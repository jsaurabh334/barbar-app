package models

import (
	"github.com/barbar-app/backend/internal/services/encryption"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DeliveryPartnerBankAccount struct {
	BaseModel
	DeliveryPartnerID uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"delivery_partner_id"`
	AccountHolderName string    `gorm:"size:255;not null" json:"account_holder_name"`
	AccountNumber     string    `gorm:"size:500;not null" json:"-"`
	IFSCCode          string    `gorm:"size:20;not null" json:"ifsc_code"`
	BankName          string    `gorm:"size:255;not null" json:"bank_name"`
	BranchName        string    `gorm:"size:255" json:"branch_name,omitempty"`
	UPIID             string    `gorm:"size:100" json:"upi_id,omitempty"`
	IsPrimary         bool      `gorm:"default:true" json:"is_primary"`
	IsVerified        bool      `gorm:"default:false" json:"is_verified"`
}

func (b *DeliveryPartnerBankAccount) BeforeSave(tx *gorm.DB) error {
	if b.AccountNumber != "" && len(b.AccountNumber) < 100 {
		enc, err := encryption.Encrypt(b.AccountNumber)
		if err != nil {
			return err
		}
		b.AccountNumber = enc
	}
	return nil
}

func (b *DeliveryPartnerBankAccount) AfterFind(tx *gorm.DB) error {
	if b.AccountNumber != "" && len(b.AccountNumber) > 50 {
		dec, err := encryption.Decrypt(b.AccountNumber)
		if err != nil {
			return err
		}
		b.AccountNumber = dec
	}
	return nil
}
