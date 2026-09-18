package admin

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	orderService "github.com/barbar-app/backend/internal/services/order"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminOrderHandler struct {
	db       *gorm.DB
	orderSvc *orderService.OrderService
}

func NewAdminOrderHandler(db *gorm.DB, orderSvc *orderService.OrderService) *AdminOrderHandler {
	return &AdminOrderHandler{db: db, orderSvc: orderSvc}
}

func (h *AdminOrderHandler) ListAllOrders(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var orders []models.Order
	var total int64

	query := h.db.Model(&models.Order{}).
		Preload("Items").
		Preload("Customer").
		Preload("Vendor").
		Preload("DeliveryPartner").
		Preload("ShippingAddress").
		Preload("StatusLog", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at ASC")
		}).
		Preload("Timeline", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at ASC")
		})

	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if paymentStatus := c.Query("payment_status"); paymentStatus != "" {
		query = query.Where("payment_status = ?", paymentStatus)
	}
	if vendorID := c.Query("vendor_id"); vendorID != "" {
		query = query.Where("vendor_id = ?", vendorID)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("order_number ILIKE ?", "%"+search+"%")
	}
	if dateFrom := c.Query("date_from"); dateFrom != "" {
		query = query.Where("created_at >= ?", dateFrom)
	}
	if dateTo := c.Query("date_to"); dateTo != "" {
		query = query.Where("created_at <= ?", dateTo)
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("created_at DESC").Find(&orders)

	utils.PaginatedResponse(c, orders, page, pageSize, total)
}

func (h *AdminOrderHandler) GetOrderDetail(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var order models.Order
	if err := h.db.
		Preload("Items").
		Preload("Customer").
		Preload("Vendor").
		Preload("DeliveryPartner").
		Preload("ShippingAddress").
		Preload("Payment").
		Preload("Refund").
		Preload("StatusLog", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at ASC")
		}).
		Preload("Timeline", func(db *gorm.DB) *gorm.DB {
			return db.Order("created_at ASC")
		}).
		First(&order, orderID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	utils.SuccessResponse(c, order)
}

type AdminUpdateOrderStatusRequest struct {
	Status string `json:"status" binding:"required"`
	Note   string `json:"note"`
}

func (h *AdminOrderHandler) UpdateOrderStatus(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var req AdminUpdateOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Status is required")
		return
	}

	targetStatus := models.OrderStatus(req.Status)
	if targetStatus == models.OrderStatusCancelled && strings.TrimSpace(req.Note) == "" {
		utils.BadRequestResponse(c, "Cancellation note/reason is required")
		return
	}

	var existingOrder models.Order
	if err := h.db.First(&existingOrder, orderID).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}
	previousStatus := string(existingOrder.Status)

	updated, err := h.orderSvc.TransitionOrder(
		c.Request.Context(),
		orderID,
		adminID,
		claims.Role,
		targetStatus,
		req.Note,
	)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	// Atomic/System-level Audit Log for Admin status mutation
	oldValJSON, _ := json.Marshal(map[string]interface{}{"status": previousStatus})
	newValJSON, _ := json.Marshal(map[string]interface{}{
		"status": req.Status,
		"note":   req.Note,
		"role":   claims.Role,
	})
	h.db.Create(&models.AuditLog{
		UserID:     adminID,
		Action:     "order_status_update",
		EntityType: "order",
		EntityID:   orderID.String(),
		OldValues:  models.JSONB(oldValJSON),
		NewValues:  models.JSONB(newValJSON),
		IPAddress:  c.ClientIP(),
		UserAgent:  c.GetHeader("User-Agent"),
		Endpoint:   c.Request.URL.Path,
		Method:     c.Request.Method,
		Status:     http.StatusOK,
	})

	utils.SuccessResponse(c, updated)
}

func (h *AdminOrderHandler) GetOrderTimeline(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var logs []models.OrderStatusLog
	if err := h.db.Where("order_id = ?", orderID).
		Order("created_at ASC").
		Find(&logs).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch order timeline")
		return
	}

	utils.SuccessResponse(c, logs)
}
