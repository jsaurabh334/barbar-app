package models

import (
	"github.com/google/uuid"
)

type DeliveryPartnerBankAccount struct {
	BaseModel
	DeliveryPartnerID uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"delivery_partner_id"`
	AccountHolderName string    `gorm:"size:255;not null" json:"account_holder_name"`
	AccountNumber     string    `gorm:"size:100;not null" json:"account_number"`
	IFSCCode          string    `gorm:"size:20;not null" json:"ifsc_code"`
	BankName          string    `gorm:"size:255;not null" json:"bank_name"`
	BranchName        string    `gorm:"size:255" json:"branch_name,omitempty"`
	UPIID             string    `gorm:"size:100" json:"upi_id,omitempty"`
	IsPrimary         bool      `gorm:"default:true" json:"is_primary"`
	IsVerified        bool      `gorm:"default:false" json:"is_verified"`
}
