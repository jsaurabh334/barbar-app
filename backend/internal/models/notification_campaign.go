package models

import (
	"time"

	"github.com/google/uuid"
)

type CampaignTargetType string

const (
	CampaignTargetAll       CampaignTargetType = "all"
	CampaignTargetCustomers CampaignTargetType = "customers"
	CampaignTargetVendors   CampaignTargetType = "vendors"
	CampaignTargetDelivery  CampaignTargetType = "delivery"
	CampaignTargetBarbers   CampaignTargetType = "barbers"
)

type CampaignStatus string

const (
	CampaignStatusDraft     CampaignStatus = "draft"
	CampaignStatusScheduled CampaignStatus = "scheduled"
	CampaignStatusSending   CampaignStatus = "sending"
	CampaignStatusCompleted CampaignStatus = "completed"
	CampaignStatusFailed    CampaignStatus = "failed"
)

type NotificationCampaign struct {
	BaseModel
	Title           string             `gorm:"size:255;not null" json:"title"`
	Message         string             `gorm:"type:text;not null" json:"message"`
	ImageURL        string             `gorm:"size:500" json:"image_url,omitempty"`
	TargetType      CampaignTargetType `gorm:"size:50;not null;index" json:"target_type"`
	ScheduledAt     *time.Time         `json:"scheduled_at,omitempty"`
	Status          CampaignStatus     `gorm:"size:50;not null;default:'draft';index" json:"status"`
	TotalRecipients int                `gorm:"default:0" json:"total_recipients"`
	SentCount       int                `gorm:"default:0" json:"sent_count"`
	FailedCount     int                `gorm:"default:0" json:"failed_count"`
	CreatedBy       uuid.UUID          `gorm:"type:uuid;not null" json:"created_by"`
	SentAt          *time.Time         `json:"sent_at,omitempty"`
}
