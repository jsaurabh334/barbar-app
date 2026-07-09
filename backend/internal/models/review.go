package models

import (
	"github.com/google/uuid"
	"time"
)

type ReviewStatus string

const (
	ReviewStatusPending  ReviewStatus = "pending"
	ReviewStatusApproved ReviewStatus = "approved"
	ReviewStatusRejected ReviewStatus = "rejected"
	ReviewStatusHidden   ReviewStatus = "hidden"
	ReviewStatusDeleted  ReviewStatus = "deleted"
)

type Review struct {
	BaseModel
	BookingID    uuid.UUID  `gorm:"type:uuid;uniqueIndex;not null" json:"booking_id"`
	CustomerID   uuid.UUID  `gorm:"type:uuid;index;not null" json:"customer_id"`
	ShopID       uuid.UUID  `gorm:"type:uuid;index;not null" json:"shop_id"`
	StaffID      *uuid.UUID `gorm:"type:uuid;index" json:"staff_id,omitempty"`
	Rating       int        `gorm:"not null;check:rating>=1 AND rating<=5" json:"rating"`
	Comment      string     `gorm:"type:text" json:"comment"`
	IsAnonymous  bool       `gorm:"default:false" json:"is_anonymous"`
	IsVerified   bool       `gorm:"default:true" json:"is_verified"`
	Status       ReviewStatus `gorm:"size:20;default:pending;index" json:"status"`

	Booking  *Booking        `gorm:"foreignKey:BookingID" json:"booking,omitempty"`
	Customer *User           `gorm:"foreignKey:CustomerID" json:"customer,omitempty"`
	Shop     *Barber         `gorm:"foreignKey:ShopID" json:"shop,omitempty"`
	Images   []ReviewImage   `gorm:"foreignKey:ReviewID" json:"images,omitempty"`
	Reply    *ReviewReply    `gorm:"foreignKey:ReviewID" json:"reply,omitempty"`
}

type ReviewImage struct {
	BaseModel
	ReviewID   uuid.UUID `gorm:"type:uuid;index;not null" json:"review_id"`
	URL        string    `gorm:"size:500;not null" json:"url"`
	Thumbnail  string    `gorm:"size:500" json:"thumbnail,omitempty"`
	SortOrder  int       `gorm:"default:0" json:"sort_order"`
	Size       int       `gorm:"default:0" json:"size"`
}

type ReviewReport struct {
	BaseModel
	ReviewID   uuid.UUID `gorm:"type:uuid;index;not null" json:"review_id"`
	ReporterID uuid.UUID `gorm:"type:uuid;index;not null" json:"reporter_id"`
	Reason     string    `gorm:"type:text;not null" json:"reason"`
	Status     string    `gorm:"size:20;default:pending;index" json:"status"`

	Review   *Review `gorm:"foreignKey:ReviewID" json:"review,omitempty"`
	Reporter *User   `gorm:"foreignKey:ReporterID" json:"reporter,omitempty"`
}

func (ReviewReport) TableName() string {
	return "review_reports"
}

type ReviewReply struct {
	BaseModel
	ReviewID uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"review_id"`
	ShopID   uuid.UUID `gorm:"type:uuid;index;not null" json:"shop_id"`
	Message  string    `gorm:"type:text;not null" json:"message"`

	Review *Review `gorm:"foreignKey:ReviewID" json:"review,omitempty"`
	Shop   *Barber `gorm:"foreignKey:ShopID" json:"shop,omitempty"`
}

// RatingDistribution represents precomputed rating breakdown
type RatingDistribution struct {
	Star5 int `json:"5"`
	Star4 int `json:"4"`
	Star3 int `json:"3"`
	Star2 int `json:"2"`
	Star1 int `json:"1"`
}

func (Review) TableName() string {
	return "reviews"
}

func (ReviewImage) TableName() string {
	return "review_images"
}

func (ReviewReply) TableName() string {
	return "review_replies"
}

// Review create validation window
const ReviewWindowDays = 30

// Available sort options for public review listing
const (
	ReviewSortNewest  = "newest"
	ReviewSortHighest = "highest"
	ReviewSortLowest  = "lowest"
)

var ValidReviewSorts = []string{ReviewSortNewest, ReviewSortHighest, ReviewSortLowest}

// Max values
const (
	MaxReviewImages     = 5
	MinReviewCommentLen = 10
	MaxReviewCommentLen = 1000
)

// IsReviewWindowValid checks if the booking is still within the review window
func IsReviewWindowValid(completedAt time.Time) bool {
	if completedAt.IsZero() {
		return false
	}
	return time.Since(completedAt).Hours() < float64(ReviewWindowDays*24)
}
