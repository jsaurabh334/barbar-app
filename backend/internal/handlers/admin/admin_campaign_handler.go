package admin

import (
	"net/http"
	"time"

	"github.com/barbar-app/backend/internal/models"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminCampaignHandler struct {
	db       *gorm.DB
	notifSvc *notifService.NotificationService
}

func NewAdminCampaignHandler(db *gorm.DB, notifSvc *notifService.NotificationService) *AdminCampaignHandler {
	return &AdminCampaignHandler{db: db, notifSvc: notifSvc}
}

func (h *AdminCampaignHandler) ListCampaigns(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var campaigns []models.NotificationCampaign
	var total int64

	query := h.db.Model(&models.NotificationCampaign{})

	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if target := c.Query("target_type"); target != "" {
		query = query.Where("target_type = ?", target)
	}

	query.Count(&total)
	if err := query.Order("created_at desc").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&campaigns).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch campaigns"})
		return
	}

	c.JSON(http.StatusOK, models.NewPagedResponse(campaigns, page, pageSize, total))
}

func (h *AdminCampaignHandler) GetCampaign(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	var campaign models.NotificationCampaign
	if err := h.db.First(&campaign, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	c.JSON(http.StatusOK, campaign)
}

func (h *AdminCampaignHandler) CreateCampaign(c *gin.Context) {
	var req struct {
		Title       string `json:"title" binding:"required"`
		Message     string `json:"message" binding:"required"`
		ImageURL    string `json:"image_url"`
		TargetType  string `json:"target_type" binding:"required"`
		ScheduledAt *string `json:"scheduled_at"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	targetType := models.CampaignTargetType(req.TargetType)
	switch targetType {
	case models.CampaignTargetAll, models.CampaignTargetCustomers, models.CampaignTargetVendors,
		models.CampaignTargetDelivery, models.CampaignTargetBarbers:
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target_type. Must be: all, customers, vendors, delivery, or barbers"})
		return
	}

	var scheduledAt *time.Time
	if req.ScheduledAt != nil {
		t, err := time.Parse(time.RFC3339, *req.ScheduledAt)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid scheduled_at format (use RFC3339)"})
			return
		}
		scheduledAt = &t
	}

	userID, _ := c.Get("user_id")
	createdBy, _ := userID.(uuid.UUID)

	status := models.CampaignStatusDraft
	if scheduledAt != nil {
		status = models.CampaignStatusScheduled
	}

	campaign := models.NotificationCampaign{
		Title:      req.Title,
		Message:    req.Message,
		ImageURL:   req.ImageURL,
		TargetType: targetType,
		ScheduledAt: scheduledAt,
		Status:     status,
		CreatedBy:  createdBy,
	}

	if err := h.db.Create(&campaign).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create campaign"})
		return
	}

	c.JSON(http.StatusCreated, campaign)
}

func (h *AdminCampaignHandler) UpdateCampaign(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	var campaign models.NotificationCampaign
	if err := h.db.First(&campaign, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	if campaign.Status != models.CampaignStatusDraft && campaign.Status != models.CampaignStatusScheduled {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Only draft or scheduled campaigns can be updated"})
		return
	}

	var req struct {
		Title       *string `json:"title"`
		Message     *string `json:"message"`
		ImageURL    *string `json:"image_url"`
		TargetType  *string `json:"target_type"`
		ScheduledAt *string `json:"scheduled_at"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{}

	if req.Title != nil {
		updates["title"] = *req.Title
	}
	if req.Message != nil {
		updates["message"] = *req.Message
	}
	if req.ImageURL != nil {
		updates["image_url"] = *req.ImageURL
	}
	if req.TargetType != nil {
		tt := models.CampaignTargetType(*req.TargetType)
		switch tt {
		case models.CampaignTargetAll, models.CampaignTargetCustomers, models.CampaignTargetVendors,
			models.CampaignTargetDelivery, models.CampaignTargetBarbers:
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target_type"})
			return
		}
		updates["target_type"] = tt
	}
	if req.ScheduledAt != nil {
		if *req.ScheduledAt == "" {
			updates["scheduled_at"] = nil
			updates["status"] = models.CampaignStatusDraft
		} else {
			t, err := time.Parse(time.RFC3339, *req.ScheduledAt)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid scheduled_at format"})
				return
			}
			updates["scheduled_at"] = t
			updates["status"] = models.CampaignStatusScheduled
		}
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	if err := h.db.Model(&campaign).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update campaign"})
		return
	}

	h.db.First(&campaign, "id = ?", id)
	c.JSON(http.StatusOK, campaign)
}

func (h *AdminCampaignHandler) DeleteCampaign(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	var campaign models.NotificationCampaign
	if err := h.db.First(&campaign, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	if campaign.Status == models.CampaignStatusSending {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete a campaign that is currently sending"})
		return
	}

	h.db.Delete(&campaign)
	c.JSON(http.StatusOK, gin.H{"message": "Campaign deleted successfully"})
}

func (h *AdminCampaignHandler) SendCampaign(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	var campaign models.NotificationCampaign
	if err := h.db.First(&campaign, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	if campaign.Status != models.CampaignStatusDraft && campaign.Status != models.CampaignStatusScheduled {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Campaign already sent or in progress"})
		return
	}

	go h.executeCampaign(campaign)
	c.JSON(http.StatusOK, gin.H{"message": "Campaign send initiated"})
}

func (h *AdminCampaignHandler) executeCampaign(campaign models.NotificationCampaign) {
	h.db.Model(&campaign).Update("status", models.CampaignStatusSending)

	var roles []string
	switch campaign.TargetType {
	case models.CampaignTargetAll:
		roles = []string{"customer", "barber", "vendor", "delivery"}
	case models.CampaignTargetCustomers:
		roles = []string{"customer"}
	case models.CampaignTargetBarbers:
		roles = []string{"barber"}
	case models.CampaignTargetVendors:
		roles = []string{"vendor"}
	case models.CampaignTargetDelivery:
		roles = []string{"delivery"}
	}

	input := notifService.SendNotificationInput{
		Title: campaign.Title,
		Body:  campaign.Message,
		Type:  models.NotifPromotion,
		Image: campaign.ImageURL,
	}

	totalSent := 0
	totalFailed := 0
	now := time.Now()

	for _, role := range roles {
		var recipients []struct {
			ID uuid.UUID
		}
		result := h.db.Model(&models.User{}).
			Select("id").
			Where("role = ? AND status = ?", role, "active").
			Find(&recipients)

		if result.Error != nil {
			continue
		}

		for _, r := range recipients {
			input.UserID = r.ID
			if err := h.notifSvc.Send(input); err != nil {
				totalFailed++
			} else {
				totalSent++
			}
		}
	}

	status := models.CampaignStatusCompleted
	if totalFailed > 0 && totalSent == 0 {
		status = models.CampaignStatusFailed
	}

	h.db.Model(&campaign).Updates(map[string]interface{}{
		"status":           status,
		"sent_count":       totalSent,
		"failed_count":     totalFailed,
		"total_recipients": totalSent + totalFailed,
		"sent_at":          now,
	})
}
