package delivery

import (
	"errors"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type EarningService struct {
	db *gorm.DB
}

func NewEarningService(db *gorm.DB) *EarningService {
	return &EarningService{db: db}
}

type CreateEarningInput struct {
	DeliveryPartnerID uuid.UUID
	OrderID           uuid.UUID
	BaseAmount        float64
	DistanceAmount    float64
	BonusAmount       float64
	TipAmount         float64
	Description       string
}

func (s *EarningService) CreateEarning(input CreateEarningInput) (*models.DeliveryEarning, error) {
	total := input.BaseAmount + input.DistanceAmount + input.BonusAmount + input.TipAmount

	earning := models.DeliveryEarning{
		DeliveryPartnerID: input.DeliveryPartnerID,
		OrderID:           input.OrderID,
		BaseAmount:        input.BaseAmount,
		DistanceAmount:    input.DistanceAmount,
		BonusAmount:       input.BonusAmount,
		TipAmount:         input.TipAmount,
		TotalAmount:       total,
		Status:            models.EarningStatusPending,
		Description:       input.Description,
	}

	if err := s.db.Create(&earning).Error; err != nil {
		return nil, err
	}
	return &earning, nil
}

func (s *EarningService) GetEarningByOrder(orderID uuid.UUID) (*models.DeliveryEarning, error) {
	var earning models.DeliveryEarning
	if err := s.db.Where("order_id = ?", orderID).First(&earning).Error; err != nil {
		return nil, err
	}
	return &earning, nil
}

func (s *EarningService) ListEarnings(partnerID uuid.UUID, limit, offset int) ([]models.DeliveryEarning, int64, error) {
	var earnings []models.DeliveryEarning
	var total int64

	query := s.db.Model(&models.DeliveryEarning{}).Where("delivery_partner_id = ?", partnerID)
	query.Count(&total)

	if err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&earnings).Error; err != nil {
		return nil, 0, err
	}
	return earnings, total, nil
}

type EarningSummary struct {
	TotalEarnings float64 `json:"total_earnings"`
	TotalOrders   int64   `json:"total_orders"`
	PendingAmount float64 `json:"pending_amount"`
	SettledAmount float64 `json:"settled_amount"`
	ThisWeek      float64 `json:"this_week"`
	ThisMonth     float64 `json:"this_month"`
}

func (s *EarningService) GetSummary(partnerID uuid.UUID) (*EarningSummary, error) {
	var summary EarningSummary

	now := time.Now()
	weekStart := now.AddDate(0, 0, -int(now.Weekday()))
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	base := s.db.Model(&models.DeliveryEarning{}).Where("delivery_partner_id = ?", partnerID)

	base.Select("COALESCE(SUM(total_amount), 0)").Scan(&summary.TotalEarnings)
	base.Select("COUNT(*)").Scan(&summary.TotalOrders)
	base.Where("status = ?", models.EarningStatusPending).Select("COALESCE(SUM(total_amount), 0)").Scan(&summary.PendingAmount)
	base.Where("status = ?", models.EarningStatusSettled).Select("COALESCE(SUM(total_amount), 0)").Scan(&summary.SettledAmount)
	base.Where("created_at >= ?", weekStart).Select("COALESCE(SUM(total_amount), 0)").Scan(&summary.ThisWeek)
	base.Where("created_at >= ?", monthStart).Select("COALESCE(SUM(total_amount), 0)").Scan(&summary.ThisMonth)

	return &summary, nil
}

func (s *EarningService) SettleEarning(earningID uuid.UUID) error {
	now := time.Now()
	result := s.db.Model(&models.DeliveryEarning{}).Where("id = ? AND status = ?", earningID, models.EarningStatusPending).
		Updates(map[string]interface{}{"status": models.EarningStatusSettled, "settled_at": &now})
	if result.RowsAffected == 0 {
		return errors.New("earning not found or already settled")
	}
	return result.Error
}
