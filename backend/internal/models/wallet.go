package models

import (
	"github.com/google/uuid"
	"time"
)

type Wallet struct {
	BaseModel
	UserID   *uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"user_id,omitempty"`
	VendorID *uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"vendor_id,omitempty"`
	Balance  float64    `gorm:"default:0" json:"balance"`
	LockedBalance float64 `gorm:"default:0" json:"locked_balance"`
	TotalCredited  float64 `gorm:"default:0" json:"total_credited"`
	TotalDebited   float64 `gorm:"default:0" json:"total_debited"`
	IsActive       bool    `gorm:"default:true" json:"is_active"`
}

type TxnType string

const (
	TxnTypeCredit   TxnType = "credit"
	TxnTypeDebit    TxnType = "debit"
)

type TxnReferenceType string

const (
	TxnRefOrder       TxnReferenceType = "order"
	TxnRefWithdrawal  TxnReferenceType = "withdrawal"
	TxnRefRefund      TxnReferenceType = "refund"
	TxnRefCommission  TxnReferenceType = "commission"
	TxnRefAdjustment  TxnReferenceType = "adjustment"
	TxnRefPayout      TxnReferenceType = "payout"
	TxnRefBonus       TxnReferenceType = "bonus"
	TxnRefDeliveryEarning TxnReferenceType = "delivery_earning"
	TxnRefCancellation TxnReferenceType = "cancellation"
)

type WalletTransaction struct {
	BaseModel
	WalletID      uuid.UUID         `gorm:"type:uuid;index;not null" json:"wallet_id"`
	TxnType       TxnType           `gorm:"size:20;not null" json:"txn_type"`
	Amount        float64           `gorm:"not null" json:"amount"`
	RunningBalance float64          `gorm:"default:0" json:"running_balance"`
	ReferenceType TxnReferenceType  `gorm:"size:50;index" json:"reference_type"`
	ReferenceID   string            `gorm:"size:255" json:"reference_id"`
	Description   string            `gorm:"type:text" json:"description,omitempty"`
	Status        string            `gorm:"size:50;default:completed;index" json:"status"`
	GatewayResponse string          `gorm:"type:text" json:"gateway_response,omitempty"`
	TxnDate       time.Time         `gorm:"index" json:"txn_date"`
}

type WithdrawalRequestStatus string

const (
	WithdrawPending   WithdrawalRequestStatus = "pending"
	WithdrawApproved  WithdrawalRequestStatus = "approved"
	WithdrawRejected  WithdrawalRequestStatus = "rejected"
	WithdrawProcessed WithdrawalRequestStatus = "processed"
)

type WithdrawalRequest struct {
	BaseModel
	VendorID         uuid.UUID                `gorm:"type:uuid;index;not null" json:"vendor_id"`
	DeliveryPartnerID *uuid.UUID               `gorm:"type:uuid;index" json:"delivery_partner_id,omitempty"`
	Amount           float64                  `json:"amount"`
	FeeAmount        float64                  `gorm:"default:0" json:"fee_amount"`
	NetAmount        float64                  `json:"net_amount"`
	BankAccountID    *uuid.UUID               `gorm:"type:uuid" json:"bank_account_id,omitempty"`
	BankAccountDetails JSONB                  `gorm:"type:jsonb" json:"bank_account_details,omitempty"`
	Status           WithdrawalRequestStatus  `gorm:"size:50;default:pending;index" json:"status"`
	AdminID          *uuid.UUID               `gorm:"type:uuid" json:"admin_id,omitempty"`
	AdminNotes       string                   `gorm:"type:text" json:"admin_notes,omitempty"`
	ProcessedAt      *time.Time               `json:"processed_at,omitempty"`
	TransactionRef   string                   `gorm:"size:255" json:"transaction_ref,omitempty"`
	UTRNumber        string                   `gorm:"size:100;column:utr_nnumber" json:"utr_number,omitempty"`
	RejectReason     string                   `gorm:"type:text" json:"reject_reason,omitempty"`
}

type VendorPayout struct {
	BaseModel
	VendorID        uuid.UUID `gorm:"type:uuid;index" json:"vendor_id"`
	WithdrawalID    uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"withdrawal_id"`
	Amount          float64   `json:"amount"`
	FeeAmount       float64   `json:"fee_amount"`
	NetAmount       float64   `json:"net_amount"`
	BankAccount     string    `gorm:"size:255" json:"bank_account"`
	IFSCCode        string    `gorm:"size:20" json:"ifsc_code"`
	UTRNumber       string    `gorm:"size:100" json:"utr_number"`
	Status          string    `gorm:"size:50;default:initiated" json:"status"`
	InitiatedBy     uuid.UUID `gorm:"type:uuid" json:"initiated_by"`
	ProcessedAt     *time.Time `json:"processed_at,omitempty"`
	CompletedAt     *time.Time `json:"completed_at,omitempty"`
	FailureReason   string    `gorm:"type:text" json:"failure_reason,omitempty"`
	GatewayResponse JSONB     `gorm:"type:jsonb" json:"gateway_response,omitempty"`
}

type CommissionTransaction struct {
	BaseModel
	OrderID      uuid.UUID `gorm:"type:uuid;index" json:"order_id"`
	VendorID     uuid.UUID `gorm:"type:uuid;index" json:"vendor_id"`
	OrderAmount  float64   `json:"order_amount"`
	CommissionRate float64 `json:"commission_rate"`
	CommissionAmount float64 `json:"commission_amount"`
	PlatformFee  float64   `json:"platform_fee"`
	TaxAmount    float64   `json:"tax_amount"`
	NetAmount    float64   `json:"net_amount"`
	Status       string    `gorm:"size:50;default:pending;index" json:"status"`
	SettledAt    *time.Time `json:"settled_at,omitempty"`
}

type RefundRequest struct {
	BaseModel
	OrderID      uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"order_id"`
	CustomerID   uuid.UUID `gorm:"type:uuid;index;not null" json:"customer_id"`
	VendorID     uuid.UUID `gorm:"type:uuid;index" json:"vendor_id"`
	Items        JSONB     `gorm:"type:jsonb" json:"items,omitempty"`
	Reason       string    `gorm:"type:text;not null" json:"reason"`
	RefundType   string    `gorm:"size:50;default:full" json:"refund_type"`
	RefundAmount float64   `json:"refund_amount"`
	Status       string    `gorm:"size:50;default:pending;index" json:"status"`
	AdminID      *uuid.UUID `gorm:"type:uuid" json:"admin_id,omitempty"`
	AdminNotes   string    `gorm:"type:text" json:"admin_notes,omitempty"`
	RejectReason string    `gorm:"type:text" json:"reject_reason,omitempty"`
	ProcessedAt  *time.Time `json:"processed_at,omitempty"`
	PaymentRefundID string `gorm:"size:255" json:"payment_refund_id,omitempty"`
	Images       JSONB     `gorm:"type:jsonb" json:"images,omitempty"`
}
