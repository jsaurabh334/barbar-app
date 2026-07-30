package order

import (
	"context"
	"fmt"
	"time"

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
	h.db.Where("delivery_partner_id = ? OR delivery_partner_id IN (SELECT id FROM delivery_partners WHERE user_id = ?)", userID, userID).
		Preload("ShippingAddress").
		Preload("Items").
		Preload("Vendor").
		Order("created_at DESC").
		Limit(20).
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

func (h *DeliveryOrderHandler) AssignReturnPickup(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var req struct {
		DeliveryUserID uuid.UUID `json:"delivery_user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "delivery_user_id is required")
		return
	}

	var order models.Order
	if err := h.db.First(&order, orderID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}
	if order.Status != models.OrderStatusReturnApproved {
		utils.BadRequestResponse(c, "Return has not been approved for this order")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), orderID, req.DeliveryUserID, "admin", models.OrderStatusReturnPickupAssigned, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	go h.service.GenerateReturnPickupOTP(updated)

	utils.SuccessResponse(c, updated)
}

func (h *DeliveryOrderHandler) AcceptReturnPickup(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var order models.Order
	if err := h.db.First(&order, orderID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}
	if order.DeliveryPartnerID == nil || *order.DeliveryPartnerID != userID {
		utils.BadRequestResponse(c, "Not the assigned driver for this return pickup")
		return
	}
	if order.Status != models.OrderStatusReturnPickupAssigned {
		utils.BadRequestResponse(c, "Return pickup is not assigned to you")
		return
	}

	// Mark assignment as accepted
	var assignment models.OrderDeliveryAssignment
	if err := h.db.Where("order_id = ? AND delivery_user_id = ? AND status = ?",
		orderID, userID, models.AssignmentPending).
		Order("created_at DESC").First(&assignment).Error; err == nil {
		now := time.Now()
		h.db.Model(&assignment).Updates(map[string]interface{}{
			"status":      models.AssignmentAccepted,
			"accepted_at": now,
		})
	}

	utils.SuccessResponse(c, gin.H{"message": "Return pickup accepted"})
}

func (h *DeliveryOrderHandler) GetDeliveryDashboard(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	today := time.Now().Truncate(24 * time.Hour)

	var completedDeliveries int64
	h.db.Model(&models.Order{}).
		Where("delivery_partner_id = ? AND status = ? AND delivered_at >= ?", userID, models.OrderStatusDelivered, today).
		Count(&completedDeliveries)

	var todayEarnings float64
	h.db.Model(&models.DeliveryEarning{}).
		Joins("JOIN orders ON orders.id = delivery_earnings.order_id").
		Where("orders.delivery_partner_id = ? AND delivery_earnings.created_at >= ?", userID, today).
		Select("COALESCE(SUM(total_amount), 0)").
		Scan(&todayEarnings)

	var activeOrders int64
	h.db.Model(&models.Order{}).
		Where("delivery_partner_id = ? AND status IN (?)", userID,
			[]models.OrderStatus{
				models.OrderStatusDriverAssigned,
				models.OrderStatusDriverAccepted,
				models.OrderStatusPickedUp,
				models.OrderStatusOutForDelivery,
				models.OrderStatusReturnPickupAssigned,
				models.OrderStatusReturnPickedUp,
			}).
		Count(&activeOrders)

	var distance float64
	h.db.Model(&models.DeliveryPresenceLog{}).
		Where("user_id = ? AND created_at >= ?", userID, today).
		Select("COALESCE(SUM(distance_travelled), 0)").
		Scan(&distance)

	var pendingDeliveries int64
	h.db.Model(&models.Order{}).
		Where("delivery_partner_id = ? AND status = ?", userID, models.OrderStatusOutForDelivery).
		Count(&pendingDeliveries)

	utils.SuccessResponse(c, gin.H{
		"today_earnings":        todayEarnings,
		"completed_deliveries":  completedDeliveries,
		"active_orders":         activeOrders,
		"distance_travelled":    distance,
		"pending_deliveries":    pendingDeliveries,
	})
}
