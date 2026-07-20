package delivery

import (
	"time"

	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	orderService "github.com/barbar-app/backend/internal/services/order"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type LocationHandler struct {
	presenceService *deliverySvc.PresenceService
	orderService    *orderService.OrderService
}

func NewLocationHandler(presenceService *deliverySvc.PresenceService, orderService *orderService.OrderService) *LocationHandler {
	return &LocationHandler{
		presenceService: presenceService,
		orderService:    orderService,
	}
}

type updateLocationRequest struct {
	Latitude  float64   `json:"latitude" binding:"required"`
	Longitude float64   `json:"longitude" binding:"required"`
	Accuracy  float64   `json:"accuracy,omitempty"`
	Speed     float64   `json:"speed,omitempty"`
	Bearing   float64   `json:"bearing,omitempty"`
	Timestamp time.Time `json:"timestamp" binding:"required"`
}

func (h *LocationHandler) UpdateLocation(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req updateLocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if time.Since(req.Timestamp) > 30*time.Second {
		utils.BadRequestResponse(c, "Location timestamp is stale (>30 seconds old)")
		return
	}

	var orderID *uuid.UUID
	order, err := h.orderService.FindActiveOrderByDriver(c.Request.Context(), userID)
	if err == nil && order != nil {
		orderID = &order.ID
	}

	accepted, err := h.presenceService.UpdateLocation(c.Request.Context(), userID, deliverySvc.LocationUpdate{
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
		Accuracy:  req.Accuracy,
		Speed:     req.Speed,
		Bearing:   req.Bearing,
		Timestamp: req.Timestamp,
	}, orderID)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	if !accepted {
		utils.SuccessResponse(c, gin.H{"accepted": false, "message": "Rate-limited (too soon or too close)"})
		return
	}

	utils.SuccessResponse(c, gin.H{"accepted": true, "message": "Location updated"})
}

func (h *LocationHandler) GetDriverLocation(c *gin.Context) {
	orderIDStr := c.Param("id")
	orderID, err := uuid.Parse(orderIDStr)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	order, err := h.orderService.GetOrderByID(c.Request.Context(), orderID)
	if err != nil || order.DeliveryPartnerID == nil {
		utils.NotFoundResponse(c, "No driver assigned to this order")
		return
	}

	driverID := *order.DeliveryPartnerID
	presence, err := h.presenceService.GetPresence(c.Request.Context(), driverID)
	if err != nil {
		utils.NotFoundResponse(c, "Driver not found or offline")
		return
	}

	resp := gin.H{
		"order_id":   orderID.String(),
		"user_id":    driverID.String(),
		"latitude":   presence["latitude"],
		"longitude":  presence["longitude"],
		"speed":      presence["speed"],
		"bearing":    presence["bearing"],
		"accuracy":   presence["accuracy"],
		"updated_at": presence["updated_at"],
		"status":     presence["status"],
	}

	if eta, err := h.presenceService.GetETA(c.Request.Context(), orderID); err == nil {
		resp["eta_minutes"] = eta["eta_minutes"]
		resp["distance_km"] = eta["distance_km"]
	}

	utils.SuccessResponse(c, resp)
}

func (h *LocationHandler) GetOrderETA(c *gin.Context) {
	orderIDStr := c.Param("id")
	orderID, err := uuid.Parse(orderIDStr)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	eta, err := h.presenceService.GetETA(c.Request.Context(), orderID)
	if err != nil {
		utils.NotFoundResponse(c, "ETA not available")
		return
	}

	utils.SuccessResponse(c, eta)
}
