package warehouse

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SelectionService struct {
	db *gorm.DB
}

func NewSelectionService(db *gorm.DB) *SelectionService {
	return &SelectionService{db: db}
}

func (s *SelectionService) SelectWarehouse(vendorID uuid.UUID, _ []models.OrderItem) (*models.Warehouse, error) {
	var warehouse models.Warehouse
	err := s.db.Where("vendor_id = ? AND is_default = ? AND is_active = ? AND (warehouse_type = ? OR warehouse_type = ?)",
		vendorID, true, true, models.WarehouseTypePickup, models.WarehouseTypeBoth).
		First(&warehouse).Error
	if err != nil {
		err = s.db.Where("vendor_id = ? AND is_active = ? AND (warehouse_type = ? OR warehouse_type = ?)",
			vendorID, true, models.WarehouseTypePickup, models.WarehouseTypeBoth).
			Order("display_order ASC, created_at ASC").
			First(&warehouse).Error
		if err != nil {
			return nil, err
		}
	}
	return &warehouse, nil
}
