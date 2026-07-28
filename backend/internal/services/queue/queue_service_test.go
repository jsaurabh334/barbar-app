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

func setupQueueTest(t *testing.T) (*QueueService, *gorm.DB) {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Booking{}, &models.Barber{}, &models.QueueAuditLog{}, &models.BookingStatusLog{}))

	hub := websocket.NewHub(nil, nil)
	svc := NewQueueService(db, hub, nil)
	return svc, db
}

func TestAssignQueuePosition(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		TotalDuration:  30,
	})

	err := svc.AssignQueuePosition(bookingID)
	assert.NoError(t, err)

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.Equal(t, 1, booking.QueuePosition)
	assert.NotNil(t, booking.QueueAssignedAt)
}

func TestAssignQueuePositionSequential(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	staffID := uuid.New()
	b1 := uuid.New()
	b2 := uuid.New()

	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: b1},
		BarberID:       barberID,
		StaffID:        &staffID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		TotalDuration:  30,
	})
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: b2},
		BarberID:       barberID,
		StaffID:        &staffID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now.Add(30 * time.Minute),
		ScheduledEnd:   now.Add(60 * time.Minute),
		TotalDuration:  30,
	})

	assert.NoError(t, svc.AssignQueuePosition(b1))
	assert.NoError(t, svc.AssignQueuePosition(b2))

	var booking2 models.Booking
	db.First(&booking2, b2)
	assert.Equal(t, 2, booking2.QueuePosition, "second booking should be position 2")
}

func TestSkipCustomer(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusCheckedIn,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		QueuePosition:  1,
		TotalDuration:  30,
	})

	err := svc.SkipCustomer(bookingID)
	assert.NoError(t, err)

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.Equal(t, 0, booking.QueuePosition, "skipped customer should have position 0")
}

func TestStartAndCompleteService(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusNext,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		TotalDuration:  30,
	})

	assert.NoError(t, svc.StartService(bookingID))

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.Equal(t, models.BookingStatusInProgress, booking.Status)
	assert.NotNil(t, booking.ActualStart)

	assert.NoError(t, svc.CompleteService(bookingID))
	db.First(&booking, bookingID)
	assert.Equal(t, models.BookingStatusCompleted, booking.Status)
	assert.NotNil(t, booking.ActualEnd)
}

func TestMutateQueue(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		TotalDuration:  30,
	})

	err := svc.MutateQueue(bookingID, func(b *models.Booking) error {
		b.Status = models.BookingStatusCheckedIn
		return nil
	}, "test", "test-mutation")
	assert.NoError(t, err)

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.Equal(t, models.BookingStatusCheckedIn, booking.Status)

	var logs []models.BookingStatusLog
	db.Where("booking_id = ?", bookingID).Find(&logs)
	assert.NotEmpty(t, logs, "status log should be created")

	var auditLogs []models.QueueAuditLog
	db.Where("booking_id = ?", bookingID).Find(&auditLogs)
	assert.NotEmpty(t, auditLogs, "audit log should be created")
}

func TestPromoteNext(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	staffID := uuid.New()
	now := time.Now()

	b1 := uuid.New()
	b2 := uuid.New()

	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: b1},
		BarberID:       barberID,
		StaffID:        &staffID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusCheckedIn,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		QueuePosition:  1,
		TotalDuration:  30,
		IsLate:         false,
	})
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: b2},
		BarberID:       barberID,
		StaffID:        &staffID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusCheckedIn,
		ScheduledStart: now.Add(30 * time.Minute),
		ScheduledEnd:   now.Add(60 * time.Minute),
		QueuePosition:  2,
		TotalDuration:  30,
		IsLate:         false,
	})

	svc.PromoteNext(barberID, &staffID)

	var booking1 models.Booking
	db.First(&booking1, b1)
	assert.Equal(t, models.BookingStatusNext, booking1.Status, "first in queue should be promoted to next")
}

func TestCalculateETA(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	staffID := uuid.New()
	now := time.Now()

	db.Create(&models.Booking{
		BarberID:       barberID,
		StaffID:        &staffID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusInProgress,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		QueuePosition:  1,
		TotalDuration:  30,
	})

	min, label := svc.CalculateETA(barberID, &staffID, 3)
	assert.GreaterOrEqual(t, min, 0)
	assert.Contains(t, label, "min")
}

func TestMarkLate(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusCheckedIn,
		ScheduledStart: now.Add(-10 * time.Minute),
		ScheduledEnd:   now.Add(20 * time.Minute),
		QueuePosition:  1,
		TotalDuration:  30,
		IsLate:         false,
	})

	err := svc.MarkLate(bookingID)
	assert.NoError(t, err)

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.True(t, booking.IsLate)
	assert.NotNil(t, booking.LateAt)
}

func TestMarkNoShow(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	now := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now.Add(-20 * time.Minute),
		ScheduledEnd:   now.Add(10 * time.Minute),
		QueuePosition:  1,
		TotalDuration:  30,
		IsLate:         false,
	})

	err := svc.MarkNoShow(bookingID, "test-no-show")
	assert.NoError(t, err)

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.Equal(t, models.BookingStatusNoShow, booking.Status)
	assert.Equal(t, 0, booking.QueuePosition)
}

func TestGetQueueStatusEmpty(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()

	db.Create(&models.Barber{BaseModel: models.BaseModel{ID: barberID}})
	status := svc.GetQueueStatus(barberID)
	assert.NotNil(t, status)
	assert.Equal(t, 0, status.QueueLength)
	assert.Empty(t, status.Entries)
}

func TestGetQueueStatusNonExistentBarber(t *testing.T) {
	svc, _ := setupQueueTest(t)
	status := svc.GetQueueStatus(uuid.New())
	assert.Nil(t, status)
}

func TestCreateAuditLog(t *testing.T) {
	svc, db := setupQueueTest(t)
	barberID := uuid.New()
	bookingID := uuid.New()

	svc.CreateAuditLog(barberID, nil, bookingID, models.QueueActionAssigned, 0, 1, uuid.Nil, "system", "test audit")

	var audit models.QueueAuditLog
	result := db.Where("booking_id = ?", bookingID).First(&audit)
	assert.NoError(t, result.Error)
	assert.Equal(t, models.QueueActionAssigned, audit.Action)
	assert.Equal(t, 0, audit.OldPosition)
	assert.Equal(t, 1, audit.NewPosition)
	assert.Equal(t, "system", audit.ChangedByRole)
}
