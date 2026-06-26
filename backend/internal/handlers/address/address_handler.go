package address

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AddressHandler struct {
	db *gorm.DB
}

func NewAddressHandler(db *gorm.DB) *AddressHandler {
	return &AddressHandler{db: db}
}

func (h *AddressHandler) List(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var addresses []models.Address
	h.db.Where("user_id = ?", userID).Order("is_default DESC, created_at DESC").Find(&addresses)

	utils.SuccessResponse(c, addresses)
}

func (h *AddressHandler) Create(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		Label       string  `json:"label" binding:"required"`
		FullName    string  `json:"full_name" binding:"required"`
		Phone       string  `json:"phone" binding:"required"`
		Pincode     string  `json:"pincode" binding:"required"`
		Line1       string  `json:"line_1" binding:"required"`
		Line2       string  `json:"line_2"`
		Landmark    string  `json:"landmark"`
		City        string  `json:"city" binding:"required"`
		State       string  `json:"state" binding:"required"`
		Country     string  `json:"country"`
		Latitude    float64 `json:"latitude"`
		Longitude   float64 `json:"longitude"`
		IsDefault   bool    `json:"is_default"`
		AddressType string  `json:"address_type"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if req.Country == "" {
		req.Country = "India"
	}

	if req.IsDefault {
		h.db.Model(&models.Address{}).Where("user_id = ?", userID).Update("is_default", false)
	}

	addr := models.Address{
		UserID:      userID,
		Label:       req.Label,
		FullName:    req.FullName,
		Phone:       req.Phone,
		Pincode:     req.Pincode,
		Line1:       req.Line1,
		Line2:       req.Line2,
		Landmark:    req.Landmark,
		City:        req.City,
		State:       req.State,
		Country:     req.Country,
		Latitude:    req.Latitude,
		Longitude:   req.Longitude,
		IsDefault:   req.IsDefault,
		AddressType: req.AddressType,
	}

	if err := h.db.Create(&addr).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create address")
		return
	}

	utils.CreatedResponse(c, addr)
}

func (h *AddressHandler) Update(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid address ID")
		return
	}

	var existing models.Address
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&existing).Error; err != nil {
		utils.NotFoundResponse(c, "Address not found")
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	allowed := []string{"label", "full_name", "phone", "pincode", "line_1", "line_2", "landmark",
		"city", "state", "country", "latitude", "longitude", "address_type"}

	if val, ok := updates["is_default"]; ok {
		if val.(bool) {
			h.db.Model(&models.Address{}).Where("user_id = ?", userID).Update("is_default", false)
		}
	}

	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}
	if val, ok := updates["is_default"]; ok {
		filtered["is_default"] = val
	}

	if err := h.db.Model(&existing).Updates(filtered).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update address")
		return
	}

	h.db.First(&existing, id)
	utils.SuccessResponse(c, existing)
}

func (h *AddressHandler) Delete(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid address ID")
		return
	}

	result := h.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Address{})
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Address not found")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Address deleted"})
}

func (h *AddressHandler) SetDefault(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid address ID")
		return
	}

	var addr models.Address
	if err := h.db.Where("id = ? AND user_id = ?", id, userID).First(&addr).Error; err != nil {
		utils.NotFoundResponse(c, "Address not found")
		return
	}

	tx := h.db.Begin()
	tx.Model(&models.Address{}).Where("user_id = ?", userID).Update("is_default", false)
	tx.Model(&addr).Update("is_default", true)
	tx.Commit()

	utils.SuccessResponse(c, gin.H{"message": "Default address set"})
}
