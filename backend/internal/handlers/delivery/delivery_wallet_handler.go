package delivery

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DeliveryWalletHandler struct {
	db *gorm.DB
}

func NewDeliveryWalletHandler(db *gorm.DB) *DeliveryWalletHandler {
	return &DeliveryWalletHandler{db: db}
}

func (h *DeliveryWalletHandler) getDriverProfile(c *gin.Context) (*models.DeliveryPartner, *models.Wallet, error) {
	userID := c.MustGet("user").(uuid.UUID)

	var dp models.DeliveryPartner
	if err := h.db.Where("user_id = ?", userID).First(&dp).Error; err != nil {
		return nil, nil, err
	}

	var wallet models.Wallet
	err := h.db.Where("user_id = ?", userID).First(&wallet).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			wallet = models.Wallet{
				UserID:   &userID,
				Balance:  0,
				IsActive: true,
			}
			if createErr := h.db.Create(&wallet).Error; createErr != nil {
				return nil, nil, createErr
			}
		} else {
			return nil, nil, err
		}
	}

	return &dp, &wallet, nil
}

func (h *DeliveryWalletHandler) GetWalletSummary(c *gin.Context) {
	_, wallet, err := h.getDriverProfile(c)
	if err != nil {
		utils.NotFoundResponse(c, "Driver wallet not found: "+err.Error())
		return
	}

	userID := c.MustGet("user").(uuid.UUID)
	var dp models.DeliveryPartner
	h.db.Where("user_id = ?", userID).First(&dp)

	var pendingWithdrawal float64
	h.db.Model(&models.WithdrawalRequest{}).
		Where("delivery_partner_id = ? AND status = ?", dp.ID, models.WithdrawPending).
		Select("COALESCE(SUM(amount), 0)").Scan(&pendingWithdrawal)

	utils.SuccessResponse(c, gin.H{
		"available_balance":          wallet.Balance,
		"locked_balance":             wallet.LockedBalance,
		"lifetime_earnings":          wallet.TotalCredited,
		"pending_withdrawal_amount": pendingWithdrawal,
	})
}

func (h *DeliveryWalletHandler) GetWalletTransactions(c *gin.Context) {
	_, wallet, err := h.getDriverProfile(c)
	if err != nil {
		utils.NotFoundResponse(c, "Driver wallet not found")
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	var txns []models.WalletTransaction
	h.db.Where("wallet_id = ?", wallet.ID).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&txns)

	utils.SuccessResponse(c, txns)
}

type withdrawRequestInput struct {
	Amount float64 `json:"amount" binding:"required"`
}

func (h *DeliveryWalletHandler) RequestWithdrawal(c *gin.Context) {
	dp, wallet, err := h.getDriverProfile(c)
	if err != nil {
		utils.NotFoundResponse(c, "Driver profile or wallet not found")
		return
	}

	var req withdrawRequestInput
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if req.Amount <= 0 {
		utils.BadRequestResponse(c, "Withdrawal amount must be greater than 0")
		return
	}

	if req.Amount > wallet.Balance {
		utils.BadRequestResponse(c, "Requested amount exceeds available balance")
		return
	}

	var bankAccount models.DeliveryPartnerBankAccount
	if err := h.db.Where("delivery_partner_id = ?", dp.ID).First(&bankAccount).Error; err != nil {
		utils.BadRequestResponse(c, "No bank account linked. Please add a bank account first.")
		return
	}

	bankJSON, _ := json.Marshal(map[string]interface{}{
		"account_number": bankAccount.AccountNumber,
		"ifsc_code":      bankAccount.IFSCCode,
		"account_holder": bankAccount.AccountHolderName,
		"bank_name":      bankAccount.BankName,
	})

	var createdWithdrawal models.WithdrawalRequest
	err = h.db.Transaction(func(tx *gorm.DB) error {
		// Lock balance: Available -> Locked
		newBalance := wallet.Balance - req.Amount
		newLocked := wallet.LockedBalance + req.Amount
		if err := tx.Model(wallet).Updates(map[string]interface{}{
			"balance":        newBalance,
			"locked_balance": newLocked,
		}).Error; err != nil {
			return err
		}

		withdrawal := models.WithdrawalRequest{
			VendorID:          uuid.Nil,
			DeliveryPartnerID: &dp.ID,
			Amount:            req.Amount,
			FeeAmount:         0,
			NetAmount:         req.Amount,
			BankAccountDetails: models.JSONB(bankJSON),
			Status:            models.WithdrawPending,
		}
		if err := tx.Create(&withdrawal).Error; err != nil {
			return err
		}

		txn := models.WalletTransaction{
			WalletID:      wallet.ID,
			TxnType:       models.TxnTypeDebit,
			Amount:        req.Amount,
			RunningBalance: newBalance,
			ReferenceType: models.TxnRefWithdrawal,
			ReferenceID:   withdrawal.ID.String(),
			Description:   "Withdrawal request submitted",
			Status:        "pending",
			TxnDate:       time.Now(),
		}
		if err := tx.Create(&txn).Error; err != nil {
			return err
		}

		createdWithdrawal = withdrawal
		return nil
	})

	if err != nil {
		utils.InternalErrorResponse(c, "Failed to submit withdrawal request: "+err.Error())
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status": "success",
		"data":   createdWithdrawal,
	})
}

func (h *DeliveryWalletHandler) ListWithdrawals(c *gin.Context) {
	dp, _, err := h.getDriverProfile(c)
	if err != nil {
		utils.NotFoundResponse(c, "Driver profile not found")
		return
	}

	var requests []models.WithdrawalRequest
	h.db.Where("delivery_partner_id = ?", dp.ID).
		Order("created_at DESC").
		Find(&requests)

	utils.SuccessResponse(c, requests)
}
