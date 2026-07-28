package models

import (
	"github.com/google/uuid"
)

type QueueAction string

const (
	QueueActionAssigned   QueueAction = "assigned"
	QueueActionReindexed  QueueAction = "reindexed"
	QueueActionPromoted   QueueAction = "promoted"
	QueueActionSkipped    QueueAction = "skipped"
	QueueActionNoShow     QueueAction = "no_show"
	QueueActionCheckedIn  QueueAction = "checked_in"
	QueueActionImComing   QueueAction = "im_coming"
	QueueActionLate       QueueAction = "late"
	QueueActionReordered   QueueAction = "reordered"
	QueueActionGraceExtend QueueAction = "grace_extended"
)

type QueueAuditLog struct {
	BaseModel
	BarberID      uuid.UUID   `gorm:"type:uuid;index;not null" json:"barber_id"`
	StaffID       *uuid.UUID  `gorm:"type:uuid;index" json:"staff_id,omitempty"`
	BookingID     uuid.UUID   `gorm:"type:uuid;index;not null" json:"booking_id"`
	Action        QueueAction `gorm:"size:50;not null;index" json:"action"`
	OldPosition   int         `gorm:"default:0" json:"old_position"`
	NewPosition   int         `gorm:"default:0" json:"new_position"`
	ChangedBy     uuid.UUID   `gorm:"type:uuid;not null" json:"changed_by"`
	ChangedByRole string      `gorm:"size:50" json:"changed_by_role"`
	Reason        string      `gorm:"type:text" json:"reason,omitempty"`
}
