package booking

import (
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BookingValidator struct {
	db *gorm.DB
}

func NewBookingValidator(db *gorm.DB) *BookingValidator {
	return &BookingValidator{db: db}
}

func (v *BookingValidator) ValidateCustomerNoOverlap(customerID uuid.UUID, scheduledStart, scheduledEnd time.Time, excludeBookingID *uuid.UUID) error {
	query := v.db.Model(&models.Booking{}).
		Where("customer_id = ? AND status IN ? AND scheduled_start < ? AND scheduled_end > ?",
			customerID, ActiveStatuses(), scheduledEnd, scheduledStart)

	if excludeBookingID != nil {
		query = query.Where("id != ?", *excludeBookingID)
	}

	var count int64
	query.Count(&count)
	if count > 0 {
		return fmt.Errorf("you already have a booking during this time")
	}
	return nil
}

func (v *BookingValidator) ValidateStaffNoOverlap(staffID uuid.UUID, scheduledStart, scheduledEnd time.Time, excludeBookingID *uuid.UUID) error {
	query := v.db.Model(&models.Booking{}).
		Where("staff_id = ? AND status IN ? AND scheduled_start < ? AND scheduled_end > ?",
			staffID, ActiveStatuses(), scheduledEnd, scheduledStart)

	if excludeBookingID != nil {
		query = query.Where("id != ?", *excludeBookingID)
	}

	var count int64
	query.Count(&count)
	if count > 0 {
		return fmt.Errorf("staff member is already booked during this time")
	}
	return nil
}

func (v *BookingValidator) ValidateCapacity(barberID uuid.UUID, maxQueueSize int) error {
	var activeCount int64
	v.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status IN ?", barberID, ActiveStatuses()).
		Count(&activeCount)

	if int(activeCount) >= maxQueueSize {
		return fmt.Errorf("shop is at full capacity")
	}
	return nil
}

func (v *BookingValidator) ValidateWorkingHours(shopStartTime, shopEndTime string, scheduledStart, scheduledEnd time.Time) error {
	shopStart, _ := time.Parse("15:04", shopStartTime)
	shopEnd, _ := time.Parse("15:04", shopEndTime)

	startMin := shopStart.Hour()*60 + shopStart.Minute()
	endMin := shopEnd.Hour()*60 + shopEnd.Minute()
	bookingStartMin := scheduledStart.Hour()*60 + scheduledStart.Minute()
	bookingEndMin := scheduledEnd.Hour()*60 + scheduledEnd.Minute()

	if bookingStartMin < startMin || bookingEndMin > endMin {
		return fmt.Errorf("booking time must be within working hours (%s - %s)", shopStartTime, shopEndTime)
	}
	return nil
}

func (v *BookingValidator) ValidateBreakHours(breakStart, breakEnd string, scheduledStart, scheduledEnd time.Time) error {
	if breakStart == "" || breakEnd == "" {
		return nil
	}
	bs, _ := time.Parse("15:04", breakStart)
	be, _ := time.Parse("15:04", breakEnd)
	breakStartMin := bs.Hour()*60 + bs.Minute()
	breakEndMin := be.Hour()*60 + be.Minute()

	bookingStartMin := scheduledStart.Hour()*60 + scheduledStart.Minute()
	bookingEndMin := scheduledEnd.Hour()*60 + scheduledEnd.Minute()

	if bookingStartMin < breakEndMin && bookingEndMin > breakStartMin {
		return fmt.Errorf("booking time cannot overlap with break hours (%s - %s)", breakStart, breakEnd)
	}
	return nil
}

func (v *BookingValidator) ValidateStaffAvailability(staff models.BarberStaff, scheduledStart time.Time, totalDuration int) error {
	dayOfWeek := int(scheduledStart.Weekday())
	if staff.DayOff == dayOfWeek {
		return fmt.Errorf("staff is off today")
	}

	tStr := scheduledStart.Format("15:04")
	startTime := staff.StartTime
	endTime := staff.EndTime
	if startTime == "" || endTime == "" {
		var barber models.Barber
		v.db.First(&barber, staff.BarberID)
		startTime = barber.StartTime
		endTime = barber.EndTime
	}
	if startTime != "" && endTime != "" {
		if tStr < startTime || tStr >= endTime {
			return fmt.Errorf("outside staff working hours (%s - %s)", startTime, endTime)
		}
	}
	return nil
}
