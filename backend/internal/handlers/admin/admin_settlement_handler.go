package admin

import (
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminSettlementHandler struct {
	db *gorm.DB
}

func NewAdminSettlementHandler(db *gorm.DB) *AdminSettlementHandler {
	return &AdminSettlementHandler{db: db}
}

func (h *AdminSettlementHandler) ListSettlements(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	type SettlementRecord struct {
		ID           uuid.UUID `json:"id"`
		VendorID     uuid.UUID `json:"vendor_id"`
		BusinessName string    `json:"business_name"`
		Amount       float64   `json:"amount"`
		FeeAmount    float64   `json:"fee_amount"`
		NetAmount    float64   `json:"net_amount"`
		Status       string    `json:"status"`
		BankAccount  string    `json:"bank_account,omitempty"`
		UTRNumber    string    `json:"utr_number,omitempty"`
		CreatedAt    time.Time `json:"created_at"`
		ProcessedAt  *time.Time `json:"processed_at,omitempty"`
	}

	var settlements []SettlementRecord
	var total int64

	query := h.db.Model(&models.WithdrawalRequest{}).
		Select(`withdrawal_requests.id, withdrawal_requests.vendor_id, 
			COALESCE(vendors.business_name, '') as business_name,
			withdrawal_requests.amount, withdrawal_requests.fee_amount, 
			withdrawal_requests.net_amount, withdrawal_requests.status,
			withdrawal_requests.bank_account_details->>'account_number' as bank_account,
			withdrawal_requests.utr_number, withdrawal_requests.created_at,
			withdrawal_requests.processed_at`).
		Joins("LEFT JOIN vendors ON vendors.id = withdrawal_requests.vendor_id")

	if status := c.Query("status"); status != "" {
		query = query.Where("withdrawal_requests.status = ?", status)
	}
	if vendorID := c.Query("vendor_id"); vendorID != "" {
		query = query.Where("withdrawal_requests.vendor_id = ?", vendorID)
	}
	if dateFrom := c.Query("date_from"); dateFrom != "" {
		query = query.Where("withdrawal_requests.created_at >= ?", dateFrom)
	}
	if dateTo := c.Query("date_to"); dateTo != "" {
		query = query.Where("withdrawal_requests.created_at <= ?", dateTo)
	}
	if minAmount := c.Query("min_amount"); minAmount != "" {
		query = query.Where("withdrawal_requests.amount >= ?", minAmount)
	}
	if maxAmount := c.Query("max_amount"); maxAmount != "" {
		query = query.Where("withdrawal_requests.amount <= ?", maxAmount)
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("withdrawal_requests.created_at DESC").Find(&settlements)

	utils.PaginatedResponse(c, settlements, page, pageSize, total)
}

func (h *AdminSettlementHandler) GetSettlementDetail(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid settlement ID")
		return
	}

	var withdrawal models.WithdrawalRequest
	if err := h.db.Preload("Vendor").First(&withdrawal, id).Error; err != nil {
		utils.NotFoundResponse(c, "Settlement not found")
		return
	}

	utils.SuccessResponse(c, withdrawal)
}

func (h *AdminSettlementHandler) ProcessSettlement(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid settlement ID")
		return
	}

	var req struct {
		Status    string  `json:"status" binding:"required,oneof=approved rejected processed"`
		AdminNotes string `json:"admin_notes"`
		UTRNumber  string `json:"utr_number"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var withdrawal models.WithdrawalRequest
	if err := h.db.First(&withdrawal, id).Error; err != nil {
		utils.NotFoundResponse(c, "Settlement not found")
		return
	}

	updates := map[string]interface{}{
		"status":     models.WithdrawalRequestStatus(req.Status),
		"admin_id":   adminID,
		"admin_notes": req.AdminNotes,
	}

	switch req.Status {
	case "processed":
		updates["processed_at"] = time.Now()
		updates["utr_number"] = req.UTRNumber
		h.db.Model(&models.Wallet{}).Where("vendor_id = ?", withdrawal.VendorID).
			Update("locked_balance", gorm.Expr("locked_balance - ?", withdrawal.Amount))
	case "rejected":
		h.db.Model(&models.Wallet{}).Where("vendor_id = ?", withdrawal.VendorID).Updates(map[string]interface{}{
			"balance":        gorm.Expr("balance + ?", withdrawal.Amount),
			"locked_balance": gorm.Expr("locked_balance - ?", withdrawal.Amount),
		})
	}

	h.db.Model(&withdrawal).Updates(updates)
	utils.SuccessResponse(c, gin.H{"message": "Settlement " + req.Status})
}

func (h *AdminSettlementHandler) BulkProcessSettlements(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)

	var req struct {
		IDs       []string `json:"ids" binding:"required,min=1"`
		Status    string   `json:"status" binding:"required,oneof=approved rejected processed"`
		UTRNumber string   `json:"utr_number"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var processed int
	var failed int

	for _, idStr := range req.IDs {
		id, err := uuid.Parse(idStr)
		if err != nil {
			failed++
			continue
		}

		var withdrawal models.WithdrawalRequest
		if err := h.db.First(&withdrawal, id).Error; err != nil {
			failed++
			continue
		}

		updates := map[string]interface{}{
			"status":   models.WithdrawalRequestStatus(req.Status),
			"admin_id": adminID,
		}

		if req.Status == "processed" {
			updates["processed_at"] = time.Now()
			updates["utr_number"] = req.UTRNumber
			h.db.Model(&models.Wallet{}).Where("vendor_id = ?", withdrawal.VendorID).
				Update("locked_balance", gorm.Expr("locked_balance - ?", withdrawal.Amount))
		} else if req.Status == "rejected" {
			h.db.Model(&models.Wallet{}).Where("vendor_id = ?", withdrawal.VendorID).Updates(map[string]interface{}{
				"balance":        gorm.Expr("balance + ?", withdrawal.Amount),
				"locked_balance": gorm.Expr("locked_balance - ?", withdrawal.Amount),
			})
		}

		h.db.Model(&withdrawal).Updates(updates)
		processed++
	}

	utils.SuccessResponse(c, gin.H{
		"message":   "Bulk process completed",
		"processed": processed,
		"failed":    failed,
	})
}
