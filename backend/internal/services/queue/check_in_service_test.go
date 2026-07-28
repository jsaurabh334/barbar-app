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

func setupCheckInTest(t *testing.T) (*QueueService, *CheckInService, *gorm.DB) {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Booking{}, &models.Barber{}, &models.QueueAuditLog{}, &models.BookingStatusLog{}))

	hub := websocket.NewHub(nil, nil)
	svc := NewQueueService(db, hub, nil)
	return svc, svc.CheckInService(), db
}

func TestGenerateQRToken(t *testing.T) {
	_, cis, _ := setupCheckInTest(t)

	bookingID := uuid.New()
	token1 := cis.GenerateQRToken(bookingID)
	token2 := cis.GenerateQRToken(bookingID)

	assert.NotEmpty(t, token1)
	assert.Len(t, token1, 32)
	assert.Equal(t, token1, token2, "tokens within same 15-min window should match")
}

func TestVerifyQR(t *testing.T) {
	_, cis, _ := setupCheckInTest(t)

	bookingID := uuid.New()
	token := cis.GenerateQRToken(bookingID)

	assert.True(t, cis.VerifyQR(bookingID, token))
	assert.False(t, cis.VerifyQR(bookingID, "invalid-token"))
	assert.False(t, cis.VerifyQR(uuid.New(), token))
}

func TestCheckInValidTransition(t *testing.T) {
	_, cis, db := setupCheckInTest(t)
	bookingID := uuid.New()
	now := time.Now()

	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       uuid.New(),
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
		TotalDuration:  30,
	})

	err := cis.CheckIn(bookingID, "qr")
	assert.NoError(t, err)

	var booking models.Booking
	db.First(&booking, bookingID)
	assert.Equal(t, models.BookingStatusCheckedIn, booking.Status)
	assert.NotNil(t, booking.CheckInAt)
}

func TestCheckInNonExistentBooking(t *testing.T) {
	_, cis, _ := setupCheckInTest(t)
	err := cis.CheckIn(uuid.New(), "qr")
	assert.Error(t, err)
}

func TestHaversineMeters(t *testing.T) {
	// Same point should be 0
	assert.InDelta(t, 0, haversineMeters(0, 0, 0, 0), 0.01)

	// Approx 111km per degree at equator, so 1 degree lat ~ 111195 meters
	dist := haversineMeters(0, 0, 1, 0)
	assert.InDelta(t, 111195, dist, 1000)

	// Known distance: Tokyo -> Seoul ~ 1150km
	dist2 := haversineMeters(35.6762, 139.6503, 37.5665, 126.9780)
	assert.InDelta(t, 1150000, dist2, 50000)
}

func TestValidateGPS(t *testing.T) {
	_, cis, db := setupCheckInTest(t)
	barberID := uuid.New()
	bookingID := uuid.New()
	now := time.Now()

	db.Create(&models.Barber{
		BaseModel: models.BaseModel{ID: barberID},
		Latitude:  40.7128,
		Longitude: -74.0060,
	})
	db.Create(&models.Booking{
		BaseModel:      models.BaseModel{ID: bookingID},
		BarberID:       barberID,
		CustomerID:     uuid.New(),
		Status:         models.BookingStatusConfirmed,
		ScheduledStart: now,
		ScheduledEnd:   now.Add(30 * time.Minute),
	})

	// Within 100m (approx same location)
	within, err := cis.ValidateGPS(bookingID, 40.7128, -74.0060, 100)
	assert.NoError(t, err)
	assert.True(t, within)

	// Far away (>100m)
	far, err := cis.ValidateGPS(bookingID, 40.7300, -74.0060, 100)
	assert.NoError(t, err)
	assert.False(t, far)

	// But within expanded radius
	expanded, err := cis.ValidateGPS(bookingID, 40.7300, -74.0060, 5000)
	assert.NoError(t, err)
	assert.True(t, expanded)
}

func TestValidateGPSNonExistentBooking(t *testing.T) {
	_, cis, _ := setupCheckInTest(t)
	_, err := cis.ValidateGPS(uuid.New(), 0, 0, 100)
	assert.Error(t, err)
}
