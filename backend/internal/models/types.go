package models

import (
	"time"

	"gorm.io/datatypes"
)

// JSONB is an alias for gorm.io/datatypes.JSON
type JSONB = datatypes.JSON

type BookingFilters struct {
	BarberID   *string `form:"barber_id"`
	CustomerID *string `form:"customer_id"`
	Status     *string `form:"status"`
	DateFrom   *string `form:"date_from"`
	DateTo     *string `form:"date_to"`
	Page       int     `form:"page,default=1"`
	PageSize   int     `form:"page_size,default=20"`
	SortBy     string  `form:"sort_by,default=created_at"`
	SortOrder  string  `form:"sort_order,default=desc"`
}

type ProductFilters struct {
	CategoryID *string  `form:"category_id"`
	VendorID   *string  `form:"vendor_id"`
	MinPrice   *float64 `form:"min_price"`
	MaxPrice   *float64 `form:"max_price"`
	Search     *string  `form:"search"`
	City       *string  `form:"city"`
	IsFeatured *bool    `form:"is_featured"`
	SortBy     string   `form:"sort_by,default=created_at"`
	SortOrder  string   `form:"sort_order,default=desc"`
	Page       int      `form:"page,default=1"`
	PageSize   int      `form:"page_size,default=20"`
}

type OrderFilters struct {
	Status    *string `form:"status"`
	VendorID  *string `form:"vendor_id"`
	DateFrom  *string `form:"date_from"`
	DateTo    *string `form:"date_to"`
	Page      int     `form:"page,default=1"`
	PageSize  int     `form:"page_size,default=20"`
	SortBy    string  `form:"sort_by,default=created_at"`
	SortOrder string  `form:"sort_order,default=desc"`
}

type DateRange struct {
	From time.Time
	To   time.Time
}

type AnalyticsQuery struct {
	StartDate string `form:"start_date"`
	EndDate   string `form:"end_date"`
	GroupBy   string `form:"group_by,default=day"`
	VendorID  string `form:"vendor_id,omitempty"`
	City      string `form:"city,omitempty"`
}

type GeoLocation struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}
