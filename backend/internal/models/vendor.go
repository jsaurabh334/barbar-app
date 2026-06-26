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
	KYCStatusPending  VendorKYCStatus = "pending"
	KYCStatusSubmitted VendorKYCStatus = "submitted"
	KYCStatusVerified  VendorKYCStatus = "verified"
	KYCStatusRejected  VendorKYCStatus = "rejected"
)

type Vendor struct {
	BaseModel
	UserID             uuid.UUID           `gorm:"type:uuid;uniqueIndex" json:"user_id"`
	StoreName          string              `gorm:"size:255;index" json:"store_name"`
	StoreSlug          string              `gorm:"size:255;uniqueIndex" json:"store_slug"`
	StoreDescription   string              `gorm:"type:text" json:"store_description,omitempty"`
	StoreLogo          string              `gorm:"size:500" json:"store_logo,omitempty"`
	StoreBanner        string              `gorm:"size:500" json:"store_banner,omitempty"`
	StoreEmail         string              `gorm:"size:255" json:"store_email,omitempty"`
	StorePhone         string              `gorm:"size:20" json:"store_phone,omitempty"`
	Address            string              `gorm:"type:text" json:"address"`
	City               string              `gorm:"size:100;index" json:"city"`
	State              string              `gorm:"size:100" json:"state"`
	Pincode            string              `gorm:"size:10" json:"pincode"`
	Latitude           float64             `json:"latitude,omitempty"`
	Longitude          float64             `json:"longitude,omitempty"`
	GSTNumber          string              `gorm:"size:50" json:"gst_number,omitempty"`
	PANNumber          string              `gorm:"size:50" json:"pan_number,omitempty"`
	FSSAINumber        string              `gorm:"size:50" json:"fssai_number,omitempty"`
	BusinessType       string              `gorm:"size:100" json:"business_type,omitempty"`
	Website            string              `gorm:"size:255" json:"website,omitempty"`
	Status             VendorStatus        `gorm:"size:50;default:pending;index" json:"status"`
	KYCStatus          VendorKYCStatus     `gorm:"size:50;default:pending" json:"kyc_status"`
	CommissionRate     float64             `gorm:"default:0" json:"commission_rate"`
	Rating             float64             `gorm:"default:0;index" json:"rating"`
	ReviewCount        int                 `gorm:"default:0" json:"review_count"`
	TotalProducts      int                 `gorm:"default:0" json:"total_products"`
	TotalOrders        int                 `gorm:"default:0" json:"total_orders"`
	TotalRevenue       float64             `gorm:"default:0" json:"total_revenue"`
	IsFeatured         bool                `gorm:"default:false;index" json:"is_featured"`
	IsVerified         bool                `gorm:"default:false" json:"is_verified"`
	IsActive           bool                `gorm:"default:true;index" json:"is_active"`
	ReturnPolicy       string              `gorm:"type:text" json:"return_policy,omitempty"`
	ShippingPolicy     string              `gorm:"type:text" json:"shipping_policy,omitempty"`
	DeliveryTimeframe  string              `gorm:"size:100" json:"delivery_timeframe,omitempty"`
	SocialLinks        JSONB               `gorm:"type:jsonb" json:"social_links,omitempty"`
	BusinessDocuments  JSONB               `gorm:"type:jsonb" json:"business_documents,omitempty"`

	// Relations
	User     *User     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Products []Product `gorm:"foreignKey:VendorID" json:"products,omitempty"`
	Wallet   *Wallet   `gorm:"foreignKey:VendorID" json:"wallet,omitempty"`
}

type VendorDocument struct {
	BaseModel
	VendorID   uuid.UUID `gorm:"type:uuid;index" json:"vendor_id"`
	DocType    string    `gorm:"size:100" json:"doc_type"`
	DocURL     string    `gorm:"size:500" json:"doc_url"`
	DocNumber  string    `gorm:"size:100" json:"doc_number,omitempty"`
	Status     string    `gorm:"size:50;default:pending" json:"status"`
	VerifiedBy *uuid.UUID `gorm:"type:uuid" json:"verified_by,omitempty"`
	VerifiedAt *time.Time `json:"verified_at,omitempty"`
	ExpiryDate *time.Time `json:"expiry_date,omitempty"`
	Remarks    string    `gorm:"type:text" json:"remarks,omitempty"`
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
	UserID      uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	DocType     string    `gorm:"size:100" json:"doc_type"`
	DocFrontURL string    `gorm:"size:500" json:"doc_front_url"`
	DocBackURL  string    `gorm:"size:500" json:"doc_back_url,omitempty"`
	DocNumber   string    `gorm:"size:100" json:"doc_number,omitempty"`
	Status      string    `gorm:"size:50;default:pending" json:"status"`
	VerifiedBy  *uuid.UUID `gorm:"type:uuid" json:"verified_by,omitempty"`
	VerifiedAt  *time.Time `json:"verified_at,omitempty"`
	RejectReason string   `gorm:"type:text" json:"reject_reason,omitempty"`
}
