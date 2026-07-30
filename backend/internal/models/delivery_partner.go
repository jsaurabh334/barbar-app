package models

import (
	"time"

	"github.com/google/uuid"
)

type DeliveryPartner struct {
	BaseModel
	UserID                uuid.UUID  `gorm:"type:uuid;uniqueIndex" json:"user_id"`
	User                  *User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	VehicleType           string     `gorm:"size:50" json:"vehicle_type"`
	VehicleNumber         string     `gorm:"size:50" json:"vehicle_number"`
	LicenseNumber         string     `gorm:"size:100" json:"license_number"`
	CurrentLatitude       float64    `gorm:"index:idx_delivery_partner_geo,priority:2" json:"current_latitude"`
	CurrentLongitude      float64   `gorm:"index:idx_delivery_partner_geo,priority:3" json:"current_longitude"`
	AvailabilityStatus    string     `gorm:"size:20;index:idx_delivery_partner_geo,priority:1" json:"availability_status"`
	Rating                float64    `gorm:"type:decimal(3,2);default:0" json:"rating"`
	Status                string     `gorm:"size:20;default:pending" json:"status"`
	RejectionReason       string     `gorm:"size:500" json:"rejection_reason,omitempty"`
	ApprovedAt            *time.Time `json:"approved_at,omitempty"`
	SuspendedAt           *time.Time `json:"suspended_at,omitempty"`
	MaxConcurrentDeliveries int      `gorm:"default:1" json:"max_concurrent_deliveries"`
	DailyDeliveryLimit    int        `gorm:"default:20" json:"daily_delivery_limit"`
	TodayDeliveryCount    int        `gorm:"default:0" json:"today_delivery_count"`
	LastDeliveryDate      *time.Time `json:"last_delivery_date,omitempty"`
	WeeklyWorkingHours    float64    `gorm:"default:48" json:"weekly_working_hours"`
	TotalDeliveries       int        `gorm:"default:0" json:"total_deliveries"`
	TotalEarnings         float64    `gorm:"default:0" json:"total_earnings"`
	LastHeartbeatAt       *time.Time `json:"last_heartbeat_at,omitempty"`
}

const (
	DeliveryPartnerStatusAvailable = "available"
	DeliveryPartnerStatusBusy      = "busy"
	DeliveryPartnerStatusOffline   = "offline"
)

const (
	DeliveryPartnerStatusPending    = "pending"
	DeliveryPartnerStatusApproved   = "approved"
	DeliveryPartnerStatusRejected   = "rejected"
	DeliveryPartnerStatusSuspended  = "suspended"
)
