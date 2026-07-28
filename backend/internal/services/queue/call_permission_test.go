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

func setupCallPermissionTest(t *testing.T) (*QueueService, *gorm.DB) {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Booking{}, &models.Barber{}, &models.User{}, &models.QueueAuditLog{}, &models.BookingStatusLog{}))

	hub := websocket.NewHub(nil, nil)
	svc := NewQueueService(db, hub, nil)
	return svc, db
}

func TestCanCall_TodayOnly(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()
	customerID := uuid.New()
	customerPhone := "1234567890"

	db.Create(&models.User{
		BaseModel: models.BaseModel{ID: customerID},
		Phone:     customerPhone,
	})

	yesterday := today.AddDate(0, 0, -1)
	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       uuid.New(),
		CustomerID:     customerID,
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: yesterday,
		ScheduledEnd:   yesterday.Add(30 * time.Minute),
	})

	// Yesterday booking should not be callable
	assert.False(t, svc.CanCall(bookingID, customerID, RoleCustomer))
}

func TestCanCall_CustomerOwnBooking(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()
	customerID := uuid.New()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       uuid.New(),
		CustomerID:     customerID,
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: today,
		ScheduledEnd:   today.Add(30 * time.Minute),
	})

	assert.True(t, svc.CanCall(bookingID, customerID, RoleCustomer))
	assert.False(t, svc.CanCall(bookingID, uuid.New(), RoleCustomer))
}

func TestCanCall_BarberOwnShop(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()
	barberUserID := uuid.New()
	barberID := uuid.New()

	db.Create(&models.Barber{
		BaseModel: models.BaseModel{ID: barberID},
		UserID:    barberUserID,
	})

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: today,
		ScheduledEnd:   today.Add(30 * time.Minute),
	})

	assert.True(t, svc.CanCall(bookingID, barberUserID, RoleBarber))
	assert.False(t, svc.CanCall(bookingID, uuid.New(), RoleBarber))
}

func TestCanCall_AdminAlways(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       uuid.New(),
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: today,
		ScheduledEnd:   today.Add(30 * time.Minute),
	})

	assert.True(t, svc.CanCall(bookingID, uuid.New(), RoleAdmin))
}

func TestCanCall_InvalidRole(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       uuid.New(),
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: today,
		ScheduledEnd:   today.Add(30 * time.Minute),
	})

	assert.False(t, svc.CanCall(bookingID, uuid.New(), "delivery"))
}

func TestGetMaskedPhone(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()
	customerID := uuid.New()
	barberUserID := uuid.New()
	barberID := uuid.New()

	db.Create(&models.User{
		BaseModel: models.BaseModel{ID: customerID},
		Phone:     "9876543210",
	})
	db.Create(&models.Barber{
		BaseModel: models.BaseModel{ID: barberID},
		UserID:    barberUserID,
		Phone:     "1234567890",
	})

	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     customerID,
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: today,
		ScheduledEnd:   today.Add(30 * time.Minute),
	})

	shopPhone, custPhone, err := svc.GetMaskedPhone(bookingID, customerID, RoleCustomer)
	assert.NoError(t, err)
	assert.Equal(t, "12******90", shopPhone, "shop phone should be masked")
	assert.Equal(t, "98******10", custPhone, "customer phone should be masked")

	shopPhone2, custPhone2, err := svc.GetMaskedPhone(bookingID, barberUserID, RoleBarber)
	assert.NoError(t, err)
	assert.Equal(t, "12******90", shopPhone2)
	assert.Equal(t, "98******10", custPhone2)
}

func TestGetMaskedPhone_Unauthorized(t *testing.T) {
	svc, db := setupCallPermissionTest(t)

	today := time.Now()
	bookingID := uuid.New()
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       uuid.New(),
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: today,
		ScheduledEnd:   today.Add(30 * time.Minute),
	})

	// Stranger calling
	shopPhone, custPhone, err := svc.GetMaskedPhone(bookingID, uuid.New(), RoleCustomer)
	assert.NoError(t, err)
	assert.Empty(t, shopPhone)
	assert.Empty(t, custPhone)
}

func TestIsSameDay(t *testing.T) {
	now := time.Now()
	tomorrow := now.AddDate(0, 0, 1)
	yesterday := now.AddDate(0, 0, -1)

	assert.True(t, isSameDay(now, now))
	assert.False(t, isSameDay(now, tomorrow))
	assert.False(t, isSameDay(now, yesterday))
}
