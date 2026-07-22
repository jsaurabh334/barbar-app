package models

import "time"

type BannerPosition string

const (
	BannerPositionHomeTop    BannerPosition = "home_top"
	BannerPositionHomeMiddle BannerPosition = "home_middle"
	BannerPositionPromotions BannerPosition = "promotions"
)

type Banner struct {
	BaseModel
	Title     string         `gorm:"size:255;not null" json:"title"`
	ImageURL  string         `gorm:"size:500;not null" json:"image_url"`
	LinkURL   string         `gorm:"size:500" json:"link_url,omitempty"`
	Position  BannerPosition `gorm:"size:50;not null;default:'home_top';index" json:"position"`
	IsActive  bool           `gorm:"default:true;index" json:"is_active"`
	SortOrder int            `gorm:"default:0" json:"sort_order"`
	StartDate *time.Time     `json:"start_date,omitempty"`
	EndDate   *time.Time     `json:"end_date,omitempty"`
}
