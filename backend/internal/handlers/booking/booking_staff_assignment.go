package booking

import (
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type StaffAssignmentResult struct {
	StaffID       uuid.UUID
	TotalDuration int
	TotalPrice    float64
	Services      []models.BarberService
}

func (h *BookingHandler) findBestStaff(
	tx *gorm.DB,
	barber models.Barber,
	requestedStaffID *uuid.UUID,
	serviceIDs []uuid.UUID,
	scheduledStart time.Time,
	_ bool,
) (*StaffAssignmentResult, error) {

	var baseServices []models.BarberService
	if err := tx.Where("id IN ? AND barber_id = ? AND is_active = ?", serviceIDs, barber.ID, true).Find(&baseServices).Error; err != nil {
		return nil, fmt.Errorf("services not found")
	}
	if len(baseServices) != len(serviceIDs) {
		return nil, fmt.Errorf("one or more services do not belong to this shop or are inactive")
	}

	totalServiceDuration := 0
	for _, svc := range baseServices {
		totalServiceDuration += svc.DurationMin
	}

	var activeBookings int64
	tx.Model(&models.Booking{}).Where("barber_id = ? AND status IN ?", barber.ID, []models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusCheckedIn, models.BookingStatusInProgress}).Count(&activeBookings)
	if int(activeBookings) >= barber.MaxQueueSize {
		return nil, fmt.Errorf("shop is at full capacity")
	}

	var staffs []models.BarberStaff
	query := tx.Preload("Services", "is_active = ?", true).
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

	tStr := scheduledStart.Format("15:04")
	dayOfWeek := int(scheduledStart.Weekday())

	for _, staff := range staffs {
		if staff.DayOff == dayOfWeek {
			continue
		}

		if staff.LeaveStart != nil && staff.LeaveEnd != nil {
			if (scheduledStart.After(*staff.LeaveStart) || scheduledStart.Equal(*staff.LeaveStart)) &&
				(scheduledStart.Before(*staff.LeaveEnd) || scheduledStart.Equal(*staff.LeaveEnd)) {
				continue
			}
		}

		startTime := staff.StartTime
		endTime := staff.EndTime
		if startTime == "" || endTime == "" {
			startTime = barber.StartTime
			endTime = barber.EndTime
		}

		if startTime != "" && endTime != "" {
			if tStr < startTime || tStr >= endTime {
				continue
			}
		}

		bookingEndTime := scheduledStart.Add(time.Duration(totalServiceDuration) * time.Minute)
		if staff.BreakStart != "" && staff.BreakEnd != "" {
			bs, _ := time.Parse("15:04", staff.BreakStart)
			be, _ := time.Parse("15:04", staff.BreakEnd)
			breakStartMin := bs.Hour()*60 + bs.Minute()
			breakEndMin := be.Hour()*60 + be.Minute()
			bookingStartMin := scheduledStart.Hour()*60 + scheduledStart.Minute()
			bookingEndMin := bookingEndTime.Hour()*60 + bookingEndTime.Minute()
			if bookingStartMin < breakEndMin && bookingEndMin > breakStartMin {
				continue
			}
		}

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

		newStart := scheduledStart
		newEnd := scheduledStart.Add(time.Duration(currentDuration+barber.BufferBetweenSlots) * time.Minute)

		var overlapCount int64
		tx.Model(&models.Booking{}).Where("staff_id = ? AND status IN ? AND scheduled_start < ? AND scheduled_end > ?",
			staff.ID,
			[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
			newEnd, newStart).Count(&overlapCount)

		if overlapCount > 0 {
			if requestedStaffID != nil {
				return nil, fmt.Errorf("Selected staff is already booked during this time slot.")
			}
			continue
		}

		if bestResult == nil {
			bestResult = &StaffAssignmentResult{
				StaffID:       staff.ID,
				TotalDuration: currentDuration,
				TotalPrice:    currentPrice,
				Services:      currentServices,
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
