package order

import (
	"github.com/barbar-app/backend/internal/models"
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	orderService "github.com/barbar-app/backend/internal/services/order"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type VendorOrderHandler struct {
	db          *gorm.DB
	service     *orderService.OrderService
	presenceSvc *deliverySvc.PresenceService
}

func NewVendorOrderHandler(db *gorm.DB, service *orderService.OrderService, presenceSvc *deliverySvc.PresenceService) *VendorOrderHandler {
	return &VendorOrderHandler{db: db, service: service, presenceSvc: presenceSvc}
}

func (h *VendorOrderHandler) vendorFromUser(c *gin.Context) (*models.Vendor, bool) {
	userID := c.MustGet("user").(uuid.UUID)
	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.NotFoundResponse(c, "Vendor profile not found")
		return nil, false
	}
	return &vendor, true
}

func (h *VendorOrderHandler) loadOrder(c *gin.Context) (*models.Order, bool) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return nil, false
	}
	var order models.Order
	if err := h.db.First(&order, orderID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return nil, false
	}
	return &order, true
}

func (h *VendorOrderHandler) AcceptOrder(c *gin.Context) {
	vendor, ok := h.vendorFromUser(c)
	if !ok {
		return
	}
	order, ok := h.loadOrder(c)
	if !ok {
		return
	}
	if order.VendorID != vendor.ID {
		utils.ForbiddenResponse(c, "This order does not belong to your vendor account")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), order.ID, vendor.UserID, "vendor", models.OrderStatusAccepted, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *VendorOrderHandler) RejectOrder(c *gin.Context) {
	vendor, ok := h.vendorFromUser(c)
	if !ok {
		return
	}
	order, ok := h.loadOrder(c)
	if !ok {
		return
	}
	if order.VendorID != vendor.ID {
		utils.ForbiddenResponse(c, "This order does not belong to your vendor account")
		return
	}

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Reason is required")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), order.ID, vendor.UserID, "vendor", models.OrderStatusCancelled, req.Reason)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *VendorOrderHandler) PackOrder(c *gin.Context) {
	vendor, ok := h.vendorFromUser(c)
	if !ok {
		return
	}
	order, ok := h.loadOrder(c)
	if !ok {
		return
	}
	if order.VendorID != vendor.ID {
		utils.ForbiddenResponse(c, "This order does not belong to your vendor account")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), order.ID, vendor.UserID, "vendor", models.OrderStatusPacked, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *VendorOrderHandler) ReadyForPickup(c *gin.Context) {
	vendor, ok := h.vendorFromUser(c)
	if !ok {
		return
	}
	order, ok := h.loadOrder(c)
	if !ok {
		return
	}
	if order.VendorID != vendor.ID {
		utils.ForbiddenResponse(c, "This order does not belong to your vendor account")
		return
	}

	updated, err := h.service.TransitionOrder(c.Request.Context(), order.ID, vendor.UserID, "vendor", models.OrderStatusReadyForPickup, "")
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, updated)
}

func (h *VendorOrderHandler) GetVendorOrderDelivery(c *gin.Context) {
	vendor, ok := h.vendorFromUser(c)
	if !ok {
		return
	}
	order, ok := h.loadOrder(c)
	if !ok {
		return
	}
	if order.VendorID != vendor.ID {
		utils.ForbiddenResponse(c, "This order does not belong to your vendor account")
		return
	}

	// Reload with delivery partner and status log
	var fullOrder models.Order
	if err := h.db.
		Preload("DeliveryPartner").
		Preload("StatusLog").
		Preload("PickupWarehouse").
		First(&fullOrder, order.ID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	resp := gin.H{
		"order_id":    fullOrder.ID.String(),
		"status":      fullOrder.Status,
		"assigned_at": fullOrder.AssignedAt,
		"picked_up_at": fullOrder.PickedUpAt,
		"delivered_at": fullOrder.DeliveredAt,
		"status_log":  fullOrder.StatusLog,
		"warehouse":   fullOrder.PickupWarehouse,
	}

	if fullOrder.DeliveryPartner != nil {
		partnerInfo := gin.H{
			"id":        fullOrder.DeliveryPartner.ID.String(),
			"name":      fullOrder.DeliveryPartner.FullName,
			"phone":     fullOrder.DeliveryPartner.Phone,
			"avatar":    fullOrder.DeliveryPartner.Avatar,
		}

		// Get delivery partner profile for vehicle info
		var dp models.DeliveryPartner
		if err := h.db.Where("user_id = ?", fullOrder.DeliveryPartner.ID).First(&dp).Error; err == nil {
			partnerInfo["vehicle_type"] = dp.VehicleType
			partnerInfo["vehicle_number"] = dp.VehicleNumber
			partnerInfo["rating"] = dp.Rating
		}

		resp["delivery_partner"] = partnerInfo

		// Get live location + ETA
		presence, err := h.presenceSvc.GetPresence(c.Request.Context(), fullOrder.DeliveryPartner.ID)
		if err == nil {
			resp["driver_location"] = presence
		}

		eta, err := h.presenceSvc.GetETA(c.Request.Context(), fullOrder.ID)
		if err == nil {
			resp["eta"] = eta
		}
	}

	utils.SuccessResponse(c, resp)
}
