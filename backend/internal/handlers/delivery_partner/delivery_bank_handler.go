package delivery_partner

import (
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type BankHandler struct {
	bankSvc *deliverySvc.BankAccountService
}

func NewBankHandler(bankSvc *deliverySvc.BankAccountService) *BankHandler {
	return &BankHandler{bankSvc: bankSvc}
}

func (h *BankHandler) GetBankAccount(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	account, err := h.bankSvc.GetByPartnerID(userID)
	if err != nil {
		utils.NotFoundResponse(c, "Bank account not found")
		return
	}
	utils.SuccessResponse(c, account)
}

func (h *BankHandler) UpsertBankAccount(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		AccountHolderName string `json:"account_holder_name" binding:"required"`
		AccountNumber     string `json:"account_number" binding:"required"`
		IFSCCode          string `json:"ifsc_code" binding:"required"`
		BankName          string `json:"bank_name" binding:"required"`
		BranchName        string `json:"branch_name"`
		UPIID             string `json:"upi_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	account, err := h.bankSvc.Upsert(userID, deliverySvc.UpsertBankAccountInput{
		AccountHolderName: req.AccountHolderName,
		AccountNumber:     req.AccountNumber,
		IFSCCode:          req.IFSCCode,
		BankName:          req.BankName,
		BranchName:        req.BranchName,
		UPIID:             req.UPIID,
	})
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to save bank account")
		return
	}
	utils.SuccessResponse(c, account)
}

func (h *BankHandler) DeleteBankAccount(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	if err := h.bankSvc.Delete(userID); err != nil {
		utils.NotFoundResponse(c, "Bank account not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "Bank account deleted"})
}
