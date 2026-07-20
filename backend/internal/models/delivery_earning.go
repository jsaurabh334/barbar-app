package models

import (
	"github.com/google/uuid"
	"time"
)

type DeliveryEarning struct {
	BaseModel
	DeliveryPartnerID uuid.UUID  `gorm:"type:uuid;index;not null" json:"delivery_partner_id"`
	OrderID           uuid.UUID  `gorm:"type:uuid;uniqueIndex;not null" json:"order_id"`
	BaseAmount        float64    `gorm:"not null" json:"base_amount"`
	DistanceAmount    float64    `gorm:"default:0" json:"distance_amount"`
	BonusAmount       float64    `gorm:"default:0" json:"bonus_amount"`
	TipAmount         float64    `gorm:"default:0" json:"tip_amount"`
	TotalAmount       float64    `gorm:"not null" json:"total_amount"`
	Status            string     `gorm:"size:20;default:pending;index" json:"status"`
	SettledAt         *time.Time `json:"settled_at,omitempty"`
	Description       string     `gorm:"size:500" json:"description,omitempty"`
}

const (
	EarningStatusPending   = "pending"
	EarningStatusSettled   = "settled"
	EarningStatusCancelled = "cancelled"
)
