package models

import (
	"github.com/google/uuid"
	"time"
)

type OrderStatus string

const (
	OrderStatusPending         OrderStatus = "pending"
	OrderStatusAccepted        OrderStatus = "accepted"
	OrderStatusConfirmed       OrderStatus = "confirmed"
	OrderStatusProcessing      OrderStatus = "processing"
	OrderStatusPacked          OrderStatus = "packed"
	OrderStatusReadyForPickup  OrderStatus = "ready_for_pickup"
	OrderStatusDriverAssigned  OrderStatus = "driver_assigned"
	OrderStatusDriverAccepted  OrderStatus = "driver_accepted"
	OrderStatusAssigned        OrderStatus = "assigned"
	OrderStatusShipped         OrderStatus = "shipped"
	OrderStatusPickedUp        OrderStatus = "picked_up"
	OrderStatusOutForDelivery  OrderStatus = "out_for_delivery"
	OrderStatusDelivered       OrderStatus = "delivered"
	OrderStatusCancelled       OrderStatus = "cancelled"
	OrderStatusReturnRequested OrderStatus = "return_requested"
	OrderStatusReturned        OrderStatus = "returned"
	OrderStatusRefunded        OrderStatus = "refunded"
	OrderStatusPartiallyRefunded OrderStatus = "partially_refunded"
)

type PaymentStatus string

const (
	PaymentStatusPending   PaymentStatus = "pending"
	PaymentStatusSuccess   PaymentStatus = "success"
	PaymentStatusFailed    PaymentStatus = "failed"
	PaymentStatusRefunded  PaymentStatus = "refunded"
	PaymentStatusPartialRefund PaymentStatus = "partial_refund"
)

type Order struct {
	BaseModel
	CustomerID        uuid.UUID     `gorm:"type:uuid;index;not null" json:"customer_id"`
	VendorID          uuid.UUID     `gorm:"type:uuid;index" json:"vendor_id"`
	OrderNumber       string        `gorm:"size:50;uniqueIndex" json:"order_number"`
	Status            OrderStatus   `gorm:"size:50;default:pending;index" json:"status"`
	ItemsTotal        float64       `gorm:"default:0" json:"items_total"`
	ShippingCharge    float64       `gorm:"default:0" json:"shipping_charge"`
	TaxAmount         float64       `gorm:"default:0" json:"tax_amount"`
	DiscountAmount    float64       `gorm:"default:0" json:"discount_amount"`
	CouponCode        string        `gorm:"size:100" json:"coupon_code,omitempty"`
	CouponDiscount    float64       `gorm:"default:0" json:"coupon_discount"`
	WalletUsed        float64       `gorm:"default:0" json:"wallet_used"`
	FinalAmount       float64       `gorm:"default:0" json:"final_amount"`
	PaymentStatus     PaymentStatus `gorm:"size:50;default:pending" json:"payment_status"`
	PaymentMethod     string        `gorm:"size:100" json:"payment_method,omitempty"`
	PaymentID         string        `gorm:"size:255" json:"payment_id,omitempty"`
	ShippingAddressID *uuid.UUID    `gorm:"type:uuid" json:"shipping_address_id,omitempty"`
	BillingAddressID  *uuid.UUID    `gorm:"type:uuid" json:"billing_address_id,omitempty"`
	DeliveryNotes     string        `gorm:"type:text" json:"delivery_notes,omitempty"`
	CancellationReason string       `gorm:"type:text" json:"cancellation_reason,omitempty"`
	CancelledAt       *time.Time    `json:"cancelled_at,omitempty"`
	DeliveredAt       *time.Time    `json:"delivered_at,omitempty"`
	ReturnReason      string        `gorm:"type:text" json:"return_reason,omitempty"`
	ReturnRequestedAt *time.Time    `json:"return_requested_at,omitempty"`
	CommissionAmount  float64       `gorm:"default:0" json:"commission_amount"`
	PlatformFee       float64       `gorm:"default:0" json:"platform_fee"`
	VendorEarnings    float64       `gorm:"default:0" json:"vendor_earnings"`
	InvoiceURL        string        `gorm:"size:500" json:"invoice_url,omitempty"`
	TrackingNumber    string        `gorm:"size:255" json:"tracking_number,omitempty"`
	CourierPartner    string        `gorm:"size:255" json:"courier_partner,omitempty"`
	EstimatedDelivery *time.Time    `json:"estimated_delivery,omitempty"`
	DeliveryPartnerID *uuid.UUID    `gorm:"type:uuid;index" json:"delivery_partner_id,omitempty"`
	WarehouseID       *uuid.UUID    `gorm:"type:uuid" json:"warehouse_id,omitempty"`
	AssignedAt        *time.Time    `json:"assigned_at,omitempty"`
	PickedUpAt        *time.Time    `json:"picked_up_at,omitempty"`
	IsRated           bool          `gorm:"default:false" json:"is_rated"`

	// Relations
	DeliveryPartner  *User            `gorm:"foreignKey:DeliveryPartnerID" json:"delivery_partner,omitempty"`
	PickupWarehouse  *Warehouse       `gorm:"foreignKey:WarehouseID" json:"pickup_warehouse,omitempty"`
	Customer        *User            `gorm:"foreignKey:CustomerID" json:"customer,omitempty"`
	Vendor          *Vendor          `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
	Items           []OrderItem      `gorm:"foreignKey:OrderID" json:"items,omitempty"`
	StatusLog       []OrderStatusLog `gorm:"foreignKey:OrderID" json:"status_log,omitempty"`
	ShippingAddress *Address         `gorm:"foreignKey:ShippingAddressID" json:"shipping_address,omitempty"`
	Payment         *Payment         `gorm:"foreignKey:OrderID" json:"payment,omitempty"`
	Refund          *RefundRequest   `gorm:"foreignKey:OrderID" json:"refund,omitempty"`
}

type OrderItem struct {
	BaseModel
	OrderID        uuid.UUID `gorm:"type:uuid;index;not null" json:"order_id"`
	ProductID      uuid.UUID `gorm:"type:uuid;index" json:"product_id"`
	VariantID      *uuid.UUID `gorm:"type:uuid" json:"variant_id,omitempty"`
	ProductName    string    `gorm:"size:255" json:"product_name"`
	VariantName    string    `gorm:"size:255" json:"variant_name,omitempty"`
	SKU            string    `gorm:"size:255" json:"sku,omitempty"`
	ProductImage   string    `gorm:"size:500" json:"product_image,omitempty"`
	Quantity       int       `gorm:"not null" json:"quantity"`
	UnitPrice      float64   `gorm:"not null" json:"unit_price"`
	DiscountPrice  float64   `json:"discount_price,omitempty"`
	TotalPrice     float64   `gorm:"not null" json:"total_price"`
	TaxPercent     float64   `gorm:"default:0" json:"tax_percent"`
	TaxAmount      float64   `gorm:"default:0" json:"tax_amount"`
	IsActive       bool      `gorm:"default:true" json:"is_active"`
}

type OrderStatusLog struct {
	BaseModel
	OrderID    uuid.UUID   `gorm:"type:uuid;index;not null" json:"order_id"`
	FromStatus OrderStatus `gorm:"size:50" json:"from_status"`
	ToStatus   OrderStatus `gorm:"size:50" json:"to_status"`
	ChangedBy  uuid.UUID   `gorm:"type:uuid" json:"changed_by"`
	Role       string      `gorm:"size:50" json:"role"`
	Note       string      `gorm:"type:text" json:"note,omitempty"`
}

type AssignmentStatus string

const (
	AssignmentPending  AssignmentStatus = "pending"
	AssignmentAccepted AssignmentStatus = "accepted"
	AssignmentRejected AssignmentStatus = "rejected"
	AssignmentExpired  AssignmentStatus = "expired"
)

type OrderDeliveryAssignment struct {
	BaseModel
	OrderID        uuid.UUID        `gorm:"type:uuid;index;not null" json:"order_id"`
	DeliveryUserID uuid.UUID        `gorm:"type:uuid;index;not null" json:"delivery_user_id"`
	AssignedAt     time.Time        `json:"assigned_at"`
	AcceptedAt     *time.Time       `json:"accepted_at,omitempty"`
	RejectedAt     *time.Time       `json:"rejected_at,omitempty"`
	ExpiresAt      time.Time        `json:"expires_at"`
	Status         AssignmentStatus `gorm:"size:50;default:pending" json:"status"`
	TimeoutCount   int              `gorm:"default:0" json:"timeout_count"`
	Note           string           `gorm:"type:text" json:"note,omitempty"`
}

type ShippingAddress struct {
	BaseModel
	UserID      uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	FullName    string    `gorm:"size:255" json:"full_name"`
	Phone       string    `gorm:"size:20" json:"phone"`
	Pincode     string    `gorm:"size:10" json:"pincode"`
	Line1       string    `gorm:"size:500" json:"line_1"`
	Line2       string    `gorm:"size:500" json:"line_2,omitempty"`
	Landmark    string    `gorm:"size:255" json:"landmark,omitempty"`
	City        string    `gorm:"size:100" json:"city"`
	State       string    `gorm:"size:100" json:"state"`
	Country     string    `gorm:"size:100;default:India" json:"country"`
	IsDefault   bool      `gorm:"default:false" json:"is_default"`
}
