package wishlist

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WishlistHandler struct {
	db *gorm.DB
}

func NewWishlistHandler(db *gorm.DB) *WishlistHandler {
	return &WishlistHandler{db: db}
}

func (h *WishlistHandler) Add(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		ProductID uuid.UUID `json:"product_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var existing models.WishlistItem
	result := h.db.Where("user_id = ? AND product_id = ?", userID, req.ProductID).First(&existing)
	if result.RowsAffected > 0 {
		utils.SuccessResponse(c, existing)
		return
	}

	item := models.WishlistItem{
		UserID:    userID,
		ProductID: req.ProductID,
	}
	h.db.Create(&item)
	utils.CreatedResponse(c, item)
}

func (h *WishlistHandler) Remove(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("product_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	result := h.db.Where("user_id = ? AND product_id = ?", userID, productID).Delete(&models.WishlistItem{})
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Item not in wishlist")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Removed from wishlist"})
}

func (h *WishlistHandler) GetAll(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var items []models.WishlistItem
	h.db.Where("user_id = ?", userID).
		Preload("Product.Images").
		Preload("Product.Category").
		Order("created_at DESC").
		Find(&items)

	utils.SuccessResponse(c, items)
}

func (h *WishlistHandler) Check(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("product_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var count int64
	h.db.Model(&models.WishlistItem{}).Where("user_id = ? AND product_id = ?", userID, productID).Count(&count)

	utils.SuccessResponse(c, gin.H{"in_wishlist": count > 0})
}
