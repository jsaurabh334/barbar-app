package invoice

import (
	"github.com/barbar-app/backend/internal/services/invoice"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
)

type InvoiceHandler struct {
	svc *invoice.InvoiceService
}

func NewInvoiceHandler(svc *invoice.InvoiceService) *InvoiceHandler {
	return &InvoiceHandler{svc: svc}
}

func (h *InvoiceHandler) GetOrderInvoice(c *gin.Context) {
	orderID := c.Param("id")
	html, err := h.svc.GenerateOrderInvoice(orderID)
	if err != nil {
		utils.NotFoundResponse(c, err.Error())
		return
	}
	c.Header("Content-Type", "text/html")
	c.String(200, html)
}

func (h *InvoiceHandler) GetBookingReceipt(c *gin.Context) {
	bookingID := c.Param("id")
	html, err := h.svc.GenerateBookingReceipt(bookingID)
	if err != nil {
		utils.NotFoundResponse(c, err.Error())
		return
	}
	c.Header("Content-Type", "text/html")
	c.String(200, html)
}

func (h *InvoiceHandler) GetBookingInvoiceJSON(c *gin.Context) {
	bookingID := c.Param("id")
	data, err := h.svc.GetBookingInvoiceData(bookingID)
	if err != nil {
		utils.NotFoundResponse(c, err.Error())
		return
	}
	utils.SuccessResponse(c, data)
}
