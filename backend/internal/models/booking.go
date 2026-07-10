package models

import (
	"github.com/google/uuid"
	"time"
)

type BookingStatus string

const (
	BookingStatusPending             BookingStatus = "pending"
	BookingStatusConfirmed           BookingStatus = "confirmed"
	BookingStatusInProgress          BookingStatus = "in_progress"
	BookingStatusCompleted           BookingStatus = "completed"
	BookingStatusCancelled           BookingStatus = "cancelled"
	BookingStatusNoShow              BookingStatus = "no_show"
	BookingStatusRescheduled         BookingStatus = "rescheduled"
	BookingStatusHomeServicePending  BookingStatus = "home_service_pending"
)

type ServiceMode string

const (
	ServiceModeShop ServiceMode = "SHOP"
	ServiceModeHome ServiceMode = "HOME"
)

func (b *Booking) ServiceModeDisplay() ServiceMode {
	if b.IsHomeService {
		return ServiceModeHome
	}
	return ServiceModeShop
}

type Booking struct {
	BaseModel
	BarberID          uuid.UUID     `gorm:"type:uuid;index;not null" json:"barber_id"`
	CustomerID        uuid.UUID     `gorm:"type:uuid;index;not null" json:"customer_id"`
	Status            BookingStatus `gorm:"size:50;default:pending;index" json:"status"`
	ScheduledStart    time.Time     `gorm:"index;not null" json:"scheduled_start"`
	ScheduledEnd      time.Time     `json:"scheduled_end"`
	ActualStart       *time.Time    `json:"actual_start,omitempty"`
	ActualEnd         *time.Time    `json:"actual_end,omitempty"`
	QueuePosition     int           `gorm:"default:0;index" json:"queue_position"`
	EstimatedWaitMin  int           `gorm:"default:0" json:"estimated_wait_minutes"`
	TotalDuration     int           `gorm:"default:0" json:"total_duration_minutes"`
	TotalPrice        float64       `gorm:"default:0" json:"total_price"`
	DiscountAmount    float64       `gorm:"default:0" json:"discount_amount"`
	FinalPrice        float64       `gorm:"default:0" json:"final_price"`
	PaymentStatus     string        `gorm:"size:50;default:pending" json:"payment_status"`
	PaymentID         string        `gorm:"size:255" json:"payment_id,omitempty"`
	CancellationReason string       `gorm:"type:text" json:"cancellation_reason,omitempty"`
	CancelledBy       *uuid.UUID    `gorm:"type:uuid" json:"cancelled_by,omitempty"`
	CancelledAt       *time.Time    `json:"cancelled_at,omitempty"`
	Notes             string        `gorm:"type:text" json:"notes,omitempty"`
	CustomerNotes     string        `gorm:"type:text" json:"customer_notes,omitempty"`
	BarberNotes       string        `gorm:"type:text" json:"barber_notes,omitempty"`
	IsWalkIn          bool          `gorm:"default:false" json:"is_walk_in"`
	Source            string        `gorm:"size:50;default:app" json:"source"`
	CheckInAt         *time.Time    `json:"check_in_at,omitempty"`
	CompletedAt       *time.Time    `json:"completed_at,omitempty"`
	IsHomeService     bool          `gorm:"default:false" json:"is_home_service"`
	HomeServiceAddressID *uuid.UUID `gorm:"type:uuid" json:"home_service_address_id,omitempty"`
	HomeServiceAddress string       `gorm:"type:text" json:"home_service_address,omitempty"`
	TravelDistanceKm  float64       `gorm:"default:0" json:"travel_distance_km"`
	TravelCharge      float64       `gorm:"default:0" json:"travel_charge"`

	// Relations
	Barber   *Barber          `gorm:"foreignKey:BarberID" json:"barber,omitempty"`
	Customer *User            `gorm:"foreignKey:CustomerID" json:"customer,omitempty"`
	Services []BookingService `gorm:"foreignKey:BookingID" json:"services,omitempty"`
	StatusLog []BookingStatusLog `gorm:"foreignKey:BookingID" json:"status_log,omitempty"`
}

type BookingService struct {
	BaseModel
	BookingID    uuid.UUID `gorm:"type:uuid;index" json:"booking_id"`
	ServiceID    uuid.UUID `gorm:"type:uuid" json:"service_id"`
	ServiceName  string    `gorm:"size:255" json:"name"`
	Quantity     int       `gorm:"default:1" json:"quantity"`
	UnitPrice    float64   `json:"price"`
	TotalPrice   float64   `json:"total_price"`
	DurationMin  int       `json:"duration_minutes"`
	AddedBy      string    `gorm:"size:50;default:customer" json:"added_by"`
	IsAddon      bool      `gorm:"default:false" json:"is_addon"`
}

type BookingStatusLog struct {
	BaseModel
	BookingID  uuid.UUID     `gorm:"type:uuid;index" json:"booking_id"`
	FromStatus BookingStatus `gorm:"size:50" json:"from_status"`
	ToStatus   BookingStatus `gorm:"size:50" json:"to_status"`
	ChangedBy  uuid.UUID     `gorm:"type:uuid" json:"changed_by"`
	ChangedByRole string     `gorm:"size:50" json:"changed_by_role"`
	Reason     string        `gorm:"type:text" json:"reason,omitempty"`
}
