package settlement

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

func setupTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Barber{}))
	require.NoError(t, db.AutoMigrate(&models.BarberEarning{}))
	require.NoError(t, db.AutoMigrate(&models.Wallet{}))
	require.NoError(t, db.AutoMigrate(&models.WalletTransaction{}))
	return db
}

func TestRecordCompletionEarnings(t *testing.T) {
	db := setupTestDB(t)
	svc := NewBookingSettlementService(db)

	barber := models.Barber{ShopName: "S", UserID: uuid.New(), Status: models.BarberStatusActive}
	require.NoError(t, db.Create(&barber).Error)

	booking := &models.Booking{
		BarberID:   barber.ID,
		CustomerID: uuid.New(),
		Status:     models.BookingStatusAwaitingCustomerConfirmation,
		FinalPrice: 499.5,
	}

	require.NoError(t, db.Transaction(func(tx *gorm.DB) error {
		return svc.RecordCompletionEarnings(tx, booking)
	}))

	var earnings []models.BarberEarning
	require.NoError(t, db.Find(&earnings).Error)
	require.Len(t, earnings, 1)
	assert.Equal(t, booking.BarberID, earnings[0].BarberID)
	assert.Equal(t, 499.5, earnings[0].Amount)
	assert.Equal(t, models.EarningStatusPending, earnings[0].Status)

	// Idempotent: recording twice keeps a single pending earning
	require.NoError(t, db.Transaction(func(tx *gorm.DB) error {
		return svc.RecordCompletionEarnings(tx, booking)
	}))
	require.NoError(t, db.Find(&earnings).Error)
	assert.Len(t, earnings, 1)
}

func TestSettleBarberEarning(t *testing.T) {
	db := setupTestDB(t)
	svc := NewBookingSettlementService(db)

	barber := models.Barber{ShopName: "S", UserID: uuid.New(), Status: models.BarberStatusActive}
	require.NoError(t, db.Create(&barber).Error)

	earning := models.BarberEarning{
		BookingID: uuid.New(),
		BarberID:  barber.ID,
		Amount:    800,
		Status:    models.EarningStatusPending,
	}
	require.NoError(t, db.Create(&earning).Error)

	require.NoError(t, svc.SettleBarberEarning(earning.ID))

	// Earning is now settled
	var settled models.BarberEarning
	require.NoError(t, db.First(&settled, earning.ID).Error)
	assert.Equal(t, models.EarningStatusSettled, settled.Status)
	assert.NotNil(t, settled.SettledAt)

	// Barber wallet credited with the full amount
	var wallet models.Wallet
	require.NoError(t, db.Where("user_id = ?", barber.UserID).First(&wallet).Error)
	assert.Equal(t, 800.0, wallet.Balance)
	assert.Equal(t, 800.0, wallet.TotalCredited)

	// A matching wallet transaction is recorded
	var txns []models.WalletTransaction
	require.NoError(t, db.Where("wallet_id = ?", wallet.ID).Find(&txns).Error)
	require.Len(t, txns, 1)
	assert.Equal(t, models.TxnRefBarberEarning, txns[0].ReferenceType)
	assert.Equal(t, models.TxnTypeCredit, txns[0].TxnType)
	assert.Equal(t, 800.0, txns[0].Amount)

	// Settling twice is rejected
	assert.Error(t, svc.SettleBarberEarning(earning.ID))
}

func TestSettleBarberEarningNotPending(t *testing.T) {
	db := setupTestDB(t)
	svc := NewBookingSettlementService(db)

	barber := models.Barber{ShopName: "S", UserID: uuid.New(), Status: models.BarberStatusActive}
	require.NoError(t, db.Create(&barber).Error)

	now := time.Now()
	earning := models.BarberEarning{
		BookingID: uuid.New(),
		BarberID:  barber.ID,
		Amount:    100,
		Status:    models.EarningStatusSettled,
		SettledAt: &now,
	}
	require.NoError(t, db.Create(&earning).Error)

	assert.Error(t, svc.SettleBarberEarning(earning.ID))
}
