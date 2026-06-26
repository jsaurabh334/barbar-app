package wallet

import (
	"encoding/json"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WalletHandler struct {
	db *gorm.DB
}

func NewWalletHandler(db *gorm.DB) *WalletHandler {
	return &WalletHandler{db: db}
}

func (h *WalletHandler) GetBalance(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	role := c.MustGet("claims").(*auth.Claims).Role

	var wallet models.Wallet
	if role == string(models.RoleVendor) {
		var vendor models.Vendor
		h.db.Where("user_id = ?", userID).First(&vendor)
		h.db.Where("vendor_id = ?", vendor.ID).First(&wallet)
	} else {
		h.db.Where("user_id = ?", userID).First(&wallet)
	}

	if wallet.ID == uuid.Nil {
		wallet = models.Wallet{UserID: &userID, Balance: 0}
		h.db.Create(&wallet)
	}

	utils.SuccessResponse(c, wallet)
}

func (h *WalletHandler) GetTransactions(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	role := c.MustGet("claims").(*auth.Claims).Role

	page, pageSize := utils.GetPageParams(c)

	var wallet models.Wallet
	if role == string(models.RoleVendor) {
		var vendor models.Vendor
		h.db.Where("user_id = ?", userID).First(&vendor)
		h.db.Where("vendor_id = ?", vendor.ID).First(&wallet)
	} else {
		h.db.Where("user_id = ?", userID).First(&wallet)
	}

	var transactions []models.WalletTransaction
	var total int64

	query := h.db.Where("wallet_id = ?", wallet.ID)
	if txnType := c.Query("type"); txnType != "" {
		query = query.Where("txn_type = ?", txnType)
	}
	if refType := c.Query("reference_type"); refType != "" {
		query = query.Where("reference_type = ?", refType)
	}

	query.Model(&models.WalletTransaction{}).Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&transactions)

	utils.PaginatedResponse(c, transactions, page, pageSize, total)
}

func (h *WalletHandler) RequestWithdrawal(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.NotFoundResponse(c, "Vendor profile not found")
		return
	}

	var req struct {
		Amount        float64   `json:"amount" binding:"required,min=500"`
		BankAccountID uuid.UUID `json:"bank_account_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var wallet models.Wallet
	if err := h.db.Where("vendor_id = ?", vendor.ID).First(&wallet).Error; err != nil {
		utils.NotFoundResponse(c, "Wallet not found")
		return
	}

	if wallet.Balance < req.Amount {
		utils.BadRequestResponse(c, "Insufficient balance")
		return
	}

	// Check max withdrawals per month
	var monthCount int64
	monthStart := time.Date(time.Now().Year(), time.Now().Month(), 1, 0, 0, 0, 0, time.UTC)
	h.db.Model(&models.WithdrawalRequest{}).Where("vendor_id = ? AND created_at >= ?", vendor.ID, monthStart).Count(&monthCount)

	var maxWithdrawalsPerMonth int64 = 5 // Configurable
	if monthCount >= maxWithdrawalsPerMonth {
		utils.BadRequestResponse(c, "Monthly withdrawal limit reached")
		return
	}

	// Get bank account details
	var bankAccount models.VendorBankAccount
	if err := h.db.Where("id = ? AND vendor_id = ?", req.BankAccountID, vendor.ID).First(&bankAccount).Error; err != nil {
		utils.BadRequestResponse(c, "Bank account not found")
		return
	}

	fee := req.Amount * 0.02 // 2% withdrawal fee
	if fee < 5 {
		fee = 5
	}
	netAmount := req.Amount - fee

	withdrawal := models.WithdrawalRequest{
		VendorID:      vendor.ID,
		Amount:        req.Amount,
		FeeAmount:     fee,
		NetAmount:     netAmount,
		BankAccountID: &bankAccount.ID,
		Status:        models.WithdrawPending,
	}

	bankDetails, _ := json.Marshal(map[string]interface{}{
		"account_holder": bankAccount.AccountHolderName,
		"account_number": maskAccountNumber(bankAccount.AccountNumber),
		"ifsc":           bankAccount.IFSCCode,
		"bank_name":      bankAccount.BankName,
	})
	json.Unmarshal(bankDetails, &withdrawal.BankAccountDetails)

	if err := h.db.Create(&withdrawal).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create withdrawal request")
		return
	}

	// Lock the amount in wallet
	h.db.Model(&wallet).Updates(map[string]interface{}{
		"balance":        gorm.Expr("balance - ?", req.Amount),
		"locked_balance": gorm.Expr("locked_balance + ?", req.Amount),
	})

	utils.CreatedResponse(c, withdrawal)
}

func (h *WalletHandler) ListWithdrawals(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var vendor models.Vendor
	h.db.Where("user_id = ?", userID).First(&vendor)

	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")

	var withdrawals []models.WithdrawalRequest
	var total int64

	query := h.db.Where("vendor_id = ?", vendor.ID)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	query.Model(&models.WithdrawalRequest{}).Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&withdrawals)

	utils.PaginatedResponse(c, withdrawals, page, pageSize, total)
}

func maskAccountNumber(number string) string {
	if len(number) < 8 {
		return "****" + number[len(number)-4:]
	}
	return "XXXX-XXXX-" + number[len(number)-4:]
}
