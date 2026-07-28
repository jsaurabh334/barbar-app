package queue

import (
	"testing"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupSchedulerTest(t *testing.T) (*QueueService, *BookingScheduler, *gorm.DB) {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{
		SkipDefaultTransaction: true,
	})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Booking{}, &models.Barber{}, &models.QueueAuditLog{}, &models.BookingStatusLog{}))

	hub := websocket.NewHub(nil, nil)
	svc := NewQueueService(db, hub, nil)
	scheduler := NewBookingScheduler(svc, 30*time.Second, 15, 30)
	return svc, scheduler, db
}

func TestNewBookingScheduler(t *testing.T) {
	_, scheduler, _ := setupSchedulerTest(t)
	assert.False(t, scheduler.IsRunning())

	assert.Equal(t, 30*time.Second, scheduler.interval)
	assert.Equal(t, 15, scheduler.graceMin)
	assert.Equal(t, 30, scheduler.queueLeadMin)
}

func TestNewBookingSchedulerDefaults(t *testing.T) {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	svc := NewQueueService(db, nil, nil)

	scheduler := NewBookingScheduler(svc, 0, 0, 0)
	assert.Equal(t, 15, scheduler.graceMin, "should default to 15min grace")
	assert.Equal(t, 30, scheduler.queueLeadMin, "should default to 30min lead")
}

func TestProcessBarber_AssignQueue(t *testing.T) {
	_, scheduler, db := setupSchedulerTest(t)
	barberID := uuid.New()
	customerID := uuid.New()

	now := time.Now()
	db.Create(&models.Booking{
		BarberID:       barberID,
		CustomerID:     customerID,
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now.Add(15 * time.Minute),
		ScheduledEnd:   now.Add(45 * time.Minute),
		TotalDuration:  30,
	})

	db.Create(&models.Barber{})
	db.Model(&models.Barber{}).Where("1=1").Update("id", barberID)
	db.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"status":           models.BarberStatusActive,
		"start_time":       "09:00",
		"end_time":         "21:00",
		"slot_duration":    30,
		"buffer_between_slots": 5,
	})

	scheduler.processBarber(barberID)

	var booking models.Booking
	db.First(&booking)
	assert.NotNil(t, booking.QueueAssignedAt, "queue should be assigned")
	assert.Equal(t, 1, booking.QueuePosition, "should be position 1")
}

func TestProcessBarber_NoQueueForFutureBooking(t *testing.T) {
	_, scheduler, db := setupSchedulerTest(t)
	barberID := uuid.New()
	customerID := uuid.New()

	farFuture := time.Now().Add(2 * time.Hour)
	db.Create(&models.Booking{
		BarberID:       barberID,
		CustomerID:     customerID,
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: farFuture,
		ScheduledEnd:   farFuture.Add(30 * time.Minute),
		TotalDuration:  30,
	})

	db.Create(&models.Barber{})
	db.Model(&models.Barber{}).Where("1=1").Update("id", barberID)
	db.Model(&models.Barber{}).Where("id = ?", barberID).Update("status", models.BarberStatusActive)

	scheduler.processBarber(barberID)

	var booking models.Booking
	db.First(&booking)
	assert.Nil(t, booking.QueueAssignedAt, "future booking should not get queue assigned")
	assert.Equal(t, 0, booking.QueuePosition)
}

func TestProcessBarber_MarkLate(t *testing.T) {
	_, scheduler, db := setupSchedulerTest(t)
	barberID := uuid.New()
	customerID := uuid.New()

	now := time.Now()
	pastStart := now.Add(-10 * time.Minute)

	db.Create(&models.Booking{
		BarberID:        barberID,
		CustomerID:      customerID,
		Status:          models.BookingStatusCheckedIn,
		ScheduledStart:  pastStart,
		ScheduledEnd:    pastStart.Add(30 * time.Minute),
		QueueAssignedAt: &now,
		QueuePosition:   1,
		TotalDuration:   30,
		IsLate:          false,
	})

	db.Create(&models.Barber{})
	db.Model(&models.Barber{}).Where("1=1").Update("id", barberID)
	db.Model(&models.Barber{}).Where("id = ?", barberID).Update("status", models.BarberStatusActive)

	scheduler.processBarber(barberID)

	var booking models.Booking
	db.First(&booking)
	assert.True(t, booking.IsLate, "should be marked late")
	assert.NotNil(t, booking.LateAt, "late_at should be set")
}

func TestProcessBarber_NoShow(t *testing.T) {
	_, scheduler, db := setupSchedulerTest(t)
	barberID := uuid.New()
	customerID := uuid.New()

	now := time.Now()
	pastTime := now.Add(-20 * time.Minute)

	db.Create(&models.Booking{
		BarberID:        barberID,
		CustomerID:      customerID,
		Status:          models.BookingStatusConfirmed,
		ScheduledStart:  pastTime,
		ScheduledEnd:    pastTime.Add(30 * time.Minute),
		QueueAssignedAt: &pastTime,
		QueuePosition:   1,
		TotalDuration:   30,
		IsLate:          false,
	})

	db.Create(&models.Barber{})
	db.Model(&models.Barber{}).Where("1=1").Update("id", barberID)
	db.Model(&models.Barber{}).Where("id = ?", barberID).Update("status", models.BarberStatusActive)

	scheduler.processBarber(barberID)

	var booking models.Booking
	db.First(&booking)
	assert.Equal(t, models.BookingStatusNoShow, booking.Status, "should be marked no-show")
}

func TestProcessBarber_OnlyProcessesActiveBarbers(t *testing.T) {
	_, scheduler, db := setupSchedulerTest(t)
	barberID := uuid.New()

	db.Create(&models.Barber{})
	db.Model(&models.Barber{}).Where("1=1").Update("id", barberID)
	db.Model(&models.Barber{}).Where("id = ?", barberID).Update("status", models.BarberStatusInactive)

	// Should not panic when processing inactive barber
	scheduler.processBarber(barberID)
}
