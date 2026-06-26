package coupon

import (
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type CouponHandler struct {
	db *gorm.DB
}

func NewCouponHandler(db *gorm.DB) *CouponHandler {
	return &CouponHandler{db: db}
}

type CreateCouponRequest struct {
	Code            string    `json:"code" binding:"required"`
	Description     string    `json:"description"`
	Type            string    `json:"type" binding:"required,oneof=percentage fixed free_shipping"`
	Value           float64   `json:"value" binding:"required,gt=0"`
	MinOrderAmount  float64   `json:"min_order_amount"`
	MaxDiscount     float64   `json:"max_discount"`
	UsageLimit      int       `json:"usage_limit"`
	PerUserLimit    int       `json:"per_user_limit"`
	ValidFrom       time.Time `json:"valid_from" binding:"required"`
	ValidTo         time.Time `json:"valid_to" binding:"required"`
	ApplicableTo    string    `json:"applicable_to"`
	VendorID        *uuid.UUID `json:"vendor_id,omitempty"`
	CategoryID      *uuid.UUID `json:"category_id,omitempty"`
	MinItems        int       `json:"min_items"`
	CustomerSegment string    `json:"customer_segment"`
}

func (h *CouponHandler) Create(c *gin.Context) {
	var req CreateCouponRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	coupon := models.Coupon{
		Code:            req.Code,
		Description:     req.Description,
		Type:            models.CouponType(req.Type),
		Value:           req.Value,
		MinOrderAmount:  req.MinOrderAmount,
		MaxDiscount:     req.MaxDiscount,
		UsageLimit:      req.UsageLimit,
		PerUserLimit:    req.PerUserLimit,
		IsActive:        true,
		ValidFrom:       req.ValidFrom,
		ValidTo:         req.ValidTo,
		ApplicableTo:    req.ApplicableTo,
		VendorID:        req.VendorID,
		CategoryID:      req.CategoryID,
		MinItems:        req.MinItems,
		CustomerSegment: req.CustomerSegment,
	}

	if err := h.db.Create(&coupon).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create coupon")
		return
	}

	utils.CreatedResponse(c, coupon)
}

func (h *CouponHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid coupon ID")
		return
	}

	var coupon models.Coupon
	if err := h.db.First(&coupon, id).Error; err != nil {
		utils.NotFoundResponse(c, "Coupon not found")
		return
	}

	var updates map[string]interface{}
	c.ShouldBindJSON(&updates)

	allowed := []string{"description", "value", "min_order_amount", "max_discount", "usage_limit",
		"is_active", "valid_from", "valid_to", "per_user_limit"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	h.db.Model(&coupon).Updates(filtered)
	utils.SuccessResponse(c, coupon)
}

func (h *CouponHandler) List(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var coupons []models.Coupon
	var total int64

	query := h.db.Model(&models.Coupon{})
	if isActive := c.Query("is_active"); isActive != "" {
		query = query.Where("is_active = ?", isActive == "true")
	}
	if vendorID := c.Query("vendor_id"); vendorID != "" {
		query = query.Where("vendor_id = ?", vendorID)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&coupons)

	utils.PaginatedResponse(c, coupons, page, pageSize, total)
}

func (h *CouponHandler) Validate(c *gin.Context) {
	var req struct {
		Code    string  `json:"code" binding:"required"`
		OrderAmount float64 `json:"order_amount" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var coupon models.Coupon
	if err := h.db.Where("code = ? AND is_active = ? AND valid_from <= ? AND valid_to >= ?",
		req.Code, true, time.Now(), time.Now()).First(&coupon).Error; err != nil {
		utils.BadRequestResponse(c, "Invalid or expired coupon")
		return
	}

	if coupon.UsageLimit > 0 && coupon.UsedCount >= coupon.UsageLimit {
		utils.BadRequestResponse(c, "Coupon usage limit reached")
		return
	}

	if req.OrderAmount < coupon.MinOrderAmount {
		utils.BadRequestResponse(c, "Minimum order amount not met. Required: "+fmt.Sprintf("%.2f", coupon.MinOrderAmount))
		return
	}

	var discount float64
	switch coupon.Type {
	case models.CouponTypePercentage:
		discount = req.OrderAmount * coupon.Value / 100
		if coupon.MaxDiscount > 0 && discount > coupon.MaxDiscount {
			discount = coupon.MaxDiscount
		}
	case models.CouponTypeFixed:
		discount = coupon.Value
	}

	utils.SuccessResponse(c, gin.H{
		"valid":           true,
		"coupon":          coupon,
		"discount_amount": discount,
	})
}

func (h *CouponHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid coupon ID")
		return
	}

	h.db.Delete(&models.Coupon{}, id)
	utils.SuccessResponse(c, gin.H{"message": "Coupon deleted"})
}
