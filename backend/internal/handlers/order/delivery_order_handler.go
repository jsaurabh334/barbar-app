package order

import (
	"context"
	"fmt"

	"github.com/barbar-app/backend/internal/models"
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	orderService "github.com/barbar-app/backend/internal/services/order"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DeliveryOrderHandler struct {
	db             *gorm.DB
	service        *orderService.OrderService
	presenceSvc    *deliverySvc.PresenceService
}

func NewDeliveryOrderHandler(db *gorm.DB, service *orderService.OrderService, presenceSvc *deliverySvc.PresenceService) *DeliveryOrderHandler {
	return &DeliveryOrderHandler{db: db, service: service, presenceSvc: presenceSvc}
}

func (h *DeliveryOrderHandler) AssignDelivery(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.ClaimDeliveryOrder(c.Request.Context(), orderID, userID)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	if err := h.presenceSvc.SetBusy(context.Background(), userID, orderID); err != nil {
		// Log the error but don't fail the request since assignment was successful
		fmt.Printf("AssignDelivery: failed to mark driver %s busy: %v\n", userID, err)
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) AssignDriver(c *gin.Context) {
	var req struct {
		DeliveryUserID uuid.UUID `json:"delivery_user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "delivery_user_id is required")
		return
	}

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.AssignDriver(c.Request.Context(), orderID, req.DeliveryUserID, "admin")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) AcceptAssignment(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.AcceptAssignment(c.Request.Context(), orderID, userID)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	if err := h.presenceSvc.SetBusy(context.Background(), userID, orderID); err != nil {
		utils.InternalErrorResponse(c, "failed to mark driver busy: "+err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) RejectAssignment(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.RejectAssignment(c.Request.Context(), orderID, userID)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) PickupOrder(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), orderID, userID, "delivery", models.OrderStatusPickedUp, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) OutForDelivery(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), orderID, userID, "delivery", models.OrderStatusOutForDelivery, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) DeliverOrder(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), orderID, userID, "delivery", models.OrderStatusDelivered, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	if err := h.presenceSvc.SetAvailable(context.Background(), userID); err != nil {
		utils.InternalErrorResponse(c, "failed to set driver available: "+err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) VerifyDeliveryOTP(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var req struct {
		OTP     string `json:"otp" binding:"required"`
		OTPType string `json:"otp_type"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "OTP is required")
		return
	}

	updated, err := h.service.VerifyDeliveryOTP(c.Request.Context(), orderID, userID, req.OTP, req.OTPType)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	if err := h.presenceSvc.SetAvailable(context.Background(), userID); err != nil {
		utils.InternalErrorResponse(c, "failed to set driver available: "+err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) GetDeliveryOrder(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var order models.Order
	if err := h.db.Preload("Items").
		Preload("Customer").
		Preload("Vendor").
		Preload("ShippingAddress").
		First(&order, orderID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	if order.DeliveryPartnerID == nil || *order.DeliveryPartnerID != userID {
		utils.BadRequestResponse(c, "Not the assigned driver for this order")
		return
	}

	utils.SuccessResponse(c, order)
}

func (h *DeliveryOrderHandler) ListAssignedOrders(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var orders []models.Order
	h.db.Where("delivery_partner_id = ?", userID).
		Preload("Items").
		Preload("Customer").
		Preload("Vendor").
		Preload("ShippingAddress").
		Order("created_at DESC").
		Find(&orders)

	utils.SuccessResponse(c, orders)
}

func (h *DeliveryOrderHandler) RegenerateOTP(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	updated, err := h.service.RegenerateOTP(c.Request.Context(), orderID, userID, "delivery")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}
