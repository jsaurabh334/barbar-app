package models

import (
	"github.com/google/uuid"
	"time"
)

type CartItem struct {
	BaseModel
	UserID    uuid.UUID  `gorm:"type:uuid;index;not null" json:"user_id"`
	ProductID uuid.UUID  `gorm:"type:uuid;index;not null" json:"product_id"`
	VariantID *uuid.UUID `gorm:"type:uuid" json:"variant_id,omitempty"`
	Quantity  int        `gorm:"default:1" json:"quantity"`
	VendorID  uuid.UUID  `gorm:"type:uuid;index" json:"vendor_id"`

	// Relations
	Product *Product       `gorm:"foreignKey:ProductID" json:"product,omitempty"`
	Variant *ProductVariant `gorm:"foreignKey:VariantID" json:"variant,omitempty"`
	Vendor  *Vendor        `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
}

type WishlistItem struct {
	BaseModel
	UserID    uuid.UUID `gorm:"type:uuid;index;not null;uniqueIndex:idx_user_product" json:"user_id"`
	ProductID uuid.UUID `gorm:"type:uuid;index;not null;uniqueIndex:idx_user_product" json:"product_id"`

	// Relations
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type CouponType string

const (
	CouponTypePercentage CouponType = "percentage"
	CouponTypeFixed      CouponType = "fixed"
	CouponTypeFreeShipping CouponType = "free_shipping"
)

type Coupon struct {
	BaseModel
	Code            string      `gorm:"size:100;uniqueIndex" json:"code"`
	Description     string      `gorm:"type:text" json:"description,omitempty"`
	Type            CouponType  `gorm:"size:50;default:percentage" json:"type"`
	Value           float64     `json:"value"`
	MinOrderAmount  float64     `gorm:"default:0" json:"min_order_amount"`
	MaxDiscount     float64     `gorm:"default:0" json:"max_discount"`
	UsageLimit      int         `gorm:"default:0" json:"usage_limit"`
	UsedCount       int         `gorm:"default:0" json:"used_count"`
	PerUserLimit    int         `gorm:"default:1" json:"per_user_limit"`
	IsActive        bool        `gorm:"default:true;index" json:"is_active"`
	ValidFrom       time.Time   `json:"valid_from"`
	ValidTo         time.Time   `json:"valid_to"`
	ApplicableTo    string      `gorm:"size:50;default:all" json:"applicable_to"`
	VendorID        *uuid.UUID  `gorm:"type:uuid;index" json:"vendor_id,omitempty"`
	CategoryID      *uuid.UUID  `gorm:"type:uuid" json:"category_id,omitempty"`
	MinItems        int         `gorm:"default:0" json:"min_items"`
	CustomerSegment string      `gorm:"size:50" json:"customer_segment,omitempty"`
	Image           string      `gorm:"size:500" json:"image,omitempty"`
}

type CouponUsage struct {
	BaseModel
	CouponID  uuid.UUID `gorm:"type:uuid;index" json:"coupon_id"`
	UserID    uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	OrderID   uuid.UUID `gorm:"type:uuid" json:"order_id"`
	Discount  float64   `json:"discount"`
}

type Invoice struct {
	BaseModel
	OrderID       uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"order_id"`
	InvoiceNumber string    `gorm:"size:100;uniqueIndex" json:"invoice_number"`
	InvoiceURL    string    `gorm:"size:500" json:"invoice_url"`
	TotalAmount   float64   `json:"total_amount"`
	TaxAmount     float64   `json:"tax_amount"`
	GSTBreakup    JSONB     `gorm:"type:jsonb" json:"gst_breakup,omitempty"`
	GeneratedAt   time.Time `json:"generated_at"`
}
