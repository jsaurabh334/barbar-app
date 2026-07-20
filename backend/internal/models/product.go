package models

import (
	"github.com/google/uuid"
	"time"
)

type CategoryType string

const (
	CategoryTypeBarber    CategoryType = "barber_service"
	CategoryTypeProduct   CategoryType = "product"
)

type Category struct {
	BaseModel
	Name          string       `gorm:"size:255;index" json:"name"`
	Slug          string       `gorm:"size:255;uniqueIndex" json:"slug"`
	Description   string       `gorm:"type:text" json:"description,omitempty"`
	Image         string       `gorm:"size:500" json:"image,omitempty"`
	Icon          string       `gorm:"size:100" json:"icon,omitempty"`
	ParentID      *uuid.UUID   `gorm:"type:uuid;index" json:"parent_id,omitempty"`
	CategoryType  CategoryType `gorm:"size:50;default:product;index" json:"category_type"`
	SortOrder     int          `gorm:"default:0" json:"sort_order"`
	IsActive      bool         `gorm:"default:true;index" json:"is_active"`
	IsFeatured    bool         `gorm:"default:false" json:"is_featured"`
	MetaTitle     string       `gorm:"size:255" json:"meta_title,omitempty"`
	MetaDesc      string       `gorm:"type:text" json:"meta_description,omitempty"`

	// Relations
	Parent   *Category     `gorm:"foreignKey:ParentID" json:"parent,omitempty"`
	Products []Product     `gorm:"foreignKey:CategoryID" json:"products,omitempty"`
}

type SubCategory struct {
	BaseModel
	CategoryID   uuid.UUID `gorm:"type:uuid;index" json:"category_id"`
	Name         string    `gorm:"size:255" json:"name"`
	Slug         string    `gorm:"size:255;index" json:"slug"`
	Description  string    `gorm:"type:text" json:"description,omitempty"`
	Image        string    `gorm:"size:500" json:"image,omitempty"`
	SortOrder    int       `gorm:"default:0" json:"sort_order"`
	IsActive     bool      `gorm:"default:true" json:"is_active"`
}

type ProductCondition string

const (
	ProductNew     ProductCondition = "new"
	ProductUsed    ProductCondition = "used"
	ProductRefurb  ProductCondition = "refurbished"
)

type Product struct {
	BaseModel
	VendorID          uuid.UUID        `gorm:"type:uuid;index;not null" json:"vendor_id"`
	BrandID           *uuid.UUID       `gorm:"type:uuid;index" json:"brand_id,omitempty"`
	CategoryID        uuid.UUID        `gorm:"type:uuid;index" json:"category_id"`
	SubCategoryID     *uuid.UUID       `gorm:"type:uuid;index" json:"sub_category_id,omitempty"`
	Name              string           `gorm:"size:255;index" json:"name"`
	Slug              string           `gorm:"size:255;index" json:"slug"`
	Description       string           `gorm:"type:text" json:"description,omitempty"`
	ShortDescription  string           `gorm:"type:text" json:"short_description,omitempty"`
	BrandName         string           `gorm:"size:255" json:"brand_name,omitempty"`
	Condition         ProductCondition `gorm:"size:50;default:new" json:"condition"`
	BasePrice         float64          `gorm:"not null" json:"base_price"`
	DiscountPrice     float64          `json:"discount_price,omitempty"`
	DiscountPercent   float64          `json:"discount_percent,omitempty"`
	TaxPercent        float64          `gorm:"default:0" json:"tax_percent"`
	Unit              string           `gorm:"size:50;default:piece" json:"unit"`
	MinOrderQty       int              `gorm:"default:1" json:"min_order_qty"`
	MaxOrderQty       int              `gorm:"default:100" json:"max_order_qty"`
	TotalStock        int              `gorm:"default:0" json:"total_stock"`
	ReservedStock     int              `gorm:"default:0" json:"reserved_stock"`
	AvailableStock    int              `gorm:"default:0" json:"available_stock"`
	LowStockThreshold int              `gorm:"default:10" json:"low_stock_threshold"`
	SoldCount         int              `gorm:"default:0;index" json:"sold_count"`
	Rating            float64          `gorm:"default:0;index" json:"rating"`
	ReviewCount       int              `gorm:"default:0" json:"review_count"`
	IsActive          bool             `gorm:"default:true;index" json:"is_active"`
	IsFeatured        bool             `gorm:"default:false;index" json:"is_featured"`
	IsApproved        bool             `gorm:"default:false;index" json:"is_approved"`
	HasVariants       bool             `gorm:"default:false" json:"has_variants"`
	Weight            float64          `json:"weight,omitempty"`
	Length            float64          `json:"length,omitempty"`
	Width             float64          `json:"width,omitempty"`
	Height            float64          `json:"height,omitempty"`
	Tags              JSONB            `gorm:"type:jsonb" json:"tags,omitempty"`
	Attributes        JSONB            `gorm:"type:jsonb" json:"attributes,omitempty"`
	SearchKeywords    string           `gorm:"type:tsvector" json:"-"`

	// Relations
	Vendor     *Vendor          `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
	Brand      *Brand           `gorm:"foreignKey:BrandID" json:"brand,omitempty"`
	Category   *Category        `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	Variants   []ProductVariant `gorm:"foreignKey:ProductID" json:"variants,omitempty"`
	Images     []ProductImage   `gorm:"foreignKey:ProductID" json:"images,omitempty"`
	Reviews    []ProductReview  `gorm:"foreignKey:ProductID" json:"reviews,omitempty"`
	Purchases  []Purchase       `gorm:"foreignKey:ProductID" json:"purchases,omitempty"`
}

type ProductVariant struct {
	BaseModel
	ProductID    uuid.UUID `gorm:"type:uuid;index;not null" json:"product_id"`
	SKU          string    `gorm:"size:255;uniqueIndex" json:"sku"`
	Barcode      string    `gorm:"size:100;index" json:"barcode,omitempty"`
	Name         string    `gorm:"size:255" json:"name"`
	Value        string    `gorm:"size:255" json:"value"`
	Price        float64   `gorm:"not null" json:"price"`
	DiscountPrice float64  `json:"discount_price,omitempty"`
	Stock        int       `gorm:"default:0" json:"stock"`
	ReservedStock int      `gorm:"default:0" json:"reserved_stock"`
	Weight       float64   `json:"weight,omitempty"`
	Image        string    `gorm:"size:500" json:"image,omitempty"`
	IsActive     bool      `gorm:"default:true;index" json:"is_active"`
	SortOrder    int       `gorm:"default:0" json:"sort_order"`
}

type ProductImage struct {
	BaseModel
	ProductID    uuid.UUID `gorm:"type:uuid;index;not null" json:"product_id"`
	ImageURL     string    `gorm:"size:500;not null" json:"image_url"`
	ThumbnailURL string    `gorm:"size:500" json:"thumbnail_url,omitempty"`
	AltText      string    `gorm:"size:255" json:"alt_text,omitempty"`
	IsPrimary    bool      `gorm:"default:false" json:"is_primary"`
	SortOrder    int       `gorm:"default:0" json:"sort_order"`
	FileSize     int64     `gorm:"default:0" json:"file_size,omitempty"`
	MimeType     string    `gorm:"size:100" json:"mime_type,omitempty"`
}

type ProductReview struct {
	BaseModel
	ProductID  uuid.UUID `gorm:"type:uuid;index;not null" json:"product_id"`
	UserID     uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	OrderID    *uuid.UUID `gorm:"type:uuid" json:"order_id,omitempty"`
	Rating     int       `gorm:"not null" json:"rating"`
	Title      string    `gorm:"size:255" json:"title,omitempty"`
	Review     string    `gorm:"type:text" json:"review,omitempty"`
	Images     JSONB     `gorm:"type:jsonb" json:"images,omitempty"`
	IsVerified bool      `gorm:"default:false" json:"is_verified"`
	IsActive   bool      `gorm:"default:true" json:"is_active"`
	HelpfulCount int     `gorm:"default:0" json:"helpful_count"`

	// Relations
	User    *User    `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

type Brand struct {
	BaseModel
	VendorID    uuid.UUID `gorm:"type:uuid;index;not null" json:"vendor_id"`
	Name        string    `gorm:"size:255;index;not null" json:"name"`
	Slug        string    `gorm:"size:255;index" json:"slug"`
	Description string    `gorm:"type:text" json:"description,omitempty"`
	Logo        string    `gorm:"size:500" json:"logo,omitempty"`
	IsActive    bool      `gorm:"default:true;index" json:"is_active"`
	SortOrder   int       `gorm:"default:0" json:"sort_order"`

	// Relations
	Vendor   *Vendor   `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
	Products []Product `gorm:"foreignKey:BrandID" json:"products,omitempty"`
}

type ProductAttribute struct {
	BaseModel
	VendorID    uuid.UUID `gorm:"type:uuid;index;not null" json:"vendor_id"`
	Name        string    `gorm:"size:255;not null" json:"name"`
	Values      JSONB     `gorm:"type:jsonb" json:"values"`
	IsActive    bool      `gorm:"default:true" json:"is_active"`
	SortOrder   int       `gorm:"default:0" json:"sort_order"`
}

type Purchase struct {
	BaseModel
	VendorID       uuid.UUID  `gorm:"type:uuid;index;not null" json:"vendor_id"`
	ProductID      uuid.UUID  `gorm:"type:uuid;index;not null" json:"product_id"`
	VariantID      *uuid.UUID `gorm:"type:uuid;index" json:"variant_id,omitempty"`
	Quantity       int        `gorm:"not null" json:"quantity"`
	UnitPrice      float64    `gorm:"not null" json:"unit_price"`
	TotalPrice     float64    `gorm:"not null" json:"total_price"`
	SupplierName   string     `gorm:"size:255" json:"supplier_name,omitempty"`
	InvoiceNumber  string     `gorm:"size:255" json:"invoice_number,omitempty"`
	Notes          string     `gorm:"type:text" json:"notes,omitempty"`
	PurchasedAt    time.Time  `json:"purchased_at"`

	// Relations
	Vendor  *Vendor  `gorm:"foreignKey:VendorID" json:"vendor,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}
