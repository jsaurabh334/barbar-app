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
    LicenseNumber    string    `gorm:"size:100" json:"license_number"`
    CurrentLatitude  float64   `json:"current_latitude"`
    CurrentLongitude float64   `json:"current_longitude"`
    AvailabilityStatus string  `gorm:"size:20" json:"availability_status"` // available, busy, offline
    Rating           float64   `gorm:"type:decimal(3,2);default:0" json:"rating"`
    CreatedAt        time.Time `json:"created_at"`
    UpdatedAt        time.Time `json:"updated_at"`
    DeletedAt        *time.Time `gorm:"index" json:"deleted_at,omitempty"`
}

const (
    DeliveryPartnerStatusAvailable = "available"
    DeliveryPartnerStatusBusy      = "busy"
    DeliveryPartnerStatusOffline   = "offline"
)

// BeforeCreate hook to generate UUID for DeliveryPartner
func (dp *DeliveryPartner) BeforeCreate(tx *gorm.DB) (err error) {
    if dp.ID == uuid.Nil {
        dp.ID = uuid.New()
    }
    return nil
}
