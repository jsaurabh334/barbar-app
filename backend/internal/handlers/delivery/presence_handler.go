package delivery

import (
	"net/http"

	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PresenceHandler struct {
	service *deliverySvc.PresenceService
}

func NewPresenceHandler(service *deliverySvc.PresenceService) *PresenceHandler {
	return &PresenceHandler{service: service}
}

type goOnlineRequest struct {
	DeviceID   string `json:"device_id"`
	AppVersion string `json:"app_version"`
}

func (h *PresenceHandler) GoOnline(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req goOnlineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if err := h.service.SetOnline(c.Request.Context(), userID, req.DeviceID, req.AppVersion); err != nil {
		utils.InternalErrorResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Driver is now online"})
}

func (h *PresenceHandler) GoOffline(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	if err := h.service.SetOffline(c.Request.Context(), userID); err != nil {
		utils.InternalErrorResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Driver is now offline"})
}

func (h *PresenceHandler) Heartbeat(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	if err := h.service.Heartbeat(c.Request.Context(), userID); err != nil {
		utils.InternalErrorResponse(c, err.Error())
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (h *PresenceHandler) GetMyPresence(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	presence, err := h.service.GetPresence(c.Request.Context(), userID)
	if err != nil {
		utils.NotFoundResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, presence)
}

func (h *PresenceHandler) GetOnlineDrivers(c *gin.Context) {
	drivers, err := h.service.ListOnlineDrivers(c.Request.Context())
	if err != nil {
		utils.InternalErrorResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, drivers)
}

func (h *PresenceHandler) GetPresenceSummary(c *gin.Context) {
	summary, err := h.service.GetPresenceSummary(c.Request.Context())
	if err != nil {
		utils.InternalErrorResponse(c, err.Error())
		return
	}

	utils.SuccessResponse(c, summary)
}
