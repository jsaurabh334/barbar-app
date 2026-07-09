package models

import (
	"github.com/google/uuid"
	"time"
)

type NotificationType string

const (
	NotifBookingConfirmed      NotificationType = "booking_confirmed"
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
)

type Notification struct {
	BaseModel
	UserID  uuid.UUID        `gorm:"type:uuid;index;not null" json:"user_id"`
	Title   string           `gorm:"size:255;not null" json:"title"`
	Body    string           `gorm:"type:text" json:"body,omitempty"`
	Type    NotificationType `gorm:"size:100;index" json:"type"`
	Data    JSONB            `gorm:"type:jsonb" json:"data,omitempty"`
	Image   string           `gorm:"size:500" json:"image,omitempty"`
	Link    string           `gorm:"size:500" json:"link,omitempty"`
	IsRead  bool             `gorm:"default:false;index" json:"is_read"`
	ReadAt  *time.Time       `json:"read_at,omitempty"`
	SentAt  time.Time        `json:"sent_at"`
}

type NotificationTemplate struct {
	BaseModel
	Name      string           `gorm:"size:255;uniqueIndex" json:"name"`
	Title     string           `gorm:"size:255" json:"title"`
	Body      string           `gorm:"type:text" json:"body"`
	Type      NotificationType `gorm:"size:100" json:"type"`
	Variables JSONB            `gorm:"type:jsonb" json:"variables"`
	IsActive  bool             `gorm:"default:true" json:"is_active"`
	Channel   string           `gorm:"size:50;default:all" json:"channel"`
}

type DeviceToken struct {
	BaseModel
	UserID  uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	Token   string    `gorm:"size:500;index" json:"token"`
	Platform string   `gorm:"size:50" json:"platform"`
	IsActive bool     `gorm:"default:true" json:"is_active"`
}
