package cart

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CartHandler struct {
	db *gorm.DB
}

func NewCartHandler(db *gorm.DB) *CartHandler {
	return &CartHandler{db: db}
}

type AddToCartRequest struct {
	ProductID uuid.UUID  `json:"product_id" binding:"required"`
	VariantID *uuid.UUID `json:"variant_id"`
	Quantity  int        `json:"quantity" binding:"required,gt=0"`
}

func (h *CartHandler) AddItem(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req AddToCartRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var product models.Product
	if err := h.db.Where("id = ? AND is_active = ? AND is_approved = ?", req.ProductID, true, true).First(&product).Error; err != nil {
		utils.BadRequestResponse(c, "Product not available")
		return
	}

	// Check existing cart item
	var existing models.CartItem
	result := h.db.Where("user_id = ? AND product_id = ?", userID, req.ProductID)
	if req.VariantID != nil {
		result = result.Where("variant_id = ?", *req.VariantID)
	} else {
		result = result.Where("variant_id IS NULL")
	}
	result.First(&existing)

	if existing.ID != uuid.Nil {
		existing.Quantity += req.Quantity
		if existing.Quantity > product.MaxOrderQty {
			existing.Quantity = product.MaxOrderQty
		}
		h.db.Save(&existing)
		utils.SuccessResponse(c, existing)
		return
	}

	cartItem := models.CartItem{
		UserID:    userID,
		ProductID: req.ProductID,
		VariantID: req.VariantID,
		Quantity:  req.Quantity,
		VendorID:  product.VendorID,
	}
	h.db.Create(&cartItem)

	h.db.Preload("Product.Images").Preload("Variant").First(&cartItem, cartItem.ID)
	utils.CreatedResponse(c, cartItem)
}

func (h *CartHandler) UpdateQuantity(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	itemID, err := uuid.Parse(c.Param("item_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid item ID")
		return
	}

	var req struct {
		Quantity int `json:"quantity" binding:"required,gt=0"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var item models.CartItem
	if err := h.db.Where("id = ? AND user_id = ?", itemID, userID).First(&item).Error; err != nil {
		utils.NotFoundResponse(c, "Cart item not found")
		return
	}

	item.Quantity = req.Quantity
	h.db.Save(&item)
	utils.SuccessResponse(c, item)
}

func (h *CartHandler) RemoveItem(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	itemID, err := uuid.Parse(c.Param("item_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid item ID")
		return
	}

	result := h.db.Where("id = ? AND user_id = ?", itemID, userID).Delete(&models.CartItem{})
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Cart item not found")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Item removed from cart"})
}

func (h *CartHandler) GetCart(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var items []models.CartItem
	h.db.Where("user_id = ?", userID).
		Preload("Product.Images").
		Preload("Product.Category").
		Preload("Variant").
		Preload("Vendor").
		Find(&items)

	var totalAmount float64
	var totalItems int
	vendorGroups := make(map[uuid.UUID][]models.CartItem)
	for _, item := range items {
		price := item.Product.BasePrice
		if item.Product.DiscountPrice > 0 {
			price = item.Product.DiscountPrice
		}
		if item.Variant != nil {
			if item.Variant.DiscountPrice > 0 {
				price = item.Variant.DiscountPrice
			} else {
				price = item.Variant.Price
			}
		}
		totalAmount += price * float64(item.Quantity)
		totalItems += item.Quantity
		vendorGroups[item.VendorID] = append(vendorGroups[item.VendorID], item)
	}

	utils.SuccessResponse(c, gin.H{
		"items":       items,
		"total_items": totalItems,
		"total_amount": totalAmount,
		"vendor_groups": vendorGroups,
	})
}

func (h *CartHandler) ClearCart(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	h.db.Where("user_id = ?", userID).Delete(&models.CartItem{})
	utils.SuccessResponse(c, gin.H{"message": "Cart cleared"})
}
