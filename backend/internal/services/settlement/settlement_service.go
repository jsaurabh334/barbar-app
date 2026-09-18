package settlement

import (
	"errors"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// SettlementService records barber earnings once a home service booking is
// approved by the customer (End OTP) and releases them to the barber's wallet.
// This is the escrow hook: money is captured as "pending" on approval and only
// reaches the barber when settled.
type SettlementService interface {
	// RecordCompletionEarnings creates a pending earning for the barber. Must be
	// called inside the completion transaction. Idempotent per booking.
	RecordCompletionEarnings(tx *gorm.DB, booking *models.Booking) error
	// SettleBarberEarning releases a pending earning to the barber's wallet.
	SettleBarberEarning(earningID uuid.UUID) error
}

type BookingSettlementService struct {
	db *gorm.DB
}

func NewBookingSettlementService(db *gorm.DB) *BookingSettlementService {
	return &BookingSettlementService{db: db}
}

func (s *BookingSettlementService) RecordCompletionEarnings(tx *gorm.DB, booking *models.Booking) error {
	var count int64
	if err := tx.Model(&models.BarberEarning{}).Where("booking_id = ?", booking.ID).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	earning := models.BarberEarning{
		BookingID:        booking.ID,
		BarberID:         booking.BarberID,
		Amount:           booking.FinalPrice,
		CommissionAmount: 0, // barber commission config is future work
		Status:           models.EarningStatusPending,
		Description:      "Home service completion approved by customer (End OTP)",
	}
	return tx.Create(&earning).Error
}

func (s *BookingSettlementService) SettleBarberEarning(earningID uuid.UUID) error {
	var earning models.BarberEarning
	if err := s.db.First(&earning, earningID).Error; err != nil {
		return errors.New("earning not found")
	}
	if earning.Status != models.EarningStatusPending {
		return errors.New("earning not pending or already settled")
	}

	var barber models.Barber
	if err := s.db.Where("id = ?", earning.BarberID).First(&barber).Error; err != nil {
		return errors.New("barber not found")
	}

	now := time.Now()
	return s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Model(&earning).Updates(map[string]interface{}{
			"status":     models.EarningStatusSettled,
			"settled_at": &now,
		}).Error; err != nil {
			return err
		}

		wallet, err := findOrCreateWallet(tx, barber.UserID)
		if err != nil {
			return err
		}

		wallet.Balance += earning.Amount
		wallet.TotalCredited += earning.Amount
		if err := tx.Save(wallet).Error; err != nil {
			return err
		}

		txn := models.WalletTransaction{
			WalletID:       wallet.ID,
			TxnType:        models.TxnTypeCredit,
			Amount:         earning.Amount,
			RunningBalance: wallet.Balance,
			ReferenceType:  models.TxnRefBarberEarning,
			ReferenceID:    earning.ID.String(),
			Description:    "Barber earning settled (home service completion)",
			Status:         "completed",
			TxnDate:        now,
		}
		return tx.Create(&txn).Error
	})
}

func findOrCreateWallet(tx *gorm.DB, userID uuid.UUID) (*models.Wallet, error) {
	var wallet models.Wallet
	err := tx.Where("user_id = ?", userID).First(&wallet).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			wallet = models.Wallet{UserID: &userID, Balance: 0, IsActive: true}
			if createErr := tx.Create(&wallet).Error; createErr != nil {
				return nil, createErr
			}
			return &wallet, nil
		}
		return nil, err
	}
	return &wallet, nil
}
