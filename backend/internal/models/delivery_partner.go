package models

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

type DeliveryPartner struct {
    ID               uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
    UserID           uuid.UUID `gorm:"type:uuid;uniqueIndex" json:"user_id"`
	VehicleType      string    `gorm:"size:50" json:"vehicle_type"`
	VehicleNumber    string    `gorm:"size:50" json:"vehicle_number"`
	LicenseNumber    string    `gorm:"size:100" json:"license_number"`
    CurrentLatitude  float64   `json:"current_latitude"`
    CurrentLongitude float64   `json:"current_longitude"`
    AvailabilityStatus string  `gorm:"size:20" json:"availability_status"` // available, busy, offline
    Rating           float64   `gorm:"type:decimal(3,2);default:0" json:"rating"`
    Status           string     `gorm:"size:20;default:pending" json:"status"`
    RejectionReason  string     `gorm:"size:500" json:"rejection_reason,omitempty"`
    ApprovedAt       *time.Time `json:"approved_at,omitempty"`
    SuspendedAt      *time.Time `json:"suspended_at,omitempty"`
    CreatedAt        time.Time `json:"created_at"`
    UpdatedAt        time.Time `json:"updated_at"`
    DeletedAt        *time.Time `gorm:"index" json:"deleted_at,omitempty"`
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

// BeforeCreate hook to generate UUID for DeliveryPartner
func (dp *DeliveryPartner) BeforeCreate(tx *gorm.DB) (err error) {
    if dp.ID == uuid.Nil {
        dp.ID = uuid.New()
    }
    return nil
}
