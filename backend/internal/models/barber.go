package models

import (
	"github.com/google/uuid"
	"time"
)

type BarberStatus string

const (
	BarberStatusActive     BarberStatus = "active"
	BarberStatusInactive   BarberStatus = "inactive"
	BarberStatusBreak      BarberStatus = "on_break"
	BarberStatusClosed           BarberStatus = "closed"
	BarberStatusUnderMaintenance BarberStatus = "under_maintenance"
	BarberStatusSuspended        BarberStatus = "suspended"
)

type BarberVerificationStatus string

const (
	BarberVerifPending  BarberVerificationStatus = "pending"
	BarberVerifApproved BarberVerificationStatus = "approved"
	BarberVerifRejected BarberVerificationStatus = "rejected"
)

type Barber struct {
	BaseModel
	UserID             uuid.UUID                `gorm:"type:uuid;uniqueIndex" json:"user_id"`
	ShopName           string                   `gorm:"size:255;index" json:"shop_name"`
	ShopDescription    string                   `gorm:"type:text" json:"shop_description,omitempty"`
	ShopImage          string                   `gorm:"size:500" json:"shop_image,omitempty"`
	ShopImages         JSONB                    `gorm:"type:jsonb" json:"shop_images,omitempty"`
	Phone              string                   `gorm:"size:20" json:"phone,omitempty"`
	AlternatePhone     string                   `gorm:"size:20" json:"alternate_phone,omitempty"`
	Email              string                   `gorm:"size:255" json:"email,omitempty"`
	Address            string                   `gorm:"type:text" json:"address"`
	City               string                   `gorm:"size:100;index" json:"city"`
	State              string                   `gorm:"size:100" json:"state"`
	Pincode            string                   `gorm:"size:10" json:"pincode"`
	Latitude           float64                  `json:"latitude"`
	Longitude          float64                  `json:"longitude"`
	Status             BarberStatus             `gorm:"size:50;default:active;index" json:"status"`
	VerificationStatus BarberVerificationStatus `gorm:"size:50;default:pending" json:"verification_status"`
	Rating             float64                  `gorm:"default:0;index" json:"rating"`
	ReviewCount        int                      `gorm:"default:0" json:"review_count"`
	RatingDistribution JSONB                    `gorm:"type:jsonb;default:'{}'" json:"rating_distribution"`
	TotalBookings      int                      `gorm:"default:0" json:"total_bookings"`
	ExperienceYears    int                      `gorm:"default:0" json:"experience_years"`
	StartTime          string                   `gorm:"size:5" json:"start_time"`
	EndTime            string                   `gorm:"size:5" json:"end_time"`
	BreakStartTime     string                   `gorm:"size:5" json:"break_start_time,omitempty"`
	BreakEndTime       string                   `gorm:"size:5" json:"break_end_time,omitempty"`
	SlotDuration       int                      `gorm:"default:30" json:"slot_duration"`
	BufferBetweenSlots int                      `gorm:"default:5" json:"buffer_between_slots"`
	MaxQueueSize       int                      `gorm:"default:50" json:"max_queue_size"`
	IsVerified         bool                     `gorm:"default:false" json:"is_verified"`
	IsFeatured         bool                     `gorm:"default:false;index" json:"is_featured"`
	IsAvailable        bool                     `gorm:"default:true;index" json:"is_available"`
	CurrentQueueLength int                      `gorm:"default:0" json:"current_queue_length"`
	AverageWaitTime    float64                  `gorm:"default:0" json:"average_wait_time"`
	Tags               JSONB                    `gorm:"type:jsonb" json:"tags,omitempty"`
	BusinessDays       JSONB                    `gorm:"type:jsonb" json:"business_days,omitempty"`
	Amenities          JSONB                    `gorm:"type:jsonb" json:"amenities,omitempty"`
	Languages          JSONB                    `gorm:"type:jsonb" json:"languages,omitempty"`
	IsHomeServiceAvailable bool                 `gorm:"default:false" json:"is_home_service_available"`
	ServiceRadiusKm    float64                  `gorm:"default:0" json:"service_radius_km"`
	TravelChargePerKm  float64                  `gorm:"default:0" json:"travel_charge_per_km"`
	BaseTravelCharge   float64                  `gorm:"default:0" json:"base_travel_charge"`

	// Relations
	User     *User            `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Services []BarberService  `gorm:"foreignKey:BarberID" json:"services,omitempty"`
	Documents []BarberDocument `gorm:"foreignKey:BarberID" json:"documents,omitempty"`
	Bookings []Booking        `gorm:"foreignKey:BarberID" json:"bookings,omitempty"`
}

type BarberService struct {
	BaseModel
	BarberID       uuid.UUID `gorm:"type:uuid;index" json:"barber_id"`
	Name           string    `gorm:"size:255;index" json:"name"`
	Description    string    `gorm:"type:text" json:"description,omitempty"`
	CategoryID     *uuid.UUID `gorm:"type:uuid;index" json:"category_id,omitempty"`
	Category       *Category  `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	Price          float64   `gorm:"not null" json:"price"`
	DiscountPrice  float64   `json:"discount_price,omitempty"`
	DurationMin    int       `gorm:"not null" json:"duration_minutes"`
	IsActive       bool      `gorm:"default:true;index" json:"is_active"`
	Image          string    `gorm:"size:500" json:"image,omitempty"`
	SortOrder      int       `gorm:"default:0" json:"sort_order"`
	IsAddon        bool      `gorm:"default:false" json:"is_addon"`
	DefaultPrice   float64   `gorm:"default:0" json:"default_price"`
	DefaultDurationMin int       `gorm:"default:0" json:"default_duration_minutes"`
	DefaultBufferMin   int       `gorm:"default:0" json:"default_buffer_minutes"`
}

type BarberAvailability struct {
	BaseModel
	BarberID  uuid.UUID `gorm:"type:uuid;index" json:"barber_id"`
	DayOfWeek int       `gorm:"index" json:"day_of_week"`
	StartTime string    `gorm:"size:5" json:"start_time"`
	EndTime   string    `gorm:"size:5" json:"end_time"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
}

type BarberHoliday struct {
	BaseModel
	BarberID  uuid.UUID `gorm:"type:uuid;index" json:"barber_id"`
	Date      time.Time `gorm:"index" json:"date"`
	Reason    string    `gorm:"size:255" json:"reason"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
}

type BarberDocument struct {
	BaseModel
	BarberID   uuid.UUID `gorm:"type:uuid;index" json:"barber_id"`
	DocType    string    `gorm:"size:100" json:"doc_type"`
	DocURL     string    `gorm:"size:500" json:"doc_url"`
	Status     string    `gorm:"size:50;default:pending" json:"status"`
	VerifiedBy *uuid.UUID `gorm:"type:uuid" json:"verified_by,omitempty"`
	VerifiedAt *time.Time `json:"verified_at,omitempty"`
	Remarks    string    `gorm:"type:text" json:"remarks,omitempty"`
}

// IsProfileComplete checks whether the barber has filled all required fields
// This checks fields that don't require DB queries. Caller must verify services & staff separately.
func (b *Barber) IsProfileComplete() bool {
	if b.ShopName == "" || b.Address == "" || b.City == "" {
		return false
	}
	if b.Latitude == 0 || b.Longitude == 0 {
		return false
	}
	if b.StartTime == "" || b.EndTime == "" {
		return false
	}
	if b.ShopImage == "" {
		return false
	}
	return true
}
