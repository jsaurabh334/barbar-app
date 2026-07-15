package notification

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Roles
const (
	RoleCustomer = "customer"
	RoleBarber   = "barber"
	RoleAdmin    = "admin"
	RoleVendor   = "vendor"
	RoleDelivery = "delivery"
)

// DeepLink Actions
const (
	ActionOpenBooking = "OPEN_BOOKING"
	ActionOpenQueue   = "OPEN_QUEUE"
	ActionOpenOrder   = "OPEN_ORDER"
	ActionOpenProduct = "OPEN_PRODUCT"
	ActionOpenReview  = "OPEN_REVIEW"
	ActionOpenProfile = "OPEN_PROFILE"
)

// NotificationEvent represents the internal event payload
type NotificationEvent struct {
	Type       models.NotificationType
	SenderID   uuid.UUID
	ReceiverID uuid.UUID
	Role       string // Optional override if we want to target a specific role instance
	Data       map[string]any
}

// NotificationMatrix maps an event type to the roles that should receive it
var NotificationMatrix = map[models.NotificationType][]string{
	models.NotifBookingRequest:   {RoleCustomer, RoleBarber},
	models.NotifBookingConfirmed: {RoleCustomer},
	models.NotifBookingRejected:  {RoleCustomer},
	models.NotifBookingCancelled: {RoleCustomer, RoleBarber},
	models.NotifQueueUpdate:      {RoleCustomer},
	models.NotifBarberStarted:    {RoleCustomer},
	models.NotifBarberCompleted:  {RoleCustomer},
	models.NotifReviewReceived:   {RoleBarber},
	models.NotifReviewModerated:  {RoleCustomer},
	models.NotifReviewReply:      {RoleCustomer},
	models.NotifPaymentSuccess:   {RoleCustomer, RoleBarber},
	models.NotifPaymentFailed:    {RoleCustomer},
	models.NotifRefundCompleted:  {RoleCustomer},
	models.NotifOrderPlaced:      {RoleVendor},
	models.NotifOrderConfirmed:   {RoleCustomer},
	models.NotifOrderShipped:     {RoleCustomer},
	models.NotifOrderDelivered:   {RoleCustomer},
	models.NotifOrderCancelled:   {RoleCustomer, RoleVendor},
	models.NotifWithdrawalApproved:  {RoleBarber, RoleVendor},
	models.NotifWithdrawalProcessed: {RoleBarber, RoleVendor},
	models.NotifWithdrawalRejected:  {RoleBarber, RoleVendor},
	models.NotifAccountVerified:     {RoleCustomer, RoleBarber, RoleVendor, RoleDelivery},
	models.NotifSystemAlert:         {RoleCustomer, RoleBarber, RoleVendor, RoleDelivery},
	models.NotifVendorApproved:      {RoleVendor},
}

type Dispatcher interface {
	Dispatch(ctx context.Context, event NotificationEvent)
}

type notificationDispatcher struct {
	db       *gorm.DB
	hub      *websocket.Hub
	template TemplateService
}

func NewDispatcher(db *gorm.DB, hub *websocket.Hub, tmpl TemplateService) Dispatcher {
	return &notificationDispatcher{
		db:       db,
		hub:      hub,
		template: tmpl,
	}
}

func (d *notificationDispatcher) Dispatch(ctx context.Context, event NotificationEvent) {
	// Find target roles for this event
	targetRoles, exists := NotificationMatrix[event.Type]
	if !exists {
		// Fallback: If not in matrix, but we have a receiver and role, try sending directly
		if event.ReceiverID != uuid.Nil && event.Role != "" {
			targetRoles = []string{event.Role}
		} else {
			log.Printf("Dispatcher: No matrix entry for %s and no explicit receiver", event.Type)
			return
		}
	}

	for _, targetRole := range targetRoles {
		// If ReceiverID is specified, we check if they match the role
		if event.ReceiverID != uuid.Nil {
			var user models.User
			if err := d.db.Where("id = ? AND role = ?", event.ReceiverID, targetRole).First(&user).Error; err == nil {
				d.sendToUser(ctx, user.ID, targetRole, event)
			} else {
				// If we just have user ID but user role is different, or if we want to bypass exact role check
				if err := d.db.First(&user, event.ReceiverID).Error; err == nil {
					// We can still send it if we really need to, but matrix restricts it.
					// Let's strictly send if it's the intended receiver.
					d.sendToUser(ctx, user.ID, string(user.Role), event)
				}
			}
		} else {
			// Broadcast to ALL users of this role? Usually not what we want for bookings, but maybe for promos.
			// MVP: we expect ReceiverID to be populated for transactional events.
			log.Printf("Dispatcher: Broadcast to role %s not fully implemented yet for event %s", targetRole, event.Type)
		}
	}
}

func (d *notificationDispatcher) sendToUser(ctx context.Context, userID uuid.UUID, role string, event NotificationEvent) {
	_ = ctx
	var user models.User
	var lang string
	if err := d.db.Select("language_pref").First(&user, userID).Error; err == nil && user.LanguagePref != "" {
		lang = user.LanguagePref
	}

	// 1. Build Title, Body, Action based on Event
	title, body, action, priority := d.buildMessageFallback(event)

	if d.template != nil {
		tmpl, ok := d.template.GetTemplate(event.Type, lang)
		if ok {
			title = d.template.Compile(tmpl.Title, event.Data)
			body = d.template.Compile(tmpl.Body, event.Data)
			// Keep action and priority from fallback for now, or from tmpl if we add them to DB
		}
	}

	now := time.Now()
	notification := models.Notification{
		UserID:         userID,
		Role:           role,
		Title:          title,
		Body:           body,
		Type:           event.Type,
		Priority:       priority,
		DeliveryStatus: models.DeliveryStatusPending,
		Action:         action,
		SentAt:         &now,
	}

	if len(event.Data) > 0 {
		dataBytes, _ := json.Marshal(event.Data)
		notification.Data = dataBytes
		if entityID, ok := event.Data["entity_id"]; ok {
			notification.EntityID = fmt.Sprintf("%v", entityID)
		}
	}

	// 2. Save to DB
	if err := d.db.Create(&notification).Error; err != nil {
		log.Printf("Dispatcher: Failed to save notification to DB: %v", err)
		return
	}

	// 3. Emit via WebSocket
	if d.hub != nil {
		d.hub.SendToUser(userID, &websocket.WSMessage{
			Type:    websocket.MsgNotification,
			Payload: notification,
		})
	}

	// 4. Send FCM Push Notification via Worker
	var tokens []models.DeviceToken
	d.db.Where("user_id = ? AND is_active = ?", userID, true).Find(&tokens)
	
	DispatchPushNotification(d.db, tokens, notification)
}

func (d *notificationDispatcher) buildMessageFallback(event NotificationEvent) (title string, body string, action string, priority models.NotificationPriority) {
	priority = models.PriorityNormal
	
	switch event.Type {
	case models.NotifBookingRequest:
		title = "New Booking Request"
		body = "A new booking has been requested."
		action = ActionOpenBooking
		priority = models.PriorityHigh
	case models.NotifBookingConfirmed:
		title = "Booking Confirmed"
		body = "Your booking has been accepted!"
		action = ActionOpenBooking
		priority = models.PriorityHigh
	case models.NotifBookingRejected:
		title = "Booking Rejected"
		body = "Your booking could not be accepted."
		action = ActionOpenBooking
		priority = models.PriorityHigh
	case models.NotifBookingCancelled:
		title = "Booking Cancelled"
		body = "A booking was cancelled."
		action = ActionOpenBooking
		priority = models.PriorityHigh
	case models.NotifQueueUpdate:
		title = "Queue Update"
		body = "Your queue position has been updated."
		action = ActionOpenQueue
	case models.NotifBarberStarted:
		title = "Service Started"
		body = "Your service has started."
		action = ActionOpenBooking
	case models.NotifBarberCompleted:
		title = "Service Completed"
		body = "Your service has been completed."
		action = ActionOpenReview
	case models.NotifReviewReceived:
		title = "New Review"
		body = "You have received a new review."
		action = ActionOpenReview
	case models.NotifReviewModerated:
		title = "Review Update"
		body = "Your review moderation status has changed."
		action = ActionOpenReview
	case models.NotifReviewReply:
		title = "New Reply on Review"
		body = "The barber replied to your review."
		action = ActionOpenReview
	case models.NotifPaymentSuccess:
		title = "Payment Successful"
		body = "Payment was completed successfully."
		action = ActionOpenBooking
		priority = models.PriorityHigh
	case models.NotifPaymentFailed:
		title = "Payment Failed"
		body = "Your payment could not be processed."
		action = ActionOpenBooking
		priority = models.PriorityHigh
	case models.NotifRefundCompleted:
		title = "Refund Processed"
		body = "Your refund has been successfully processed."
		action = ActionOpenBooking
		priority = models.PriorityNormal
	case models.NotifOrderPlaced:
		title = "New Order Received"
		body = "You have received a new order."
		action = ActionOpenOrder
		priority = models.PriorityHigh
	case models.NotifOrderConfirmed:
		title = "Order Confirmed"
		body = "Your order has been confirmed."
		action = ActionOpenOrder
		priority = models.PriorityNormal
	case models.NotifOrderShipped:
		title = "Order Shipped"
		body = "Your order has been shipped."
		action = ActionOpenOrder
		priority = models.PriorityNormal
	case models.NotifOrderDelivered:
		title = "Order Delivered"
		body = "Your order has been delivered successfully."
		action = ActionOpenOrder
		priority = models.PriorityNormal
	case models.NotifOrderCancelled:
		title = "Order Cancelled"
		body = "The order has been cancelled."
		action = ActionOpenOrder
		priority = models.PriorityHigh
	case models.NotifWithdrawalApproved:
		title = "Withdrawal Approved"
		body = "Your withdrawal request has been approved."
		action = ActionOpenProfile
		priority = models.PriorityNormal
	case models.NotifWithdrawalProcessed:
		title = "Withdrawal Processed"
		body = "Your withdrawal has been successfully processed."
		action = ActionOpenProfile
		priority = models.PriorityHigh
	case models.NotifWithdrawalRejected:
		title = "Withdrawal Rejected"
		body = "Your withdrawal request was rejected."
		action = ActionOpenProfile
		priority = models.PriorityHigh
	case models.NotifAccountVerified:
		title = "Account Verified"
		body = "Your account has been verified successfully."
		action = ActionOpenProfile
		priority = models.PriorityNormal
	case models.NotifSystemAlert:
		title = "System Alert"
		body = "Important system update or alert."
		action = ActionOpenProfile
		priority = models.PriorityHigh
	case models.NotifVendorApproved:
		title = "Vendor Approved"
		body = "Your vendor application has been approved."
		action = ActionOpenProfile
		priority = models.PriorityNormal
	default:
		title = "Notification"
		body = "You have a new notification."
		action = "OPEN_APP"
	}
	return title, body, action, priority
}
