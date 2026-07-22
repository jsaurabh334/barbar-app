package queue

import (
	"context"
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
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		todayStart, todayEnd,
	).Order("staff_id ASC, queue_position ASC, scheduled_start ASC, created_at ASC").Find(&bookings)

	// Group by staffID
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
		[]models.BookingStatus{models.BookingStatusInProgress, models.BookingStatusPending, models.BookingStatusConfirmed},
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
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
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
		Entries:     entries,
	}
}

func (s *QueueService) BroadcastQueueUpdate(barberID uuid.UUID) {
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
