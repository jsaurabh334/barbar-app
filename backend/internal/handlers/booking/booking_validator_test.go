package booking

import (
	"testing"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupValidatorDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Booking{}))
	require.NoError(t, db.AutoMigrate(&models.BarberStaff{}))
	require.NoError(t, db.AutoMigrate(&models.Barber{}))
	return db
}

func TestValidateCustomerNoOverlap(t *testing.T) {
	db := setupValidatorDB(t)
	v := NewBookingValidator(db)

	customerID := uuid.New()
	barberID := uuid.New()
	start := time.Date(2026, 7, 28, 10, 0, 0, 0, time.UTC)
	end := time.Date(2026, 7, 28, 11, 0, 0, 0, time.UTC)

	// Must pass when no overlapping booking exists
	assert.NoError(t, v.ValidateCustomerNoOverlap(customerID, start, end, nil))

	// Create an overlapping booking
	db.Create(&models.Booking{
		BarberID:       barberID,
		CustomerID:     customerID,
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: time.Date(2026, 7, 28, 10, 30, 0, 0, time.UTC),
		ScheduledEnd:   time.Date(2026, 7, 28, 11, 30, 0, 0, time.UTC),
	})

	// Must fail with overlapping booking
	assert.Error(t, v.ValidateCustomerNoOverlap(customerID, start, end, nil))
	assert.Contains(t, v.ValidateCustomerNoOverlap(customerID, start, end, nil).Error(), "already have a booking")

	// Must pass when excluding the overlapping booking's ID
	var existing models.Booking
	db.First(&existing)
	assert.NoError(t, v.ValidateCustomerNoOverlap(customerID, start, end, &existing.ID))

	// Must pass for a different customer
	assert.NoError(t, v.ValidateCustomerNoOverlap(uuid.New(), start, end, nil))

	// Non-overlapping time (completely after)
	afterStart := time.Date(2026, 7, 28, 12, 0, 0, 0, time.UTC)
	afterEnd := time.Date(2026, 7, 28, 13, 0, 0, 0, time.UTC)
	assert.NoError(t, v.ValidateCustomerNoOverlap(customerID, afterStart, afterEnd, nil))

	// Non-overlapping time (completely before)
	beforeStart := time.Date(2026, 7, 28, 8, 0, 0, 0, time.UTC)
	beforeEnd := time.Date(2026, 7, 28, 9, 0, 0, 0, time.UTC)
	assert.NoError(t, v.ValidateCustomerNoOverlap(customerID, beforeStart, beforeEnd, nil))
}

func TestValidateStaffNoOverlap(t *testing.T) {
	db := setupValidatorDB(t)
	v := NewBookingValidator(db)

	staffID := uuid.New()
	barberID := uuid.New()
	start := time.Date(2026, 7, 28, 10, 0, 0, 0, time.UTC)
	end := time.Date(2026, 7, 28, 11, 0, 0, 0, time.UTC)

	// No overlap yet
	assert.NoError(t, v.ValidateStaffNoOverlap(staffID, start, end, nil))

	// Create overlapping booking for staff
	db.Create(&models.Booking{
		BarberID:       barberID,
		StaffID:        &staffID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: time.Date(2026, 7, 28, 10, 30, 0, 0, time.UTC),
		ScheduledEnd:   time.Date(2026, 7, 28, 11, 30, 0, 0, time.UTC),
	})

	assert.Error(t, v.ValidateStaffNoOverlap(staffID, start, end, nil))
	assert.Contains(t, v.ValidateStaffNoOverlap(staffID, start, end, nil).Error(), "already booked")

	// Different staff should pass
	assert.NoError(t, v.ValidateStaffNoOverlap(uuid.New(), start, end, nil))
}

func TestValidateCapacity(t *testing.T) {
	db := setupValidatorDB(t)
	v := NewBookingValidator(db)

	barberID := uuid.New()
	otherBarberID := uuid.New()

	// Capacity 2, no bookings yet
	assert.NoError(t, v.ValidateCapacity(barberID, 2))

	// Fill to capacity
	for i := 0; i < 2; i++ {
		db.Create(&models.Booking{
			BarberID:       barberID,
			CustomerID:     uuid.New(),
			Status:         models.BookingStatusConfirmed,
			ScheduledStart: time.Date(2026, 7, 28, 10+i, 0, 0, 0, time.UTC),
			ScheduledEnd:   time.Date(2026, 7, 28, 11+i, 0, 0, 0, time.UTC),
		})
	}

	// Now at capacity
	assert.Error(t, v.ValidateCapacity(barberID, 2))
	assert.Contains(t, v.ValidateCapacity(barberID, 2).Error(), "full capacity")

	// Other barber still has space
	assert.NoError(t, v.ValidateCapacity(otherBarberID, 2))

	// Completed/cancelled bookings should not count toward capacity
	db.Create(&models.Booking{
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusCompleted,
		ScheduledStart: time.Date(2026, 7, 28, 12, 0, 0, 0, time.UTC),
		ScheduledEnd:   time.Date(2026, 7, 28, 13, 0, 0, 0, time.UTC),
	})
	assert.Error(t, v.ValidateCapacity(barberID, 2), "completed bookings should not free capacity")
}

func TestValidateWorkingHours(t *testing.T) {
	v := &BookingValidator{}

	shopOpen := "09:00"
	shopClose := "21:00"

	// Within hours
	start := time.Date(2026, 7, 28, 10, 0, 0, 0, time.UTC)
	end := time.Date(2026, 7, 28, 11, 0, 0, 0, time.UTC)
	assert.NoError(t, v.ValidateWorkingHours(shopOpen, shopClose, start, end))

	// Before opening
	earlyStart := time.Date(2026, 7, 28, 8, 0, 0, 0, time.UTC)
	earlyEnd := time.Date(2026, 7, 28, 9, 0, 0, 0, time.UTC)
	assert.Error(t, v.ValidateWorkingHours(shopOpen, shopClose, earlyStart, earlyEnd))
	assert.Contains(t, v.ValidateWorkingHours(shopOpen, shopClose, earlyStart, earlyEnd).Error(), "working hours")

	// After closing
	lateStart := time.Date(2026, 7, 28, 21, 0, 0, 0, time.UTC)
	lateEnd := time.Date(2026, 7, 28, 22, 0, 0, 0, time.UTC)
	assert.Error(t, v.ValidateWorkingHours(shopOpen, shopClose, lateStart, lateEnd))

	// Starts before but ends during hours
	overlapStart := time.Date(2026, 7, 28, 8, 30, 0, 0, time.UTC)
	overlapEnd := time.Date(2026, 7, 28, 10, 30, 0, 0, time.UTC)
	assert.Error(t, v.ValidateWorkingHours(shopOpen, shopClose, overlapStart, overlapEnd))
}

func TestValidateBreakHours(t *testing.T) {
	v := &BookingValidator{}

	breakStart := "13:00"
	breakEnd := "14:00"

	// Outside break hours
	outsideStart := time.Date(2026, 7, 28, 11, 0, 0, 0, time.UTC)
	outsideEnd := time.Date(2026, 7, 28, 12, 0, 0, 0, time.UTC)
	assert.NoError(t, v.ValidateBreakHours(breakStart, breakEnd, outsideStart, outsideEnd))

	// Overlapping break hours
	overlapStart := time.Date(2026, 7, 28, 12, 30, 0, 0, time.UTC)
	overlapEnd := time.Date(2026, 7, 28, 13, 30, 0, 0, time.UTC)
	assert.Error(t, v.ValidateBreakHours(breakStart, breakEnd, overlapStart, overlapEnd))
	assert.Contains(t, v.ValidateBreakHours(breakStart, breakEnd, overlapStart, overlapEnd).Error(), "break hours")

	// Completely inside break
	insideStart := time.Date(2026, 7, 28, 13, 15, 0, 0, time.UTC)
	insideEnd := time.Date(2026, 7, 28, 13, 45, 0, 0, time.UTC)
	assert.Error(t, v.ValidateBreakHours(breakStart, breakEnd, insideStart, insideEnd))

	// No break defined = always passes
	assert.NoError(t, v.ValidateBreakHours("", "", outsideStart, outsideEnd))
	assert.NoError(t, v.ValidateBreakHours("", "", insideStart, insideEnd))
}

func TestValidateStaffAvailability(t *testing.T) {
	db := setupValidatorDB(t)
	v := NewBookingValidator(db)

	barberID := uuid.New()
	db.Create(&models.Barber{
		StartTime: "09:00",
		EndTime:   "18:00",
	})
	db.Model(&models.Barber{}).Where("start_time = ?", "09:00").Update("id", barberID)

	staff := models.BarberStaff{
		BarberID:  barberID,
		StartTime: "10:00",
		EndTime:   "17:00",
		DayOff:    0,
	}

	// Within staff hours
	monday := time.Date(2026, 7, 28, 11, 0, 0, 0, time.UTC) // Tuesday
	assert.NoError(t, v.ValidateStaffAvailability(staff, monday, 60))

	// Outside staff hours
	early := time.Date(2026, 7, 28, 9, 0, 0, 0, time.UTC)
	assert.Error(t, v.ValidateStaffAvailability(staff, early, 60))
	assert.Contains(t, v.ValidateStaffAvailability(staff, early, 60).Error(), "working hours")
}
