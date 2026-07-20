package models

import "github.com/google/uuid"

type DriverStatus string

const (
	DriverOffline DriverStatus = "offline"
	DriverOnline  DriverStatus = "online"
	DriverBusy    DriverStatus = "busy"
)

type DeliveryPresenceLog struct {
	BaseModel
	DeliveryUserID uuid.UUID   `gorm:"type:uuid;index;not null" json:"delivery_user_id"`
	Status         DriverStatus `gorm:"size:50" json:"status"`
	CurrentOrderID *uuid.UUID  `gorm:"type:uuid;index" json:"current_order_id,omitempty"`
	AppVersion     string      `gorm:"size:50" json:"app_version,omitempty"`
	DeviceID       string      `gorm:"size:255" json:"device_id,omitempty"`
	Note           string      `gorm:"type:text" json:"note,omitempty"`
}
