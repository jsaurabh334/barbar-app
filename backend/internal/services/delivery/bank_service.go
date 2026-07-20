package delivery

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BankAccountService struct {
	db *gorm.DB
}

func NewBankAccountService(db *gorm.DB) *BankAccountService {
	return &BankAccountService{db: db}
}

type UpsertBankAccountInput struct {
	AccountHolderName string
	AccountNumber     string
	IFSCCode          string
	BankName          string
	BranchName        string
	UPIID             string
}

func (s *BankAccountService) Upsert(partnerID uuid.UUID, input UpsertBankAccountInput) (*models.DeliveryPartnerBankAccount, error) {
	var account models.DeliveryPartnerBankAccount
	result := s.db.Where("delivery_partner_id = ?", partnerID).First(&account)

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			account = models.DeliveryPartnerBankAccount{
				DeliveryPartnerID: partnerID,
				AccountHolderName: input.AccountHolderName,
				AccountNumber:     input.AccountNumber,
				IFSCCode:          input.IFSCCode,
				BankName:          input.BankName,
				BranchName:        input.BranchName,
				UPIID:             input.UPIID,
				IsPrimary:         true,
			}
			if err := s.db.Create(&account).Error; err != nil {
				return nil, err
			}
			return &account, nil
		}
		return nil, result.Error
	}

	updates := map[string]interface{}{
		"account_holder_name": input.AccountHolderName,
		"account_number":      input.AccountNumber,
		"ifsc_code":           input.IFSCCode,
		"bank_name":           input.BankName,
		"branch_name":         input.BranchName,
		"upi_id":              input.UPIID,
	}
	if err := s.db.Model(&account).Updates(updates).Error; err != nil {
		return nil, err
	}

	s.db.First(&account, account.ID)
	return &account, nil
}

func (s *BankAccountService) GetByPartnerID(partnerID uuid.UUID) (*models.DeliveryPartnerBankAccount, error) {
	var account models.DeliveryPartnerBankAccount
	if err := s.db.Where("delivery_partner_id = ?", partnerID).First(&account).Error; err != nil {
		return nil, err
	}
	return &account, nil
}

func (s *BankAccountService) Delete(partnerID uuid.UUID) error {
	result := s.db.Where("delivery_partner_id = ?", partnerID).Delete(&models.DeliveryPartnerBankAccount{})
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return result.Error
}
