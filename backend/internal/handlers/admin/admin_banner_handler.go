package admin

import (
	"net/http"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminBannerHandler struct {
	db *gorm.DB
}

func NewAdminBannerHandler(db *gorm.DB) *AdminBannerHandler {
	return &AdminBannerHandler{db: db}
}

func (h *AdminBannerHandler) ListBanners(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var banners []models.Banner
	var total int64

	query := h.db.Model(&models.Banner{})

	if pos := c.Query("position"); pos != "" {
		query = query.Where("position = ?", pos)
	}
	if active := c.Query("is_active"); active != "" {
		query = query.Where("is_active = ?", active == "true")
	}

	query.Count(&total)
	if err := query.Order("sort_order asc, created_at desc").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&banners).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch banners"})
		return
	}

	c.JSON(http.StatusOK, models.NewPagedResponse(banners, page, pageSize, total))
}

func (h *AdminBannerHandler) GetBanner(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid banner ID"})
		return
	}

	var banner models.Banner
	if err := h.db.First(&banner, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Banner not found"})
		return
	}

	c.JSON(http.StatusOK, banner)
}

func (h *AdminBannerHandler) CreateBanner(c *gin.Context) {
	var req struct {
		Title     string  `json:"title" binding:"required"`
		ImageURL  string  `json:"image_url" binding:"required"`
		LinkURL   string  `json:"link_url"`
		Position  string  `json:"position" binding:"required"`
		SortOrder int     `json:"sort_order"`
		StartDate *string `json:"start_date"`
		EndDate   *string `json:"end_date"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pos := models.BannerPosition(req.Position)
	switch pos {
	case models.BannerPositionHomeTop, models.BannerPositionHomeMiddle, models.BannerPositionPromotions:
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid position. Must be: home_top, home_middle, or promotions"})
		return
	}

	var startDate, endDate *time.Time
	if req.StartDate != nil {
		t, err := time.Parse(time.RFC3339, *req.StartDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid start_date format (use RFC3339)"})
			return
		}
		startDate = &t
	}
	if req.EndDate != nil {
		t, err := time.Parse(time.RFC3339, *req.EndDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid end_date format (use RFC3339)"})
			return
		}
		endDate = &t
	}

	banner := models.Banner{
		Title:     req.Title,
		ImageURL:  req.ImageURL,
		LinkURL:   req.LinkURL,
		Position:  pos,
		IsActive:  true,
		SortOrder: req.SortOrder,
		StartDate: startDate,
		EndDate:   endDate,
	}

	if err := h.db.Create(&banner).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create banner"})
		return
	}

	c.JSON(http.StatusCreated, banner)
}

func (h *AdminBannerHandler) UpdateBanner(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid banner ID"})
		return
	}

	var banner models.Banner
	if err := h.db.First(&banner, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Banner not found"})
		return
	}

	var req struct {
		Title     *string `json:"title"`
		ImageURL  *string `json:"image_url"`
		LinkURL   *string `json:"link_url"`
		Position  *string `json:"position"`
		SortOrder *int    `json:"sort_order"`
		StartDate *string `json:"start_date"`
		EndDate   *string `json:"end_date"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}

	if req.Title != nil {
		updates["title"] = *req.Title
	}
	if req.ImageURL != nil {
		updates["image_url"] = *req.ImageURL
	}
	if req.LinkURL != nil {
		updates["link_url"] = *req.LinkURL
	}
	if req.Position != nil {
		pos := models.BannerPosition(*req.Position)
		switch pos {
		case models.BannerPositionHomeTop, models.BannerPositionHomeMiddle, models.BannerPositionPromotions:
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid position"})
			return
		}
		updates["position"] = pos
	}
	if req.SortOrder != nil {
		updates["sort_order"] = *req.SortOrder
	}
	if req.StartDate != nil {
		t, err := time.Parse(time.RFC3339, *req.StartDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid start_date format"})
			return
		}
		updates["start_date"] = t
	}
	if req.EndDate != nil {
		t, err := time.Parse(time.RFC3339, *req.EndDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid end_date format"})
			return
		}
		updates["end_date"] = t
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	if err := h.db.Model(&banner).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update banner"})
		return
	}

	h.db.First(&banner, "id = ?", id)
	c.JSON(http.StatusOK, banner)
}

func (h *AdminBannerHandler) DeleteBanner(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid banner ID"})
		return
	}

	result := h.db.Delete(&models.Banner{}, "id = ?", id)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Banner not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Banner deleted successfully"})
}

func (h *AdminBannerHandler) ToggleBannerActive(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid banner ID"})
		return
	}

	var banner models.Banner
	if err := h.db.First(&banner, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Banner not found"})
		return
	}

	banner.IsActive = !banner.IsActive
	if err := h.db.Save(&banner).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to toggle banner status"})
		return
	}

	c.JSON(http.StatusOK, banner)
}
