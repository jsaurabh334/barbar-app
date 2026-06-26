package search

import (
	"github.com/barbar-app/backend/internal/services/analytics"
	"github.com/barbar-app/backend/internal/services/search"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
)

type SearchHandler struct {
	searchSvc    *search.SearchService
	analyticsSvc *analytics.AnalyticsService
}

func NewSearchHandler(svc *search.SearchService, analyticsSvc *analytics.AnalyticsService) *SearchHandler {
	return &SearchHandler{searchSvc: svc, analyticsSvc: analyticsSvc}
}

func (h *SearchHandler) Search(c *gin.Context) {
	h.searchSvc.Search(c)
}

func (h *SearchHandler) ExportRevenueCSV(c *gin.Context) {
	csvStr, err := h.analyticsSvc.ExportRevenueCSV(c)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate CSV")
		return
	}
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=revenue_report.csv")
	c.String(200, csvStr)
}

func (h *SearchHandler) ExportUserGrowthCSV(c *gin.Context) {
	csvStr, err := h.analyticsSvc.ExportUserGrowthCSV(c)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate CSV")
		return
	}
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=user_growth.csv")
	c.String(200, csvStr)
}

func (h *SearchHandler) ExportTopBarbersCSV(c *gin.Context) {
	csvStr, err := h.analyticsSvc.ExportTopBarbersCSV(c)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate CSV")
		return
	}
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=top_barbers.csv")
	c.String(200, csvStr)
}
