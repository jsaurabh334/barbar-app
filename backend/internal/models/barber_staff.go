package models

import (
	"github.com/google/uuid"
)

type StaffRole string

const (
	RoleManager StaffRole = "manager"
	RoleStaff   StaffRole = "staff"
)

type BarberStaff struct {
	BaseModel
	BarberID uuid.UUID  `gorm:"type:uuid;index;not null" json:"barber_id"`
	UserID   *uuid.UUID `gorm:"type:uuid;index" json:"user_id,omitempty"`
	Name     string     `gorm:"size:255;not null" json:"name"`
	Image    string     `gorm:"size:500" json:"image,omitempty"`
	Phone    string     `gorm:"size:20" json:"phone,omitempty"`
	Role     StaffRole  `gorm:"size:50;default:staff" json:"role"`
	IsActive bool       `gorm:"default:true;index" json:"is_active"`
	Rating          float64 `gorm:"default:0" json:"rating"`
	ReviewCount     int     `gorm:"default:0" json:"review_count"`
	RatingDistribution JSONB `gorm:"type:jsonb;default:'{}'" json:"rating_distribution,omitempty"`

	// Profile details
	Bio             string `gorm:"size:1000" json:"bio,omitempty"`
	ExperienceYears int    `gorm:"default:0" json:"experience_years"`
	Languages       JSONB  `gorm:"type:jsonb;default:'[]'" json:"languages,omitempty"`
	Specializations string `gorm:"size:500" json:"specializations,omitempty"`
	Instagram       string `gorm:"size:255" json:"instagram,omitempty"`

	// Schedule
	WorkingDays string  `gorm:"size:255;default:'1,2,3,4,5,6'" json:"working_days"` // comma separated days, 0=Sun
	StartTime   string  `gorm:"size:5;default:'09:00'" json:"start_time"`
	EndTime     string  `gorm:"size:5;default:'21:00'" json:"end_time"`
	DayOff      int     `gorm:"default:0" json:"day_off"` // 0=Sun, 1=Mon, etc.

	// Relations
	Barber *Barber `gorm:"foreignKey:BarberID" json:"barber,omitempty"`
	User   *User   `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Services []StaffService `gorm:"foreignKey:StaffID" json:"services,omitempty"`
	Bookings []Booking      `gorm:"foreignKey:StaffID" json:"bookings,omitempty"`
}

type StaffService struct {
	BaseModel
	StaffID   uuid.UUID `gorm:"type:uuid;index;not null" json:"staff_id"`
	ServiceID uuid.UUID `gorm:"type:uuid;index;not null" json:"service_id"`
	
	// Overrides
	Price       float64 `gorm:"default:0" json:"price"`
	DurationMin int     `gorm:"default:0" json:"duration_minutes"`
	BufferMin   int     `gorm:"default:0" json:"buffer_minutes"`
	IsActive    bool    `gorm:"default:true;index" json:"is_active"`

	// Relations
	Staff   *BarberStaff   `gorm:"foreignKey:StaffID" json:"staff,omitempty"`
	Service *BarberService `gorm:"foreignKey:ServiceID" json:"service,omitempty"`
}
