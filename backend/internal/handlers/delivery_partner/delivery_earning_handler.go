package delivery_partner

import (
	"strconv"

	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type EarningHandler struct {
	earningSvc *deliverySvc.EarningService
}

func NewEarningHandler(earningSvc *deliverySvc.EarningService) *EarningHandler {
	return &EarningHandler{earningSvc: earningSvc}
}

func (h *EarningHandler) ListEarnings(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	earnings, total, err := h.earningSvc.ListEarnings(userID, limit, offset)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch earnings")
		return
	}
	page := offset/limit + 1
	utils.PaginatedResponse(c, earnings, page, limit, total)
}

func (h *EarningHandler) GetEarningSummary(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	summary, err := h.earningSvc.GetSummary(userID)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch earning summary")
		return
	}
	utils.SuccessResponse(c, summary)
}
