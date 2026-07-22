package admin

import (
	"net/http"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminCmsHandler struct {
	db *gorm.DB
}

func NewAdminCmsHandler(db *gorm.DB) *AdminCmsHandler {
	return &AdminCmsHandler{db: db}
}

func (h *AdminCmsHandler) ListCmsPages(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var pages []models.CmsPage
	var total int64

	query := h.db.Model(&models.CmsPage{})

	if cType := c.Query("type"); cType != "" {
		query = query.Where("type = ?", cType)
	}
	if published := c.Query("is_published"); published != "" {
		query = query.Where("is_published = ?", published == "true")
	}

	query.Count(&total)
	if err := query.Order("type asc, sort_order asc, created_at desc").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&pages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch CMS pages"})
		return
	}

	c.JSON(http.StatusOK, models.NewPagedResponse(pages, page, pageSize, total))
}

func (h *AdminCmsHandler) GetCmsPage(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid page ID"})
		return
	}

	var page models.CmsPage
	if err := h.db.First(&page, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "CMS page not found"})
		return
	}

	c.JSON(http.StatusOK, page)
}

func (h *AdminCmsHandler) CreateCmsPage(c *gin.Context) {
	var req struct {
		Key         string `json:"key" binding:"required"`
		Title       string `json:"title" binding:"required"`
		Content     string `json:"content" binding:"required"`
		Type        string `json:"type" binding:"required"`
		SortOrder   int    `json:"sort_order"`
		IsPublished *bool  `json:"is_published"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	pageType := models.CmsPageType(req.Type)
	switch pageType {
	case models.CmsPageTypePage, models.CmsPageTypeFAQ:
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid type. Must be: page or faq"})
		return
	}

	isPublished := true
	if req.IsPublished != nil {
		isPublished = *req.IsPublished
	}

	page := models.CmsPage{
		Key:         req.Key,
		Title:       req.Title,
		Content:     req.Content,
		Type:        pageType,
		SortOrder:   req.SortOrder,
		IsPublished: isPublished,
	}

	if err := h.db.Create(&page).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create page. Key may already exist."})
		return
	}

	c.JSON(http.StatusCreated, page)
}

func (h *AdminCmsHandler) UpdateCmsPage(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid page ID"})
		return
	}

	var page models.CmsPage
	if err := h.db.First(&page, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "CMS page not found"})
		return
	}

	var req struct {
		Key         *string `json:"key"`
		Title       *string `json:"title"`
		Content     *string `json:"content"`
		Type        *string `json:"type"`
		SortOrder   *int    `json:"sort_order"`
		IsPublished *bool   `json:"is_published"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}

	if req.Key != nil {
		updates["key"] = *req.Key
	}
	if req.Title != nil {
		updates["title"] = *req.Title
	}
	if req.Content != nil {
		updates["content"] = *req.Content
	}
	if req.Type != nil {
		pt := models.CmsPageType(*req.Type)
		switch pt {
		case models.CmsPageTypePage, models.CmsPageTypeFAQ:
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid type"})
			return
		}
		updates["type"] = pt
	}
	if req.SortOrder != nil {
		updates["sort_order"] = *req.SortOrder
	}
	if req.IsPublished != nil {
		updates["is_published"] = *req.IsPublished
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	if err := h.db.Model(&page).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update page"})
		return
	}

	h.db.First(&page, "id = ?", id)
	c.JSON(http.StatusOK, page)
}

func (h *AdminCmsHandler) DeleteCmsPage(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid page ID"})
		return
	}

	result := h.db.Delete(&models.CmsPage{}, "id = ?", id)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "CMS page not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Page deleted successfully"})
}

// PublicGetCmsPage serves a published page by key to unauthenticated users
func (h *AdminCmsHandler) PublicGetCmsPage(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Page key is required"})
		return
	}

	var page models.CmsPage
	if err := h.db.Where("key = ? AND is_published = ?", key, true).First(&page).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Page not found"})
		return
	}

	c.JSON(http.StatusOK, page)
}
