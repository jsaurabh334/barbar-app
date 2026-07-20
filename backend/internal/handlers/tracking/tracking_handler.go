package tracking

import (
	trackingSvc "github.com/barbar-app/backend/internal/services/tracking"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type TrackingHandler struct {
	service *trackingSvc.Service
}

func NewTrackingHandler(service *trackingSvc.Service) *TrackingHandler {
	return &TrackingHandler{service: service}
}

func (h *TrackingHandler) GetTracking(c *gin.Context) {
	orderIDStr := c.Param("id")
	orderID, err := uuid.Parse(orderIDStr)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	resp, err := h.service.GetTracking(c.Request.Context(), orderID)
	if err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	utils.SuccessResponse(c, resp)
}
