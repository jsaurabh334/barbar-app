package models

import (
	"github.com/google/uuid"
	"time"
)

type VendorStatus string

const (
	VendorStatusPending   VendorStatus = "pending"
	VendorStatusApproved  VendorStatus = "approved"
	VendorStatusRejected  VendorStatus = "rejected"
	VendorStatusSuspended VendorStatus = "suspended"
)

type VendorKYCStatus string

const (
	KYCStatusPending   VendorKYCStatus = "pending"
	KYCStatusSubmitted VendorKYCStatus = "submitted"
	KYCStatusVerified  VendorKYCStatus = "verified"
	KYCStatusRejected  VendorKYCStatus = "rejected"
)

type Vendor struct {
	BaseModel
	UserID              uuid.UUID           `gorm:"type:uuid;uniqueIndex" json:"user_id"`
	BusinessName        string              `gorm:"size:255;index" json:"business_name"`
	BusinessSlug        string              `gorm:"size:255;uniqueIndex" json:"business_slug"`
	BusinessDescription string              `gorm:"type:text" json:"business_description,omitempty"`
	Logo                string              `gorm:"size:500" json:"logo,omitempty"`
	Banner              string              `gorm:"size:500" json:"banner,omitempty"`
	BusinessEmail       string              `gorm:"size:255" json:"business_email,omitempty"`
	BusinessPhone       string              `gorm:"size:20" json:"business_phone,omitempty"`
	Address             string              `gorm:"type:text" json:"address"`
	City                string              `gorm:"size:100;index" json:"city"`
	State               string              `gorm:"size:100" json:"state"`
	Pincode             string              `gorm:"size:10" json:"pincode"`
	Latitude            float64             `json:"latitude,omitempty"`
	Longitude           float64             `json:"longitude,omitempty"`
	GSTNumber           string              `gorm:"size:50" json:"gst_number,omitempty"`
	PANNumber           string              `gorm:"size:50" json:"pan_number,omitempty"`
	BusinessType        string              `gorm:"size:100" json:"business_type,omitempty"`
	Website             string              `gorm:"size:255" json:"website,omitempty"`
	Status              VendorStatus        `gorm:"size:50;default:pending;index" json:"status"`
	KYCStatus           VendorKYCStatus     `gorm:"size:50;default:pending" json:"kyc_status"`
	CommissionRate      float64             `gorm:"default:0" json:"commission_rate"`
	Rating              float64             `gorm:"default:0;index" json:"rating"`
	ReviewCount         int                 `gorm:"default:0" json:"review_count"`
	TotalProducts       int                 `gorm:"default:0" json:"total_products"`
	TotalOrders         int                 `gorm:"default:0" json:"total_orders"`
	TotalRevenue        float64             `gorm:"default:0" json:"total_revenue"`
	IsFeatured          bool                `gorm:"default:false;index" json:"is_featured"`
	IsVerified          bool                `gorm:"default:false" json:"is_verified"`
	IsActive            bool                `gorm:"default:true;index" json:"is_active"`
	ReturnPolicy        string              `gorm:"type:text" json:"return_policy,omitempty"`
	ShippingPolicy      string              `gorm:"type:text" json:"shipping_policy,omitempty"`
	DeliveryTimeframe   string              `gorm:"size:100" json:"delivery_timeframe,omitempty"`

	// Relations
	User          *User       `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Products      []Product   `gorm:"foreignKey:VendorID" json:"products,omitempty"`
	Wallet        *Wallet     `gorm:"foreignKey:VendorID" json:"wallet,omitempty"`
	Warehouses    []Warehouse `gorm:"foreignKey:VendorID" json:"warehouses,omitempty"`
}

type VendorDocument struct {
	BaseModel
	VendorID   uuid.UUID  `gorm:"type:uuid;index" json:"vendor_id"`
	DocType    string     `gorm:"size:100" json:"doc_type"`
	DocURL     string     `gorm:"size:500" json:"doc_url"`
	DocNumber  string     `gorm:"size:100" json:"doc_number,omitempty"`
	Status     string     `gorm:"size:50;default:pending" json:"status"`
	VerifiedBy *uuid.UUID `gorm:"type:uuid" json:"verified_by,omitempty"`
	VerifiedAt *time.Time `json:"verified_at,omitempty"`
	ExpiryDate *time.Time `json:"expiry_date,omitempty"`
	Remarks    string     `gorm:"type:text" json:"remarks,omitempty"`
}

type VendorBankAccount struct {
	BaseModel
	VendorID          uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"vendor_id"`
	AccountHolderName string    `gorm:"size:255" json:"account_holder_name"`
	AccountNumber     string    `gorm:"size:100" json:"account_number"`
	IFSCCode          string    `gorm:"size:20" json:"ifsc_code"`
	BankName          string    `gorm:"size:255" json:"bank_name"`
	BranchName        string    `gorm:"size:255" json:"branch_name"`
	UPIID             string    `gorm:"size:100" json:"upi_id,omitempty"`
	IsPrimary         bool      `gorm:"default:true" json:"is_primary"`
	IsVerified        bool      `gorm:"default:false" json:"is_verified"`
}

type KYCDocument struct {
	BaseModel
	UserID       uuid.UUID  `gorm:"type:uuid;index" json:"user_id"`
	DocType      string     `gorm:"size:100" json:"doc_type"`
	DocFrontURL  string     `gorm:"size:500" json:"doc_front_url"`
	DocBackURL   string     `gorm:"size:500" json:"doc_back_url,omitempty"`
	DocNumber    string     `gorm:"size:100" json:"doc_number,omitempty"`
	Status       string     `gorm:"size:50;default:pending" json:"status"`
	VerifiedBy   *uuid.UUID `gorm:"type:uuid" json:"verified_by,omitempty"`
	VerifiedAt   *time.Time `json:"verified_at,omitempty"`
	RejectReason string    `gorm:"type:text" json:"reject_reason,omitempty"`
}

type WarehouseType string

const (
	WarehouseTypePickup WarehouseType = "pickup"
	WarehouseTypeReturn WarehouseType = "return"
	WarehouseTypeBoth   WarehouseType = "both"
)

type WarehouseStatus string

const (
	WarehouseStatusActive   WarehouseStatus = "active"
	WarehouseStatusInactive WarehouseStatus = "inactive"
)

type Warehouse struct {
	BaseModel
	VendorID     uuid.UUID       `gorm:"type:uuid;index;not null" json:"vendor_id"`
	Name         string          `gorm:"size:255;not null" json:"name"`
	Phone        string          `gorm:"size:20" json:"phone,omitempty"`
	Email        string          `gorm:"size:255" json:"email,omitempty"`
	Address      string          `gorm:"type:text;not null" json:"address"`
	City         string          `gorm:"size:100;index;not null" json:"city"`
	State        string          `gorm:"size:100" json:"state"`
	Pincode      string          `gorm:"size:10" json:"pincode"`
	Latitude     float64         `json:"latitude,omitempty"`
	Longitude    float64         `json:"longitude,omitempty"`
	WarehouseType WarehouseType  `gorm:"size:50;default:both" json:"warehouse_type"`
	Status       WarehouseStatus `gorm:"size:50;default:active" json:"status"`
	IsDefault    bool            `gorm:"default:false" json:"is_default"`
	IsActive     bool            `gorm:"default:true;index" json:"is_active"`
	DisplayOrder int             `gorm:"default:0" json:"display_order"`

	// Relations
	Vendor *Vendor `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
}
