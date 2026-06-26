package search

import (
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type SearchService struct {
	db *gorm.DB
}

type SearchResult struct {
	Products []models.Product `json:"products,omitempty"`
	Barbers  []models.Barber  `json:"barbers,omitempty"`
	Vendors  []models.Vendor  `json:"vendors,omitempty"`
}

type SearchHit struct {
	Type        string      `json:"type"`
	ID          string      `json:"id"`
	Title       string      `json:"title"`
	Description string      `json:"description,omitempty"`
	Image       string      `json:"image,omitempty"`
	Data        interface{} `json:"data,omitempty"`
}

func NewSearchService(db *gorm.DB) *SearchService {
	return &SearchService{db: db}
}

func (s *SearchService) Search(c *gin.Context) {
	q := c.Query("q")
	if q == "" {
		utils.BadRequestResponse(c, "Query parameter 'q' is required")
		return
	}
	searchType := c.DefaultQuery("type", "all")
	page, pageSize := utils.GetPageParams(c)
	offset := (page - 1) * pageSize

	likeQuery := "%" + q + "%"

	var allHits []SearchHit
	var total int64

	if searchType == "all" || searchType == "products" {
		var products []models.Product
		var count int64
		pq := s.db.Model(&models.Product{}).Where("is_active = ? AND is_approved = ?", true, true).
			Where("name ILIKE ? OR description ILIKE ?", likeQuery, likeQuery)
		pq.Count(&count)
		total += count

		pq.Offset(offset).Limit(pageSize).Order("rating DESC, created_at DESC").Find(&products)
		for _, p := range products {
			allHits = append(allHits, SearchHit{
				Type:        "product",
				ID:          p.ID.String(),
				Title:       p.Name,
				Description: p.Description,
				Data:        p,
			})
		}
	}

	if searchType == "all" || searchType == "barbers" {
		var barbers []models.Barber
		var count int64
		bq := s.db.Model(&models.Barber{}).Where("verification_status = ? AND status = ?", models.BarberVerifApproved, models.BarberStatusActive).
			Where("shop_name ILIKE ? OR city ILIKE ? OR LOWER(shop_description) ILIKE LOWER(?)", likeQuery, likeQuery, likeQuery)
		bq.Count(&count)
		total += count

		bq.Offset(offset).Limit(pageSize).Order("rating DESC, is_featured DESC").Find(&barbers)
		for _, b := range barbers {
			allHits = append(allHits, SearchHit{
				Type:        "barber",
				ID:          b.ID.String(),
				Title:       b.ShopName,
				Description: b.City + ", " + b.State,
				Image:       b.ShopImage,
				Data:        b,
			})
		}
	}

	if searchType == "all" || searchType == "vendors" {
		var vendors []models.Vendor
		var count int64
		vq := s.db.Model(&models.Vendor{}).Where("status = ? AND is_active = ?", models.VendorStatusApproved, true).
			Where("store_name ILIKE ? OR city ILIKE ?", likeQuery, likeQuery)
		vq.Count(&count)
		total += count

		vq.Offset(offset).Limit(pageSize).Order("rating DESC, is_featured DESC").Find(&vendors)
		for _, v := range vendors {
			allHits = append(allHits, SearchHit{
				Type:        "vendor",
				ID:          v.ID.String(),
				Title:       v.StoreName,
				Description: v.City + ", " + v.State,
				Data:        v,
			})
		}
	}

	utils.PaginatedResponse(c, allHits, page, pageSize, total)
}
