package models

import (
	"time"

	"github.com/google/uuid"
)

type NotificationType string

const (
	NotifBookingRequest        NotificationType = "booking_request"
	NotifBookingConfirmed      NotificationType = "booking_confirmed"
	NotifBookingRejected       NotificationType = "booking_rejected"
	NotifBookingReminder       NotificationType = "booking_reminder"
	NotifBookingModified       NotificationType = "booking_modified"
	NotifBookingCancelled      NotificationType = "booking_cancelled"
	NotifQueueUpdate           NotificationType = "queue_update"
	NotifWaitTimeChanged       NotificationType = "wait_time_changed"
	NotifBarberStarted         NotificationType = "barber_started"
	NotifBarberCompleted       NotificationType = "barber_completed"
	NotifOrderPlaced           NotificationType = "order_placed"
	NotifOrderConfirmed        NotificationType = "order_confirmed"
	NotifOrderShipped          NotificationType = "order_shipped"
	NotifOrderDelivered        NotificationType = "order_delivered"
	NotifOrderCancelled        NotificationType = "order_cancelled"
	NotifPaymentSuccess        NotificationType = "payment_success"
	NotifPaymentFailed         NotificationType = "payment_failed"
	NotifRefundInitiated       NotificationType = "refund_initiated"
	NotifRefundCompleted       NotificationType = "refund_completed"
	NotifWithdrawalApproved    NotificationType = "withdrawal_approved"
	NotifWithdrawalProcessed   NotificationType = "withdrawal_processed"
	NotifWithdrawalRejected    NotificationType = "withdrawal_rejected"
	NotifPromotion             NotificationType = "promotion"
	NotifNewOffer              NotificationType = "new_offer"
	NotifWalletCredit          NotificationType = "wallet_credit"
	NotifWalletDebit           NotificationType = "wallet_debit"
	NotifAccountVerified       NotificationType = "account_verified"
	NotifNewMessage            NotificationType = "new_message"
	NotifSystemAlert           NotificationType = "system_alert"
	NotifDisputeUpdate         NotificationType = "dispute_update"
	NotifVendorApproved        NotificationType = "vendor_approved"
	NotifReviewReceived        NotificationType = "review_received"
	NotifReviewModerated       NotificationType = "review_moderated"
	NotifReviewReply           NotificationType = "review_reply"
)

type DeliveryStatus string

const (
	DeliveryStatusPending   DeliveryStatus = "pending"
	DeliveryStatusSent      DeliveryStatus = "sent"
	DeliveryStatusDelivered DeliveryStatus = "delivered"
	DeliveryStatusFailed    DeliveryStatus = "failed"
	DeliveryStatusRead      DeliveryStatus = "read"
)

type NotificationPriority string

const (
	PriorityHigh   NotificationPriority = "high"
	PriorityNormal NotificationPriority = "normal"
	PriorityLow    NotificationPriority = "low"
)

type NotificationCategory string

const (
	CategoryBooking     NotificationCategory = "booking"
	CategoryPayment     NotificationCategory = "payment"
	CategoryWallet      NotificationCategory = "wallet"
	CategoryMarketplace NotificationCategory = "marketplace"
	CategoryReview      NotificationCategory = "review"
	CategoryAdmin       NotificationCategory = "admin"
	CategoryPromotion   NotificationCategory = "promotion"
)

type Notification struct {
	BaseModel
	UserID         uuid.UUID            `gorm:"type:uuid;index;not null" json:"user_id"`
	Role           string               `gorm:"size:50" json:"role"` // customer, barber, etc
	Title          string               `gorm:"size:255;not null" json:"title"`
	Body           string               `gorm:"type:text" json:"body,omitempty"`
	Type           NotificationType     `gorm:"size:100;index" json:"type"`
	Category       NotificationCategory `gorm:"size:100;index" json:"category"`
	Priority       NotificationPriority `gorm:"size:50;default:'normal'" json:"priority"`
	DeliveryStatus DeliveryStatus       `gorm:"size:50;default:'pending'" json:"delivery_status"`
	Data           JSONB                `gorm:"type:jsonb" json:"data,omitempty"`
	Image          string               `gorm:"size:500" json:"image,omitempty"`
	Link           string               `gorm:"size:500" json:"link,omitempty"`
	Action         string               `gorm:"size:100" json:"action,omitempty"`
	EntityID       string               `gorm:"size:100" json:"entity_id,omitempty"`
	IsRead         bool                 `gorm:"default:false;index" json:"is_read"`
	ReadAt         *time.Time           `json:"read_at,omitempty"`
	SentAt         *time.Time           `json:"sent_at,omitempty"`
	ExpiresAt      *time.Time           `json:"expires_at,omitempty"`
}

type NotificationLog struct {
	BaseModel
	NotificationID uuid.UUID `gorm:"type:uuid;index" json:"notification_id"`
	DeviceToken    string    `gorm:"size:500;index" json:"device_token"`
	Status         string    `gorm:"size:50" json:"status"`
	Error          string    `gorm:"type:text" json:"error,omitempty"`
	SentAt         time.Time `json:"sent_at"`
	Response       JSONB     `gorm:"type:jsonb" json:"response,omitempty"`
}

type NotificationTemplate struct {
	BaseModel
	Name      string           `gorm:"size:255;uniqueIndex:idx_name_lang" json:"name"`
	Language  string           `gorm:"size:10;default:en;uniqueIndex:idx_name_lang" json:"language"`
	Title     string           `gorm:"size:255" json:"title"`
	Body      string           `gorm:"type:text" json:"body"`
	Type      NotificationType `gorm:"size:100" json:"type"`
	Variables JSONB            `gorm:"type:jsonb" json:"variables"`
	IsActive  bool             `gorm:"default:true" json:"is_active"`
	Channel   string           `gorm:"size:50;default:all" json:"channel"`
}

type DeviceToken struct {
	BaseModel
	UserID     uuid.UUID  `gorm:"type:uuid;index" json:"user_id"`
	Role       string     `gorm:"size:50;index" json:"role"`
	Token      string     `gorm:"size:500;index" json:"token"`
	Platform   string     `gorm:"size:50" json:"platform"`
	DeviceName string     `gorm:"size:255" json:"device_name"`
	AppVersion string     `gorm:"size:50" json:"app_version"`
	IsActive   bool       `gorm:"default:true" json:"is_active"`
	LastSeen   *time.Time `json:"last_seen,omitempty"`
}

type NotificationPreference struct {
	BaseModel
	UserID         uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	Role           string    `gorm:"size:50;index" json:"role"`
	BookingUpdates bool      `gorm:"default:true" json:"booking_updates"`
	QueueUpdates   bool      `gorm:"default:true" json:"queue_updates"`
	Offers         bool      `gorm:"default:true" json:"offers"`
	Promotions     bool      `gorm:"default:true" json:"promotions"`
	Wallet         bool      `gorm:"default:true" json:"wallet"`
	Orders         bool      `gorm:"default:true" json:"orders"`
}
