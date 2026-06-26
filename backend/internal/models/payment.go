package models

import (
	"github.com/google/uuid"
	"time"
)

type PaymentGateway string

const (
	GatewayRazorpay PaymentGateway = "razorpay"
	GatewayStripe   PaymentGateway = "stripe"
	GatewayCash     PaymentGateway = "cash"
	GatewayWallet   PaymentGateway = "wallet"
)

type PaymentStatusInternal string

const (
	PayStatusInitiated PaymentStatusInternal = "initiated"
	PayStatusPending   PaymentStatusInternal = "pending"
	PayStatusSuccess   PaymentStatusInternal = "success"
	PayStatusFailed    PaymentStatusInternal = "failed"
	PayStatusRefunded  PaymentStatusInternal = "refunded"
)

type Payment struct {
	BaseModel
	OrderID           uuid.UUID           `gorm:"type:uuid;index" json:"order_id"`
	UserID            uuid.UUID           `gorm:"type:uuid;index" json:"user_id"`
	Amount            float64             `json:"amount"`
	Gateway           PaymentGateway      `gorm:"size:50" json:"gateway"`
	GatewayOrderID    string              `gorm:"size:255" json:"gateway_order_id,omitempty"`
	GatewayPaymentID  string              `gorm:"size:255;index" json:"gateway_payment_id,omitempty"`
	GatewaySignature  string              `gorm:"size:500" json:"gateway_signature,omitempty"`
	Currency          string              `gorm:"size:10;default:INR" json:"currency"`
	Status            PaymentStatusInternal `gorm:"size:50;default:initiated;index" json:"status"`
	PaymentMethod     string              `gorm:"size:100" json:"payment_method,omitempty"`
	BankReference     string              `gorm:"size:255" json:"bank_reference,omitempty"`
	FailureReason     string              `gorm:"type:text" json:"failure_reason,omitempty"`
	RefundAmount      float64             `gorm:"default:0" json:"refund_amount"`
	RefundStatus      string              `gorm:"size:50" json:"refund_status,omitempty"`
	RefundedAt        *time.Time          `json:"refunded_at,omitempty"`
	PaidAt            *time.Time          `json:"paid_at,omitempty"`
	Metadata          JSONB               `gorm:"type:jsonb" json:"metadata,omitempty"`
}

type PaymentGatewayLog struct {
	BaseModel
	PaymentID     uuid.UUID `gorm:"type:uuid;index" json:"payment_id"`
	Gateway       string    `gorm:"size:50" json:"gateway"`
	EventType     string    `gorm:"size:255" json:"event_type"`
	Request       JSONB     `gorm:"type:jsonb" json:"request,omitempty"`
	Response      JSONB     `gorm:"type:jsonb" json:"response,omitempty"`
	Status        string    `gorm:"size:50" json:"status"`
	IPAddress     string    `gorm:"size:50" json:"ip_address,omitempty"`
}
