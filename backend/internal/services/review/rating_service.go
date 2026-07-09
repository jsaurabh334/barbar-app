package review

import (
	"encoding/json"
	"math"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RatingService struct {
	db *gorm.DB
}

func NewRatingService(db *gorm.DB) *RatingService {
	return &RatingService{db: db}
}

// RecalculateShopRating recomputes avg rating, count, and distribution for a shop
func (s *RatingService) RecalculateShopRating(shopID uuid.UUID) {
	var result struct {
		Avg   float64
		Count int
		Star5 int
		Star4 int
		Star3 int
		Star2 int
		Star1 int
	}

	s.db.Model(&models.Review{}).
		Select(`
			COALESCE(AVG(rating), 0) as avg,
			COUNT(*) as count,
			COUNT(*) FILTER (WHERE rating = 5) as star_5,
			COUNT(*) FILTER (WHERE rating = 4) as star_4,
			COUNT(*) FILTER (WHERE rating = 3) as star_3,
			COUNT(*) FILTER (WHERE rating = 2) as star_2,
			COUNT(*) FILTER (WHERE rating = 1) as star_1
		`).
		Where("shop_id = ? AND status = ?", shopID, models.ReviewStatusApproved).
		Scan(&result)

	dist := models.RatingDistribution{
		Star5: result.Star5,
		Star4: result.Star4,
		Star3: result.Star3,
		Star2: result.Star2,
		Star1: result.Star1,
	}
	distJSON, _ := json.Marshal(dist)

	s.db.Model(&models.Barber{}).Where("id = ?", shopID).Updates(map[string]interface{}{
		"rating":               math.Round(result.Avg*100) / 100,
		"review_count":         result.Count,
		"rating_distribution":  string(distJSON),
	})
}
