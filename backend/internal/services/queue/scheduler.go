package queue

import (
	"context"
	"log"
	"sync"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
)

type BookingScheduler struct {
	svc         *QueueService
	interval    time.Duration
	graceMin    int
	queueLeadMin int
	mu          sync.Mutex
	running     bool
}

func NewBookingScheduler(svc *QueueService, interval time.Duration, graceMin, queueLeadMin int) *BookingScheduler {
	if graceMin <= 0 {
		graceMin = 15
	}
	if queueLeadMin <= 0 {
		queueLeadMin = 30
	}
	return &BookingScheduler{
		svc:          svc,
		interval:     interval,
		graceMin:     graceMin,
		queueLeadMin: queueLeadMin,
	}
}

func (s *BookingScheduler) Start(ctx context.Context) {
	s.mu.Lock()
	if s.running {
		s.mu.Unlock()
		return
	}
	s.running = true
	s.mu.Unlock()

	go func() {
		ticker := time.NewTicker(s.interval)
		defer ticker.Stop()
		log.Printf("BookingScheduler started: interval=%v, grace=%dmin, queueLead=%dmin", s.interval, s.graceMin, s.queueLeadMin)

		for {
			select {
			case <-ctx.Done():
				log.Println("BookingScheduler stopped")
				s.mu.Lock()
				s.running = false
				s.mu.Unlock()
				return
			case <-ticker.C:
				s.runOnce()
			}
		}
	}()
}

func (s *BookingScheduler) runOnce() {
	var barbers []models.Barber
	if err := s.svc.db.Where("status = ?", models.BarberStatusActive).Find(&barbers).Error; err != nil {
		log.Printf("BookingScheduler: failed to fetch barbers: %v", err)
		return
	}

	for _, barber := range barbers {
		s.processBarber(barber.ID)
	}
}

func (s *BookingScheduler) processBarber(barberID uuid.UUID) {
	now := time.Now()
	leadCutoff := now.Add(time.Duration(s.queueLeadMin) * time.Minute)

	// 1. Assign queue for confirmed bookings within the lead window
	var assignable []models.Booking
	s.svc.db.Where("barber_id = ? AND status = ? AND queue_assigned_at IS NULL AND scheduled_start <= ? AND scheduled_start > ?",
		barberID, models.BookingStatusConfirmed, leadCutoff, now.Add(-2*time.Hour)).
		Order("scheduled_start ASC, created_at ASC").
		Find(&assignable)

	for _, b := range assignable {
		s.svc.AssignQueuePosition(b.ID)
	}

	// 2. T-15 reminder: confirmed bookings with queue assigned, ~15 min before start, not yet reminded
	var remindable []models.Booking
	s.svc.db.Where("barber_id = ? AND status = ? AND queue_assigned_at IS NOT NULL AND reminder_sent_at IS NULL AND scheduled_start BETWEEN ? AND ?",
		barberID, models.BookingStatusConfirmed, now.Add(14*time.Minute), now.Add(16*time.Minute)).
		Find(&remindable)

	for _, b := range remindable {
		if err := s.svc.RemindUpcoming(b.ID); err == nil {
			s.svc.db.Model(&b).Update("reminder_sent_at", time.Now())
		}
	}

	// 3. Late detection: confirmed+queue and checked_in/waiting/next past scheduled_start
	var confirmedLate []models.Booking
	s.svc.db.Where("barber_id = ? AND status = ? AND queue_assigned_at IS NOT NULL AND scheduled_start < ? AND is_late = ?",
		barberID, models.BookingStatusConfirmed, now, false).
		Find(&confirmedLate)

	var queueLate []models.Booking
	s.svc.db.Where("barber_id = ? AND status IN ? AND scheduled_start < ? AND is_late = ?",
		barberID, []models.BookingStatus{models.BookingStatusCheckedIn, models.BookingStatusWaiting, models.BookingStatusNext}, now, false).
		Find(&queueLate)

	lateCheck := append(confirmedLate, queueLate...)
	for _, b := range lateCheck {
		s.svc.MarkLate(b.ID)
	}

	// 4. No-show: confirmed + queue assigned, past effective deadline
	// effectiveDeadline = COALESCE(grace_extended_until, scheduled_start + gracePeriod)
	// We check: scheduled_start + gracePeriod < now AND (grace_extended_until IS NULL OR grace_extended_until < now)
	var noShowCandidates []models.Booking
	s.svc.db.Where("barber_id = ? AND status = ? AND queue_assigned_at IS NOT NULL AND scheduled_start < ?",
		barberID, models.BookingStatusConfirmed, now.Add(-time.Duration(s.graceMin)*time.Minute)).
		Where("(grace_extended_until IS NULL OR grace_extended_until < ?)", now).
		Find(&noShowCandidates)

	for _, b := range noShowCandidates {
		s.svc.MarkNoShow(b.ID, "auto-no-show")
	}
}

func (s *BookingScheduler) IsRunning() bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.running
}
