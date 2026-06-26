package webhook

import (
	"encoding/json"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	webhookSvc "github.com/barbar-app/backend/internal/services/webhook"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WebhookHandler struct {
	db  *gorm.DB
	svc *webhookSvc.WebhookService
}

func NewWebhookHandler(db *gorm.DB, svc *webhookSvc.WebhookService) *WebhookHandler {
	return &WebhookHandler{db: db, svc: svc}
}

func (h *WebhookHandler) List(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var endpoints []models.WebhookEndpoint
	var total int64

	query := h.db.Model(&models.WebhookEndpoint{})
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&endpoints)

	utils.PaginatedResponse(c, endpoints, page, pageSize, total)
}

func (h *WebhookHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid webhook ID")
		return
	}

	var ep models.WebhookEndpoint
	if err := h.db.First(&ep, id).Error; err != nil {
		utils.NotFoundResponse(c, "Webhook not found")
		return
	}
	utils.SuccessResponse(c, ep)
}

func (h *WebhookHandler) Create(c *gin.Context) {
	var req struct {
		URL         string   `json:"url" binding:"required"`
		Events      []string `json:"events" binding:"required"`
		Secret      string   `json:"secret"`
		Description string   `json:"description"`
		RetryCount  int      `json:"retry_count"`
		TimeoutSec  int      `json:"timeout_sec"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	eventsBytes, _ := json.Marshal(req.Events)

	if req.RetryCount == 0 {
		req.RetryCount = 3
	}
	if req.TimeoutSec == 0 {
		req.TimeoutSec = 10
	}

	ep := models.WebhookEndpoint{
		URL:         req.URL,
		Events:      models.JSONB(eventsBytes),
		Secret:      req.Secret,
		Description: req.Description,
		Status:      models.WebhookActive,
		RetryCount:  req.RetryCount,
		TimeoutSec:  req.TimeoutSec,
	}
	h.db.Create(&ep)
	utils.CreatedResponse(c, ep)
}

func (h *WebhookHandler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid webhook ID")
		return
	}

	var ep models.WebhookEndpoint
	if err := h.db.First(&ep, id).Error; err != nil {
		utils.NotFoundResponse(c, "Webhook not found")
		return
	}

	var req struct {
		URL         *string  `json:"url"`
		Events      []string `json:"events"`
		Secret      *string  `json:"secret"`
		Description *string  `json:"description"`
		Status      *string  `json:"status"`
		RetryCount  *int     `json:"retry_count"`
		TimeoutSec  *int     `json:"timeout_sec"`
	}
	c.ShouldBindJSON(&req)

	updates := map[string]interface{}{}
	if req.URL != nil { updates["url"] = *req.URL }
	if req.Secret != nil { updates["secret"] = *req.Secret }
	if req.Description != nil { updates["description"] = *req.Description }
	if req.Status != nil { updates["status"] = *req.Status }
	if req.RetryCount != nil { updates["retry_count"] = *req.RetryCount }
	if req.TimeoutSec != nil { updates["timeout_sec"] = *req.TimeoutSec }
	if req.Events != nil {
		eventsBytes, _ := json.Marshal(req.Events)
		updates["events"] = models.JSONB(eventsBytes)
	}

	h.db.Model(&ep).Updates(updates)
	h.db.First(&ep, id)
	utils.SuccessResponse(c, ep)
}

func (h *WebhookHandler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid webhook ID")
		return
	}

	result := h.db.Delete(&models.WebhookEndpoint{}, id)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Webhook not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "Webhook deleted"})
}

func (h *WebhookHandler) GetLogs(c *gin.Context) {
	id := c.Param("id")
	logs := h.svc.GetDeliveryLogs(id)
	utils.SuccessResponse(c, logs)
}
