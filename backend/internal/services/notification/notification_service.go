package notification

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/barbar-app/backend/internal/config"
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
	notification := models.Notification{
		UserID: input.UserID,
		Title:  input.Title,
		Body:   input.Body,
		Type:   input.Type,
		Image:  input.Image,
		Link:   input.Link,
		SentAt: time.Now(),
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

	cfg := config.Load()
	serverKey := cfg.FCM.ServerKey
	if serverKey == "" {
		return
	}

	payload := buildFCMPayload(tokens, notification)
	data, _ := json.Marshal(payload)
	tokenList := make([]models.DeviceToken, len(tokens))
	copy(tokenList, tokens)

	utils.DefaultPool.SubmitNamed("fcm_"+string(notification.Type), func(p interface{}) error {
		req, err := http.NewRequest("POST", "https://fcm.googleapis.com/fcm/send", bytes.NewBuffer(data))
		if err != nil {
			return err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "key="+serverKey)

		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		defer resp.Body.Close()

		if resp.StatusCode == 200 {
			var fcmResp FCMResponse
			if json.NewDecoder(resp.Body).Decode(&fcmResp) == nil {
				for i, result := range fcmResp.Results {
					if result.Error != "" && i < len(tokenList) {
						s.db.Model(&models.DeviceToken{}).Where("token = ?", tokenList[i].Token).
							Update("is_active", false)
					}
				}
			}
		}
		return nil
	}, nil)
}

type FCMNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
	Image string `json:"image,omitempty"`
}

type FCMData struct {
	Type        string `json:"type,omitempty"`
	ID          string `json:"id,omitempty"`
	DeepLink    string `json:"deep_link,omitempty"`
	Image       string `json:"image,omitempty"`
}

type FCMMessage struct {
	To           string        `json:"to,omitempty"`
	RegistrationIDs []string   `json:"registration_ids,omitempty"`
	Notification FCMNotification `json:"notification"`
	Data         FCMData       `json:"data,omitempty"`
	Priority     string        `json:"priority,omitempty"`
	MutableContent bool        `json:"mutable_content,omitempty"`
}

type FCMResponse struct {
	MulticastID  int64 `json:"multicast_id"`
	Success      int   `json:"success"`
	Failure      int   `json:"failure"`
	CanonicalIDs int   `json:"canonical_ids"`
	Results      []struct {
		MessageID      string `json:"message_id"`
		RegistrationID string `json:"registration_id,omitempty"`
		Error          string `json:"error,omitempty"`
	} `json:"results"`
}

func buildFCMPayload(tokens []models.DeviceToken, notification models.Notification) FCMMessage {
	msg := FCMMessage{
		Notification: FCMNotification{
			Title: notification.Title,
			Body:  notification.Body,
			Image: notification.Image,
		},
		Priority: "high",
	}

	var dataMap map[string]interface{}
	if notification.Data != nil {
		json.Unmarshal(notification.Data, &dataMap)
	}

	notifType := string(notification.Type)
	if id, ok := dataMap["booking_id"]; ok {
		msg.Data = FCMData{Type: notifType, ID: fmt.Sprintf("%v", id), DeepLink: "barbar://booking/" + fmt.Sprintf("%v", id)}
	} else if id, ok := dataMap["order_id"]; ok {
		msg.Data = FCMData{Type: notifType, ID: fmt.Sprintf("%v", id), DeepLink: "barbar://order/" + fmt.Sprintf("%v", id)}
	} else {
		msg.Data = FCMData{Type: notifType}
	}

	if len(tokens) == 1 {
		msg.To = tokens[0].Token
	} else {
		ids := make([]string, len(tokens))
		for i, t := range tokens {
			ids[i] = t.Token
		}
		msg.RegistrationIDs = ids
	}

	return msg
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
		Token    string `json:"token" binding:"required"`
		Platform string `json:"platform" binding:"required,oneof=ios android web"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	device := models.DeviceToken{
		UserID:   userID,
		Token:    req.Token,
		Platform: req.Platform,
		IsActive: true,
	}
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
