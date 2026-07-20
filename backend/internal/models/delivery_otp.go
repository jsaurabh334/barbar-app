package models

import (
	"time"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DeliveryOTP struct {
	BaseModel
	OrderID     uuid.UUID  `gorm:"type:uuid;uniqueIndex;not null" json:"order_id"`
	OTP         string     `gorm:"size:10;not null" json:"-"`
	ExpiresAt   time.Time  `json:"expires_at"`
	VerifiedAt  *time.Time `json:"verified_at,omitempty"`
	Attempts    int        `gorm:"default:0" json:"-"`
	MaxAttempts int        `gorm:"default:5" json:"-"`
}

func (d *DeliveryOTP) BeforeCreate(tx *gorm.DB) (err error) {
	if d.ID == uuid.Nil {
		d.ID = uuid.New()
	}
	if d.MaxAttempts == 0 {
		d.MaxAttempts = 5
	}
	return nil
}

func (d *DeliveryOTP) IsExpired() bool {
	return time.Now().After(d.ExpiresAt)
}

func (d *DeliveryOTP) IsVerified() bool {
	return d.VerifiedAt != nil
}

func (d *DeliveryOTP) CanRetry() bool {
	return d.Attempts < d.MaxAttempts
}
