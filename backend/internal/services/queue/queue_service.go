package queue

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type QueueService struct {
	db         *gorm.DB
	hub        *websocket.Hub
	dispatcher notification.Dispatcher
}

func NewQueueService(db *gorm.DB, hub *websocket.Hub, dispatcher notification.Dispatcher) *QueueService {
	return &QueueService{db: db, hub: hub, dispatcher: dispatcher}
}

func todayStartEnd() (time.Time, time.Time) {
	now := time.Now()
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	return start, start.Add(24 * time.Hour)
}

func (s *QueueService) RecalculatePositions(barberID uuid.UUID) {
	todayStart, todayEnd := todayStartEnd()
	var bookings []models.Booking
	s.db.Where("barber_id = ? AND status IN ? AND scheduled_start >= ? AND scheduled_start < ?",
		barberID,
		[]models.BookingStatus{models.BookingStatusCheckedIn, models.BookingStatusWaiting, models.BookingStatusNext, models.BookingStatusInProgress},
		todayStart, todayEnd,
	).Order("staff_id ASC, queue_position ASC, scheduled_start ASC, created_at ASC").Find(&bookings)

	staffQueues := make(map[string][]models.Booking)
	for _, b := range bookings {
		staffID := ""
		if b.StaffID != nil {
			staffID = b.StaffID.String()
		}
		staffQueues[staffID] = append(staffQueues[staffID], b)
	}

	for _, queue := range staffQueues {
		for i, b := range queue {
			newPos := i + 1
			if b.QueuePosition != newPos {
				s.db.Model(&b).Update("queue_position", newPos)
			}
		}
	}
}
func (s *QueueService) RecalculateWaitTimes(barberID uuid.UUID) {
	todayStart, todayEnd := todayStartEnd()
	var barber models.Barber
	if err := s.db.First(&barber, barberID).Error; err != nil {
		return
	}

	var bookings []models.Booking
	s.db.Where("barber_id = ? AND status IN ? AND scheduled_start >= ? AND scheduled_start < ?",
		barberID,
		[]models.BookingStatus{models.BookingStatusInProgress, models.BookingStatusNext, models.BookingStatusWaiting, models.BookingStatusCheckedIn},
		todayStart, todayEnd,
	).Order("staff_id ASC, queue_position ASC, scheduled_start ASC, created_at ASC").Find(&bookings)

	staffQueues := make(map[string][]models.Booking)
	for _, b := range bookings {
		staffID := ""
		if b.StaffID != nil {
			staffID = b.StaffID.String()
		}
		staffQueues[staffID] = append(staffQueues[staffID], b)
	}

	for _, queue := range staffQueues {
		accumulatedWait := 0
		for _, b := range queue {
			if b.Status == models.BookingStatusInProgress {
				duration := b.TotalDuration
				if duration <= 0 {
					duration = barber.SlotDuration
				}
				
				start := b.CreatedAt
				if b.ActualStart != nil {
					start = *b.ActualStart
				} else if !b.ScheduledStart.IsZero() {
					start = b.ScheduledStart
				}
				
				elapsed := int(time.Since(start).Minutes())
				remaining := duration - elapsed
				if remaining < 0 {
					remaining = 0
				}
				accumulatedWait = remaining + barber.BufferBetweenSlots
			} else {
				if b.EstimatedWaitMin != accumulatedWait {
					s.db.Model(&b).Update("estimated_wait_minutes", accumulatedWait)
				}
				
				duration := b.TotalDuration
				if duration <= 0 {
					duration = barber.SlotDuration
				}
				accumulatedWait += duration + barber.BufferBetweenSlots
			}
		}
	}
}
type QueueEntry struct {
	Booking         models.Booking `json:"booking"`
	Position        int            `json:"position"`
	EstimatedWaitMs int64          `json:"estimated_wait_ms"`
}

type QueueStatus struct {
	BarberID    uuid.UUID    `json:"barber_id"`
	QueueLength int          `json:"queue_length"`
	Version     int64        `json:"version"`
	Entries     []QueueEntry `json:"entries"`
}

func (s *QueueService) GetQueueStatus(barberID uuid.UUID) *QueueStatus {
	todayStart, todayEnd := todayStartEnd()
	var barber models.Barber
	if err := s.db.First(&barber, barberID).Error; err != nil {
		return nil
	}

	var bookings []models.Booking
	s.db.Where("barber_id = ? AND status IN ? AND scheduled_start >= ? AND scheduled_start < ?",
		barberID,
		[]models.BookingStatus{models.BookingStatusCheckedIn, models.BookingStatusWaiting, models.BookingStatusNext, models.BookingStatusInProgress},
		todayStart, todayEnd,
	).Preload("Customer").Order("staff_id ASC, queue_position ASC, scheduled_start ASC").Find(&bookings)

	entries := make([]QueueEntry, len(bookings))
	
	// Just assigning raw positions for the broadcast payload
	for i, b := range bookings {
		entries[i] = QueueEntry{
			Booking:         b,
			Position:        b.QueuePosition,
			EstimatedWaitMs: int64(b.EstimatedWaitMin * 60 * 1000),
		}
	}

	return &QueueStatus{
		BarberID:    barberID,
		QueueLength: len(bookings),
		Version:     barber.QueueVersion,
		Entries:     entries,
	}
}

func (s *QueueService) BroadcastQueueUpdate(barberID uuid.UUID) {
	// Atomically increment queue version for stale-update protection
	s.db.Model(&models.Barber{}).Where("id = ?", barberID).
		UpdateColumn("queue_version", gorm.Expr("queue_version + 1"))

	status := s.GetQueueStatus(barberID)
	if status == nil {
		return
	}

	// Gather in-progress info for richer customer payloads
	var currentlyServing string
	var remainingTime int
	for _, entry := range status.Entries {
		if entry.Booking.Status == models.BookingStatusInProgress {
			if entry.Booking.Customer != nil {
				currentlyServing = entry.Booking.Customer.FullName
			}
			duration := entry.Booking.TotalDuration
			if duration <= 0 {
				var barber models.Barber
				s.db.First(&barber, barberID)
				duration = barber.SlotDuration
			}
			start := entry.Booking.CreatedAt
			if entry.Booking.ActualStart != nil {
				start = *entry.Booking.ActualStart
			} else if !entry.Booking.ScheduledStart.IsZero() {
				start = entry.Booking.ScheduledStart
			}
			elapsed := int(time.Since(start).Minutes())
			remaining := duration - elapsed
			if remaining < 0 {
				remaining = 0
			}
			remainingTime = remaining
			break
		}
	}

	for _, entry := range status.Entries {
		customerID := entry.Booking.CustomerID
		
		payloadData := map[string]interface{}{
			"booking_id":         entry.Booking.ID.String(),
			"position":           entry.Position,
			"current_position":   entry.Position,
			"people_ahead":       entry.Position - 1,
			"estimated_wait_ms":  entry.EstimatedWaitMs,
			"estimated_wait_min": entry.EstimatedWaitMs / (60 * 1000),
			"remaining_time":     remainingTime,
			"currently_serving":  currentlyServing,
			"queue_length":       status.QueueLength,
			"queue_version":      status.Version,
		}

		if s.dispatcher != nil {
			s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
				Type:       models.NotifQueueUpdate,
				ReceiverID: customerID,
				Role:       notification.RoleCustomer,
				Data:       payloadData,
			})
		} else {
			// Fallback to direct hub broadcast if dispatcher is not provided
			msg := &websocket.WSMessage{
				Type:    websocket.MsgQueueUpdate,
				Payload: payloadData,
			}
			s.hub.SendToUser(customerID, msg)
		}
	}

	barberUserID := s.getBarberUserID(barberID)
	if barberUserID != nil {
		s.hub.SendToUser(*barberUserID, &websocket.WSMessage{
			Type:    websocket.MsgQueueUpdate,
			Payload: status,
		})
	}
}

func (s *QueueService) AutoCancelNoShows(barberID uuid.UUID, graceMinutes int) int {
	cutoff := time.Now().Add(-time.Duration(graceMinutes) * time.Minute)

	var barber models.Barber
	if err := s.db.First(&barber, barberID).Error; err != nil {
		return 0
	}

	var noShows []models.Booking
	s.db.Where("barber_id = ? AND status = ? AND scheduled_start < ?",
		barberID, models.BookingStatusConfirmed, cutoff).Find(&noShows)

	if len(noShows) == 0 {
		return 0
	}

	for _, b := range noShows {
		fromStatus := b.Status
		b.Status = models.BookingStatusNoShow
		b.BarberNotes = "Auto-cancelled: no-show"
		s.db.Save(&b)

		s.db.Create(&models.BookingStatusLog{
			BookingID:      b.ID,
			FromStatus:     fromStatus,
			ToStatus:       models.BookingStatusNoShow,
			ChangedBy:      barber.UserID,
			ChangedByRole:  "system",
			Reason:         "No-show auto-cancellation",
		})
	}

	s.RecalculatePositions(barberID)
	s.RecalculateWaitTimes(barberID)
	s.BroadcastQueueUpdate(barberID)

	return len(noShows)
}

func (s *QueueService) GetEstimatedWait(barberID uuid.UUID, bookingID uuid.UUID) (int, int, error) {
	todayStart, todayEnd := todayStartEnd()
	var booking models.Booking
	if err := s.db.First(&booking, bookingID).Error; err != nil {
		return 0, 0, err
	}

	var aheadBookings []models.Booking
	s.db.Where("barber_id = ? AND status IN ? AND scheduled_start >= ? AND scheduled_start < ? AND (queue_position < ? OR (queue_position = ? AND created_at < ?)) AND id != ?",
		barberID,
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		todayStart, todayEnd,
		booking.QueuePosition, booking.QueuePosition, booking.CreatedAt, booking.ID).
		Order("queue_position ASC, scheduled_start ASC").
		Find(&aheadBookings)

	var barber models.Barber
	s.db.First(&barber, barberID)

	wait := 0
	for _, ab := range aheadBookings {
		duration := ab.TotalDuration
		if duration <= 0 {
			duration = barber.SlotDuration
		}
		
		if ab.Status == models.BookingStatusInProgress {
			start := ab.CreatedAt
			if ab.ActualStart != nil {
				start = *ab.ActualStart
			} else if !ab.ScheduledStart.IsZero() {
				start = ab.ScheduledStart
			}
			elapsed := int(time.Since(start).Minutes())
			remaining := duration - elapsed
			if remaining < 0 {
				remaining = 0
			}
			wait += remaining + barber.BufferBetweenSlots
		} else {
			wait += duration + barber.BufferBetweenSlots
		}
	}

	position := len(aheadBookings) + 1
	return position, wait, nil
}

func (s *QueueService) getBarberUserID(barberID uuid.UUID) *uuid.UUID {
	var barber models.Barber
	if err := s.db.First(&barber, barberID).Error; err != nil {
		return nil
	}
	return &barber.UserID
}

func (s *QueueService) StartNoShowScheduler(interval time.Duration, graceMinutes int) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for range ticker.C {
			var barbers []models.Barber
			s.db.Where("status = ?", models.BarberStatusActive).Find(&barbers)

			for _, barber := range barbers {
				cancelled := s.AutoCancelNoShows(barber.ID, graceMinutes)
				if cancelled > 0 {
					log.Printf("Auto-cancelled %d no-shows for barber %s", cancelled, barber.ID)
				}
			}
		}
	}()
}

func (s *QueueService) getBooking(bookingID uuid.UUID) (*models.Booking, error) {
	var booking models.Booking
	if err := s.db.First(&booking, bookingID).Error; err != nil {
		return nil, err
	}
	return &booking, nil
}

// withLockedBooking opens a transaction, acquires FOR UPDATE row lock (PG only),
// then runs fn with the locked booking. fn can mutate the booking in-place;
// changes are saved and committed atomically.
func (s *QueueService) withLockedBooking(bookingID uuid.UUID, fn func(*models.Booking) error) error {
	tx := s.db.Begin()

	var booking models.Booking
	var q *gorm.DB
	if s.db.Dialector.Name() == "postgres" {
		q = tx.Set("gorm:query_option", "FOR UPDATE").First(&booking, bookingID)
	} else {
		q = tx.First(&booking, bookingID)
	}
	if q.Error != nil {
		tx.Rollback()
		return q.Error
	}

	if err := fn(&booking); err != nil {
		tx.Rollback()
		return err
	}

	if err := tx.Save(&booking).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

func queueStatuses() []models.BookingStatus {
	return []models.BookingStatus{
		models.BookingStatusCheckedIn,
		models.BookingStatusWaiting,
		models.BookingStatusNext,
		models.BookingStatusInProgress,
	}
}

func (s *QueueService) AssignQueuePosition(bookingID uuid.UUID) error {
	booking, err := s.getBooking(bookingID)
	if err != nil {
		return err
	}

	var aheadCount int64
	s.db.Model(&models.Booking{}).
		Where("staff_id = ? AND status IN ? AND id != ?", booking.StaffID, queueStatuses(), bookingID).
		Count(&aheadCount)

	newPos := int(aheadCount) + 1
	now := time.Now()

	s.db.Model(&booking).Updates(map[string]interface{}{
		"queue_position":   newPos,
		"queue_assigned_at": &now,
		"estimated_wait_minutes": 0,
	})

	s.CreateAuditLog(booking.BarberID, booking.StaffID, bookingID, models.QueueActionAssigned, 0, newPos, uuid.Nil, "scheduler", "Queue assigned at T-30")
	s.RecalculateWaitTimes(booking.BarberID)
	s.BroadcastQueueUpdate(booking.BarberID)

	return nil
}

func (s *QueueService) MarkLate(bookingID uuid.UUID) error {
	if s.dispatcher == nil {
		return fmt.Errorf("dispatcher not initialized")
	}
	var barberID, customerID uuid.UUID
	var staffID *uuid.UUID
	var queuePos int
	err := s.withLockedBooking(bookingID, func(b *models.Booking) error {
		now := time.Now()
		b.IsLate = true
		b.LateAt = &now
		b.LateNotifiedAt = &now
		barberID = b.BarberID
		customerID = b.CustomerID
		staffID = b.StaffID
		queuePos = b.QueuePosition
		return nil
	})
	if err != nil {
		return err
	}

	s.CreateAuditLog(barberID, staffID, bookingID, models.QueueActionLate, queuePos, queuePos, uuid.Nil, "scheduler", "Late detected")
	s.BroadcastQueueUpdate(barberID)

	s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
		Type:       models.NotifBookingLate,
		ReceiverID: customerID,
		Role:       notification.RoleCustomer,
		Data: map[string]any{
			"entity_id":       bookingID.String(),
			"barber_id":       barberID.String(),
			"scheduled_start": time.Now().Format(time.RFC3339),
		},
	})

	return nil
}

func (s *QueueService) MarkNoShow(bookingID uuid.UUID, reason string) error {
	if s.dispatcher == nil {
		return fmt.Errorf("dispatcher not initialized")
	}
	var barberID, customerID uuid.UUID
	var staffID *uuid.UUID
	var fromStatus models.BookingStatus
	var oldPos int

	err := s.withLockedBooking(bookingID, func(b *models.Booking) error {
		fromStatus = b.Status
		oldPos = b.QueuePosition
		barberID = b.BarberID
		customerID = b.CustomerID
		staffID = b.StaffID

		b.Status = models.BookingStatusNoShow
		b.QueuePosition = 0
		return nil
	})
	if err != nil {
		return err
	}

	s.db.Create(&models.BookingStatusLog{
		BookingID: bookingID,
		FromStatus: fromStatus,
		ToStatus:   models.BookingStatusNoShow,
		ChangedBy:  uuid.Nil,
		ChangedByRole: "system",
		Reason:     reason,
	})

	s.CreateAuditLog(barberID, staffID, bookingID, models.QueueActionNoShow, oldPos, 0, uuid.Nil, "scheduler", reason)
	s.PromoteNext(barberID, staffID)
	s.RecalculateWaitTimes(barberID)
	s.BroadcastQueueUpdate(barberID)

	s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
		Type:       models.NotifBookingNoShow,
		ReceiverID: customerID,
		Role:       notification.RoleCustomer,
		Data: map[string]any{
			"entity_id": bookingID.String(),
			"barber_id": barberID.String(),
		},
	})

	return nil
}

func (s *QueueService) PromoteNext(barberID uuid.UUID, staffID *uuid.UUID) {
	query := s.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status IN ? AND queue_position > 0", barberID, []models.BookingStatus{models.BookingStatusCheckedIn, models.BookingStatusWaiting})

	if staffID != nil {
		query = query.Where("staff_id = ?", staffID)
	}

	var nextBooking models.Booking
	query.Order("queue_position ASC, scheduled_start ASC").First(&nextBooking)

	if nextBooking.ID != uuid.Nil {
		s.db.Model(&nextBooking).Update("status", models.BookingStatusNext)
		s.CreateAuditLog(barberID, staffID, nextBooking.ID, models.QueueActionPromoted, 0, nextBooking.QueuePosition, uuid.Nil, "scheduler", "Promoted to next")
	}
}

func (s *QueueService) MutateQueue(bookingID uuid.UUID, fn func(*models.Booking) error, changedByRole, reason string) error {
	tx := s.db.Begin()

	var booking models.Booking
	if err := tx.Set("gorm:query_option", "FOR UPDATE").First(&booking, bookingID).Error; err != nil {
		tx.Rollback()
		return err
	}

	oldPos := booking.QueuePosition
	oldStatus := booking.Status

	if err := fn(&booking); err != nil {
		tx.Rollback()
		return err
	}

	if booking.Status != oldStatus {
		tx.Create(&models.BookingStatusLog{
			BookingID:     bookingID,
			FromStatus:    oldStatus,
			ToStatus:      booking.Status,
			ChangedBy:     booking.CustomerID,
			ChangedByRole: changedByRole,
			Reason:        reason,
		})
	}

	if err := tx.Save(&booking).Error; err != nil {
		tx.Rollback()
		return err
	}

	tx.Commit()

	s.CreateAuditLog(booking.BarberID, booking.StaffID, bookingID, models.QueueActionCheckedIn, oldPos, booking.QueuePosition, uuid.Nil, changedByRole, reason)
	s.RecalculatePositions(booking.BarberID)
	s.RecalculateWaitTimes(booking.BarberID)
	s.BroadcastQueueUpdate(booking.BarberID)

	return nil
}

func (s *QueueService) CreateAuditLog(barberID uuid.UUID, staffID *uuid.UUID, bookingID uuid.UUID, action models.QueueAction, oldPos, newPos int, changedBy uuid.UUID, changedByRole, reason string) {
	s.db.Create(&models.QueueAuditLog{
		BarberID:      barberID,
		StaffID:       staffID,
		BookingID:     bookingID,
		Action:        action,
		OldPosition:   oldPos,
		NewPosition:   newPos,
		ChangedBy:     changedBy,
		ChangedByRole: changedByRole,
		Reason:        reason,
	})
}

func (s *QueueService) CalculateETA(barberID uuid.UUID, staffID *uuid.UUID, targetPosition int) (int, string) {
	query := s.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status IN ? AND queue_position < ? AND queue_position > 0",
			barberID, queueStatuses(), targetPosition)

	if staffID != nil {
		query = query.Where("staff_id = ?", staffID)
	}

	var ahead []models.Booking
	query.Order("queue_position ASC").Find(&ahead)

	totalMinutes := 0
	for i, b := range ahead {
		if i == 0 && b.Status == models.BookingStatusInProgress {
			if b.ActualStart != nil {
				elapsed := int(time.Since(*b.ActualStart).Minutes())
				remaining := b.TotalDuration - elapsed
				if remaining < 0 {
					remaining = 0
				}
				totalMinutes += remaining
			} else {
				totalMinutes += b.TotalDuration
			}
		} else {
			dur := b.TotalDuration
			if dur <= 0 {
				dur = 30
			}
			totalMinutes += dur
		}
	}

	return totalMinutes, fmt.Sprintf("~%d min", totalMinutes)
}

func (s *QueueService) SkipCustomer(bookingID uuid.UUID) error {
	var barberID uuid.UUID
	var staffID *uuid.UUID
	var oldPos int

	err := s.withLockedBooking(bookingID, func(b *models.Booking) error {
		oldPos = b.QueuePosition
		barberID = b.BarberID
		staffID = b.StaffID
		b.QueuePosition = 0
		return nil
	})
	if err != nil {
		return err
	}

	s.CreateAuditLog(barberID, staffID, bookingID, models.QueueActionSkipped, oldPos, 0, uuid.Nil, "barber", "Skipped by barber")
	s.RecalculatePositions(barberID)
	s.RecalculateWaitTimes(barberID)
	s.BroadcastQueueUpdate(barberID)

	return nil
}

func (s *QueueService) StartService(bookingID uuid.UUID) error {
	var barberID uuid.UUID
	var fromStatus models.BookingStatus

	err := s.withLockedBooking(bookingID, func(b *models.Booking) error {
		now := time.Now()
		fromStatus = b.Status
		barberID = b.BarberID
		b.Status = models.BookingStatusInProgress
		b.ActualStart = &now
		return nil
	})
	if err != nil {
		return err
	}

	s.db.Create(&models.BookingStatusLog{
		BookingID:     bookingID,
		FromStatus:    fromStatus,
		ToStatus:      models.BookingStatusInProgress,
		ChangedBy:     uuid.Nil,
		ChangedByRole: "barber",
		Reason:        "Service started",
	})
	s.BroadcastQueueUpdate(barberID)

	return nil
}

func (s *QueueService) CompleteService(bookingID uuid.UUID) error {
	var barberID uuid.UUID
	var staffID *uuid.UUID

	err := s.withLockedBooking(bookingID, func(b *models.Booking) error {
		now := time.Now()
		barberID = b.BarberID
		staffID = b.StaffID
		b.Status = models.BookingStatusCompleted
		b.ActualEnd = &now
		b.CompletedAt = &now
		return nil
	})
	if err != nil {
		return err
	}

	s.db.Create(&models.BookingStatusLog{
		BookingID:     bookingID,
		FromStatus:    models.BookingStatusInProgress,
		ToStatus:      models.BookingStatusCompleted,
		ChangedBy:     uuid.Nil,
		ChangedByRole: "barber",
		Reason:        "Service completed",
	})
	s.db.Model(&models.Barber{}).Where("id = ?", barberID).Update("current_queue_length", gorm.Expr("GREATEST(current_queue_length - 1, 0)"))

	// Promote next
	var nextBooking models.Booking
	nq := s.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status = ? AND queue_position > 0", barberID, models.BookingStatusWaiting)
	if staffID != nil {
		nq = nq.Where("staff_id = ?", staffID)
	}
	nq.Order("queue_position ASC").First(&nextBooking)
	if nextBooking.ID != uuid.Nil {
		s.db.Model(&nextBooking).Update("status", models.BookingStatusNext)
	}

	s.RecalculatePositions(barberID)
	s.RecalculateWaitTimes(barberID)
	s.BroadcastQueueUpdate(barberID)

	return nil
}

func (s *QueueService) ExtendGrace(bookingID uuid.UUID, extraMinutes int, changedBy uuid.UUID, changedByRole string) error {
	if s.dispatcher == nil {
		return fmt.Errorf("dispatcher not initialized")
	}
	var barberID, customerID uuid.UUID
	var staffID *uuid.UUID
	var queuePos int
	var extendedUntil time.Time

	err := s.withLockedBooking(bookingID, func(b *models.Booking) error {
		if b.Status != models.BookingStatusConfirmed && b.Status != models.BookingStatusCheckedIn &&
			b.Status != models.BookingStatusWaiting && b.Status != models.BookingStatusNext {
			return fmt.Errorf("cannot extend grace for booking in status %s", b.Status)
		}

		now := time.Now()
		baseDeadline := b.ScheduledStart.Add(time.Duration(s.cfgGraceMinutes()) * time.Minute)
		if b.GraceExtendedUntil != nil && b.GraceExtendedUntil.After(now) {
			extendedUntil = b.GraceExtendedUntil.Add(time.Duration(extraMinutes) * time.Minute)
		} else {
			extendedUntil = baseDeadline.Add(time.Duration(extraMinutes) * time.Minute)
		}
		if extendedUntil.Before(now) {
			extendedUntil = now.Add(time.Duration(extraMinutes) * time.Minute)
		}

		b.GraceExtendedUntil = &extendedUntil
		barberID = b.BarberID
		customerID = b.CustomerID
		staffID = b.StaffID
		queuePos = b.QueuePosition
		return nil
	})
	if err != nil {
		return err
	}

	s.CreateAuditLog(barberID, staffID, bookingID, models.QueueActionGraceExtend, queuePos, queuePos, changedBy, changedByRole, fmt.Sprintf("Grace extended by %d min until %s", extraMinutes, extendedUntil.Format("15:04")))
	s.BroadcastQueueUpdate(barberID)

	s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
		Type:       models.NotifGraceExtended,
		ReceiverID: customerID,
		Role:       notification.RoleCustomer,
		Data: map[string]any{
			"entity_id":      bookingID.String(),
			"extended_until": extendedUntil.Format("15:04"),
			"extra_minutes":  extraMinutes,
		},
	})

	return nil
}

func (s *QueueService) RemindUpcoming(bookingID uuid.UUID) error {
	if s.dispatcher == nil {
		return fmt.Errorf("dispatcher not initialized")
	}
	booking, err := s.getBooking(bookingID)
	if err != nil {
		return err
	}

	s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
		Type:       models.NotifBookingReminder,
		ReceiverID: booking.CustomerID,
		Role:       notification.RoleCustomer,
		Data: map[string]any{
			"entity_id":       bookingID.String(),
			"barber_id":       booking.BarberID.String(),
			"scheduled_start": booking.ScheduledStart.Format(time.RFC3339),
		},
	})

	return nil
}

func (s *QueueService) cfgGraceMinutes() int {
	return 15
}
