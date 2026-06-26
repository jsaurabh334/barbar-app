package models

import (
	"time"

	"github.com/google/uuid"
)

type AuditLog struct {
	BaseModel
	UserID     uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	Action     string    `gorm:"size:100;index" json:"action"`
	EntityType string    `gorm:"size:100;index" json:"entity_type"`
	EntityID   string    `gorm:"size:255" json:"entity_id"`
	OldValues  JSONB     `gorm:"type:jsonb" json:"old_values,omitempty"`
	NewValues  JSONB     `gorm:"type:jsonb" json:"new_values,omitempty"`
	IPAddress  string    `gorm:"size:50" json:"ip_address"`
	UserAgent  string    `gorm:"size:500" json:"user_agent,omitempty"`
	Endpoint   string    `gorm:"size:255" json:"endpoint"`
	Method     string    `gorm:"size:10" json:"method"`
	Duration   int64     `json:"duration_ms"`
	Status     int       `json:"status"`
}

type DisputeStatus string

const (
	DisputeOpen      DisputeStatus = "open"
	DisputeInReview  DisputeStatus = "in_review"
	DisputeResolved  DisputeStatus = "resolved"
	DisputeClosed    DisputeStatus = "closed"
	DisputeEscalated DisputeStatus = "escalated"
)

type Dispute struct {
	BaseModel
	RaisedBy   uuid.UUID     `gorm:"type:uuid;index" json:"raised_by"`
	OrderID    *uuid.UUID    `gorm:"type:uuid;index" json:"order_id,omitempty"`
	BookingID  *uuid.UUID    `gorm:"type:uuid;index" json:"booking_id,omitempty"`
	Subject    string        `gorm:"size:255;not null" json:"subject"`
	Description string       `gorm:"type:text;not null" json:"description"`
	Category   string        `gorm:"size:100" json:"category"`
	Priority   string        `gorm:"size:20;default:medium" json:"priority"`
	Status     DisputeStatus `gorm:"size:50;default:open;index" json:"status"`
	AssignedTo *uuid.UUID    `gorm:"type:uuid" json:"assigned_to,omitempty"`
	ResolvedAt *time.Time    `json:"resolved_at,omitempty"`
	Resolution string        `gorm:"type:text" json:"resolution,omitempty"`
	Images     JSONB         `gorm:"type:jsonb" json:"images,omitempty"`
}

type DisputeMessage struct {
	BaseModel
	DisputeID  uuid.UUID `gorm:"type:uuid;index" json:"dispute_id"`
	SenderID   uuid.UUID `gorm:"type:uuid" json:"sender_id"`
	Message    string    `gorm:"type:text;not null" json:"message"`
	Attachments JSONB    `gorm:"type:jsonb" json:"attachments,omitempty"`
	IsStaffOnly bool     `gorm:"default:false" json:"is_staff_only"`
}

type PlatformSetting struct {
	BaseModel
	Key         string `gorm:"size:255;uniqueIndex" json:"key"`
	Value       string `gorm:"type:text" json:"value"`
	Description string `gorm:"type:text" json:"description,omitempty"`
	DataType    string `gorm:"size:50;default:string" json:"data_type"`
	Group       string `gorm:"size:100;default:general" json:"group"`
	IsPublic    bool   `gorm:"default:false" json:"is_public"`
}

type TaxSetting struct {
	BaseModel
	Name           string  `gorm:"size:255" json:"name"`
	Rate           float64 `json:"rate"`
	Type           string  `gorm:"size:50;default:GST" json:"type"`
	Description    string  `gorm:"type:text" json:"description,omitempty"`
	IsActive       bool    `gorm:"default:true" json:"is_active"`
	ApplicableTo   string  `gorm:"size:50;default:all" json:"applicable_to"`
	HSNCode        string  `gorm:"size:20" json:"hsn_code,omitempty"`
	SACCode        string  `gorm:"size:20" json:"sac_code,omitempty"`
	CGSTRate       float64 `json:"cgst_rate,omitempty"`
	SGSTRate       float64 `json:"sgst_rate,omitempty"`
	IGSTRate       float64 `json:"igst_rate,omitempty"`
	CessRate       float64 `json:"cess_rate,omitempty"`
	SortOrder      int     `gorm:"default:0" json:"sort_order"`
}

type WebhookStatus string

const (
	WebhookActive   WebhookStatus = "active"
	WebhookInactive WebhookStatus = "inactive"
	WebhookFailed   WebhookStatus = "failed"
)

type WebhookEventStatus string

const (
	WebhookEventPending  WebhookEventStatus = "pending"
	WebhookEventSent     WebhookEventStatus = "sent"
	WebhookEventFailed   WebhookEventStatus = "failed"
	WebhookEventRetrying WebhookEventStatus = "retrying"
)

type WebhookEndpoint struct {
	BaseModel
	VendorID    *uuid.UUID    `gorm:"type:uuid;index" json:"vendor_id,omitempty"`
	BarberID    *uuid.UUID    `gorm:"type:uuid;index" json:"barber_id,omitempty"`
	URL         string         `gorm:"size:500;not null" json:"url"`
	Events      JSONB          `gorm:"type:jsonb;default:'[]'" json:"events"`
	Secret      string         `gorm:"size:255" json:"-"`
	Status      WebhookStatus  `gorm:"size:50;default:active" json:"status"`
	Description string         `gorm:"type:text" json:"description,omitempty"`
	RetryCount  int            `gorm:"default:3" json:"retry_count"`
	TimeoutSec  int            `gorm:"default:10" json:"timeout_sec"`
}

type WebhookEvent struct {
	BaseModel
	EndpointID uuid.UUID         `gorm:"type:uuid;index" json:"endpoint_id"`
	Event      string            `gorm:"size:100;index" json:"event"`
	Payload    JSONB             `gorm:"type:jsonb" json:"payload"`
	Status     WebhookEventStatus `gorm:"size:50;default:pending;index" json:"status"`
	Response   string            `gorm:"type:text" json:"response,omitempty"`
	StatusCode int               `json:"status_code,omitempty"`
	Attempts   int               `gorm:"default:0" json:"attempts"`
	MaxRetries int               `gorm:"default:3" json:"max_retries"`
	NextRetry  *time.Time        `json:"next_retry,omitempty"`
}

type FeaturedListing struct {
	BaseModel
	ProductID  *uuid.UUID `gorm:"type:uuid;index" json:"product_id,omitempty"`
	BarberID   *uuid.UUID `gorm:"type:uuid;index" json:"barber_id,omitempty"`
	VendorID   *uuid.UUID `gorm:"type:uuid;index" json:"vendor_id,omitempty"`
	StartDate  time.Time  `json:"start_date"`
	EndDate    time.Time  `json:"end_date"`
	Fee        float64    `json:"fee"`
	Status     string     `gorm:"size:50;default:active" json:"status"`
	PaymentID  *uuid.UUID `gorm:"type:uuid" json:"payment_id,omitempty"`
	Priority   int        `gorm:"default:0" json:"priority"`
}
