package kyc

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type KYCHandler struct {
	db *gorm.DB
}

func NewKYCHandler(db *gorm.DB) *KYCHandler {
	return &KYCHandler{db: db}
}

func (h *KYCHandler) SubmitKYC(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		DocType     string `json:"doc_type" binding:"required"`
		DocFrontURL string `json:"doc_front_url" binding:"required"`
		DocBackURL  string `json:"doc_back_url"`
		DocNumber   string `json:"doc_number"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	// Check if a document of same type already exists
	var existing models.KYCDocument
	if err := h.db.Where("user_id = ? AND doc_type = ?", userID, req.DocType).First(&existing).Error; err == nil {
		h.db.Model(&existing).Updates(map[string]interface{}{
			"doc_front_url": req.DocFrontURL,
			"doc_back_url":  req.DocBackURL,
			"doc_number":    req.DocNumber,
			"status":        "pending",
			"verified_by":   nil,
			"verified_at":   nil,
			"reject_reason": "",
		})
		utils.SuccessResponse(c, existing)
		return
	}

	doc := models.KYCDocument{
		UserID:      userID,
		DocType:     req.DocType,
		DocFrontURL: req.DocFrontURL,
		DocBackURL:  req.DocBackURL,
		DocNumber:   req.DocNumber,
		Status:      "pending",
	}
	h.db.Create(&doc)
	utils.CreatedResponse(c, doc)
}

func (h *KYCHandler) GetMyKYC(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var docs []models.KYCDocument
	h.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&docs)
	utils.SuccessResponse(c, docs)
}
