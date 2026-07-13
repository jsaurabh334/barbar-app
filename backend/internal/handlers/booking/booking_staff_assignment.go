package booking

import (
	"fmt"
	"time"
	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
)

// StaffAssignmentResult holds the result of staff auto-assignment
type StaffAssignmentResult struct {
	StaffID          uuid.UUID
	EstimatedWaitMin int
	QueuePosition    int
	TotalDuration    int
	TotalPrice       float64
	Services         []models.BarberService // Potentially overridden by StaffService
}

// findBestStaff assigning logic
func (h *BookingHandler) findBestStaff(
	barber models.Barber,
	requestedStaffID *uuid.UUID,
	serviceIDs []uuid.UUID,
	scheduledStart time.Time,
	_ bool, // isHomeService
) (*StaffAssignmentResult, error) {

	// 1. Fetch original services to know base price and duration
	var baseServices []models.BarberService
	if err := h.db.Where("id IN ? AND barber_id = ? AND is_active = ?", serviceIDs, barber.ID, true).Find(&baseServices).Error; err != nil {
		return nil, fmt.Errorf("services not found")
	}
	if len(baseServices) != len(serviceIDs) {
		return nil, fmt.Errorf("one or more services do not belong to this shop or are inactive")
	}

	// 2. Fetch active staff
	var staffs []models.BarberStaff
	query := h.db.Preload("Services", "is_active = ?", true).
		Where("barber_id = ? AND is_active = ?", barber.ID, true)
	
	if requestedStaffID != nil {
		query = query.Where("id = ?", *requestedStaffID)
	}
	
	if err := query.Find(&staffs).Error; err != nil {
		return nil, fmt.Errorf("error fetching staff")
	}

	if len(staffs) == 0 {
		return nil, fmt.Errorf("no available staff found")
	}

	var bestResult *StaffAssignmentResult
	minWait := -1

	// Helper to check working hours
	tStr := scheduledStart.Format("15:04")
	dayOfWeek := int(scheduledStart.Weekday()) // 0=Sun, 1=Mon...

	for _, staff := range staffs {
		// a. Check DayOff
		if staff.DayOff == dayOfWeek {
			continue // Staff is off today
		}

		// b. Check Working hours (use Staff override if exists, else Shop)
		startTime := staff.StartTime
		endTime := staff.EndTime
		if startTime == "" || endTime == "" {
			startTime = barber.StartTime
			endTime = barber.EndTime
		}

		if startTime != "" && endTime != "" {
			if tStr < startTime || tStr >= endTime {
				continue // Outside working hours
			}
		}

		// c. Check if Staff can perform ALL requested services
		// and calculate overridden prices/durations
		canPerformAll := true
		staffServicesMap := make(map[uuid.UUID]models.StaffService)
		for _, ss := range staff.Services {
			staffServicesMap[ss.ServiceID] = ss
		}

		var currentServices []models.BarberService
		currentDuration := 0
		currentPrice := 0.0

		for _, bs := range baseServices {
			ss, exists := staffServicesMap[bs.ID]
			if !exists {
				canPerformAll = false
				break
			}
			// Clone the base service for this staff
			svc := bs
			if ss.Price > 0 {
				svc.Price = ss.Price
			}
			if ss.DurationMin > 0 {
				svc.DurationMin = ss.DurationMin
			}
			currentDuration += svc.DurationMin
			currentPrice += svc.Price
			currentServices = append(currentServices, svc)
		}

		if !canPerformAll {
			continue
		}

		// d. Calculate Queue Position & Estimated Wait for this staff
		var aheadBookings []models.Booking
		h.db.Where("staff_id = ? AND status IN ? AND (scheduled_start < ? OR (scheduled_start = ? AND created_at < ?))",
			staff.ID,
			[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
			scheduledStart, scheduledStart, time.Now()).
			Order("queue_position ASC, scheduled_start ASC").
			Find(&aheadBookings)

		estimatedWait := 0
		for _, ab := range aheadBookings {
			dur := ab.TotalDuration
			if dur <= 0 {
				dur = barber.SlotDuration
			}

			if ab.Status == models.BookingStatusInProgress {
				start := ab.CreatedAt
				if ab.ActualStart != nil {
					start = *ab.ActualStart
				} else if !ab.ScheduledStart.IsZero() {
					start = ab.ScheduledStart
				}
				elapsed := int(time.Since(start).Minutes())
				remaining := dur - elapsed
				if remaining < 0 {
					remaining = 0
				}
				estimatedWait += remaining + barber.BufferBetweenSlots
			} else {
				estimatedWait += dur + barber.BufferBetweenSlots
			}
		}
		
		// If home service, skip queue logic and just check if they are free? 
		// For simplicity, we just use estimatedWait as the metric for all.
		queuePos := len(aheadBookings) + 1

		// Pick Earliest Available (min estimated wait)
		if minWait == -1 || estimatedWait < minWait {
			minWait = estimatedWait
			bestResult = &StaffAssignmentResult{
				StaffID:          staff.ID,
				EstimatedWaitMin: estimatedWait,
				QueuePosition:    queuePos,
				TotalDuration:    currentDuration,
				TotalPrice:       currentPrice,
				Services:         currentServices,
			}
		}
	}

	if bestResult == nil {
		if requestedStaffID != nil {
			return nil, fmt.Errorf("requested staff is not available or cannot perform these services")
		}
		return nil, fmt.Errorf("no staff available to perform the requested services at this time")
	}

	return bestResult, nil
}
