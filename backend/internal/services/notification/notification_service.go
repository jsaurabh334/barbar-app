package notification

import (
	"encoding/json"
	"time"

	"github.com/barbar-app/backend/internal/middleware"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationService struct {
	db  *gorm.DB
	hub *websocket.Hub
}

func NewNotificationService(db *gorm.DB, hub *websocket.Hub) *NotificationService {
	return &NotificationService{db: db, hub: hub}
}

type SendNotificationInput struct {
	UserID uuid.UUID              `json:"user_id"`
	Title  string                 `json:"title"`
	Body   string                 `json:"body"`
	Type   models.NotificationType `json:"type"`
	Data   map[string]interface{} `json:"data,omitempty"`
	Image  string                 `json:"image,omitempty"`
	Link   string                 `json:"link,omitempty"`
}

func (s *NotificationService) Send(input SendNotificationInput) error {
	now := time.Now()
	notification := models.Notification{
		UserID: input.UserID,
		Title:  input.Title,
		Body:   input.Body,
		Type:   input.Type,
		Image:  input.Image,
		Link:   input.Link,
		SentAt: &now,
	}

	if len(input.Data) > 0 {
		dataJSON, _ := json.Marshal(input.Data)
		json.Unmarshal(dataJSON, &notification.Data)
	}

	if err := s.db.Create(&notification).Error; err != nil {
		return err
	}

	// Send real-time via WebSocket
	s.hub.SendToUser(input.UserID, &websocket.WSMessage{
		Type:    websocket.MsgNotification,
		Payload: notification,
	})

	// Send push notification via FCM
	go s.sendPushNotification(input.UserID, notification)

	return nil
}

func (s *NotificationService) SendBulk(inputs []SendNotificationInput) {
	for _, input := range inputs {
		s.Send(input)
	}
}

func (s *NotificationService) SendToRole(role string, input SendNotificationInput) {
	var users []models.User
	s.db.Where("role = ? AND status = ?", role, models.UserStatusActive).Find(&users)
	for _, user := range users {
		input.UserID = user.ID
		s.Send(input)
	}
}

func (s *NotificationService) SendBookingConfirmation(booking *models.Booking) {
	customerNotif := SendNotificationInput{
		UserID: booking.CustomerID,
		Title:  "Booking Confirmed",
		Body:   "Your booking has been confirmed",
		Type:   models.NotifBookingConfirmed,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
			"status":     booking.Status,
		},
	}
	s.Send(customerNotif)

	// Notify barber
	var barber models.Barber
	s.db.First(&barber, booking.BarberID)
	barberNotif := SendNotificationInput{
		UserID: barber.UserID,
		Title:  "New Booking",
		Body:   "You have a new booking",
		Type:   models.NotifBookingConfirmed,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
		},
	}
	s.Send(barberNotif)
}

func (s *NotificationService) SendQueueUpdate(booking *models.Booking) {
	notif := SendNotificationInput{
		UserID: booking.CustomerID,
		Title:  "Queue Updated",
		Body:   "Your queue position has been updated",
		Type:   models.NotifQueueUpdate,
		Data: map[string]interface{}{
			"booking_id":        booking.ID.String(),
			"queue_position":    booking.QueuePosition,
			"estimated_wait":    booking.EstimatedWaitMin,
		},
	}
	s.Send(notif)
}

func (s *NotificationService) SendOrderConfirmation(order *models.Order) {
	notif := SendNotificationInput{
		UserID: order.CustomerID,
		Title:  "Order Placed",
		Body:   "Your order has been placed successfully",
		Type:   models.NotifOrderPlaced,
		Data: map[string]interface{}{
			"order_id":     order.ID.String(),
			"order_number": order.OrderNumber,
		},
	}
	s.Send(notif)

	var vendor models.Vendor
	s.db.First(&vendor, order.VendorID)
	vendorNotif := SendNotificationInput{
		UserID: vendor.UserID,
		Title:  "New Order",
		Body:   "You have received a new order",
		Type:   models.NotifOrderPlaced,
		Data: map[string]interface{}{
			"order_id":     order.ID.String(),
			"order_number": order.OrderNumber,
		},
	}
	s.Send(vendorNotif)
}

func (s *NotificationService) SendOrderStatusUpdate(order *models.Order) {
	notif := SendNotificationInput{
		UserID: order.CustomerID,
		Title:  "Order Updated",
		Body:   "Your order status: " + string(order.Status),
		Type:   models.NotifOrderConfirmed,
		Data: map[string]interface{}{
			"order_id": order.ID.String(),
			"status":   order.Status,
		},
	}
	s.Send(notif)
}

func (s *NotificationService) sendPushNotification(userID uuid.UUID, notification models.Notification) {
	var tokens []models.DeviceToken
	s.db.Where("user_id = ? AND is_active = ?", userID, true).Find(&tokens)
	if len(tokens) == 0 {
		return
	}

	DispatchPushNotification(s.db, tokens, notification)
}



func (s *NotificationService) GetUserNotifications(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	page, pageSize := utils.GetPageParams(c)

	var notifications []models.Notification
	var total int64

	s.db.Where("user_id = ?", userID).Count(&total)
	s.db.Where("user_id = ?", userID).Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&notifications)

	utils.PaginatedResponse(c, notifications, page, pageSize, total)
}

func (s *NotificationService) MarkAsRead(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	notifID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid notification ID")
		return
	}

	now := time.Now()
	s.db.Model(&models.Notification{}).Where("id = ? AND user_id = ?", notifID, userID).Updates(map[string]interface{}{
		"is_read":  true,
		"read_at": &now,
	})

	utils.SuccessResponse(c, gin.H{"message": "Marked as read"})
}

func (s *NotificationService) MarkAllAsRead(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	now := time.Now()
	s.db.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", userID, false).Updates(map[string]interface{}{
		"is_read":  true,
		"read_at": &now,
	})

	utils.SuccessResponse(c, gin.H{"message": "All marked as read"})
}

func (s *NotificationService) GetUnreadCount(userID uuid.UUID) int64 {
	var count int64
	s.db.Model(&models.Notification{}).Where("user_id = ? AND is_read = ?", userID, false).Count(&count)
	return count
}

func (s *NotificationService) RegisterDeviceToken(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		Token      string `json:"token" binding:"required"`
		Platform   string `json:"platform" binding:"required"`
		DeviceName string `json:"device_name"`
		AppVersion string `json:"app_version"`
		Role       string `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	device := models.DeviceToken{
		UserID:     userID,
		Token:      req.Token,
		Platform:   req.Platform,
		DeviceName: req.DeviceName,
		AppVersion: req.AppVersion,
		Role:       req.Role,
		IsActive:   true,
	}

	// Delete old token if exists
	s.db.Where("user_id = ? AND token = ?", userID, req.Token).Delete(&models.DeviceToken{})
	s.db.Create(&device)

	utils.SuccessResponse(c, device)
}

func (s *NotificationService) UnregisterDeviceToken(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	token := c.Param("token")

	s.db.Where("user_id = ? AND token = ?", userID, token).Delete(&models.DeviceToken{})
	utils.SuccessResponse(c, gin.H{"message": "Device unregistered"})
}

func (s *NotificationService) RegisterRoutes(r *gin.RouterGroup, authMiddleware *middleware.AuthMiddleware) {
	r.GET("/notifications", authMiddleware.Authenticate(), s.GetUserNotifications)
	r.PUT("/notifications/:id/read", authMiddleware.Authenticate(), s.MarkAsRead)
	r.PUT("/notifications/read-all", authMiddleware.Authenticate(), s.MarkAllAsRead)
	r.POST("/devices", authMiddleware.Authenticate(), s.RegisterDeviceToken)
	r.DELETE("/devices/:token", authMiddleware.Authenticate(), s.UnregisterDeviceToken)
}
