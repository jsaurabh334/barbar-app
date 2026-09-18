package models

import (
	"time"

	"github.com/google/uuid"
)

// BarberEarning records the amount due to a barber once a home service booking
// is completed with customer approval (End OTP). Earnings start as "pending"
// (money held) and are released to the barber's wallet when settled.
type BarberEarning struct {
	BaseModel
	BookingID        uuid.UUID  `gorm:"type:uuid;uniqueIndex;not null" json:"booking_id"`
	BarberID         uuid.UUID  `gorm:"type:uuid;index;not null" json:"barber_id"`
	Amount           float64    `gorm:"not null" json:"amount"`
	CommissionAmount float64    `gorm:"default:0" json:"commission_amount"`
	Status           string     `gorm:"size:20;default:pending;index" json:"status"`
	SettledAt        *time.Time `json:"settled_at,omitempty"`
	Description      string     `gorm:"size:500" json:"description,omitempty"`
}
