package admin

import (
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/services/queue"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminBookingHandler struct {
	db         *gorm.DB
	dispatcher notification.Dispatcher
	hub        *websocket.Hub
}

func NewAdminBookingHandler(db *gorm.DB, dispatcher notification.Dispatcher, hub *websocket.Hub) *AdminBookingHandler {
	return &AdminBookingHandler{db: db, dispatcher: dispatcher, hub: hub}
}

func (h *AdminBookingHandler) GetBookingDetail(c *gin.Context) {
	bookingID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.
		Preload("Barber").
		Preload("Staff").
		Preload("Customer").
		Preload("Services").
		Preload("StatusLog", func(db *gorm.DB) *gorm.DB {
			return db.Order("booking_status_logs.created_at ASC")
		}).
		First(&booking, bookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	utils.SuccessResponse(c, booking)
}

func (h *AdminBookingHandler) AdminCancelBooking(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	bookingID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Cancellation reason is required")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, bookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	if booking.Status == models.BookingStatusCancelled {
		utils.BadRequestResponse(c, "Booking is already cancelled")
		return
	}
	if booking.Status == models.BookingStatusCompleted {
		utils.BadRequestResponse(c, "Completed bookings cannot be cancelled")
		return
	}

	now := time.Now()
	originalStatus := booking.Status
	booking.Status = models.BookingStatusCancelled
	booking.CancellationReason = req.Reason
	booking.CancelledBy = &adminID
	booking.CancelledAt = &now
	h.db.Save(&booking)

	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     originalStatus,
		ToStatus:       models.BookingStatusCancelled,
		ChangedBy:      adminID,
		ChangedByRole:  claims.Role,
		Reason:         req.Reason,
	})

	if originalStatus != models.BookingStatusHomeServicePending {
		h.db.Model(&models.Barber{}).Where("id = ?", booking.BarberID).
			Update("current_queue_length", gorm.Expr("GREATEST(current_queue_length - 1, 0)"))
	}

	qSvc := queue.NewQueueService(h.db, h.hub, h.dispatcher)
	qSvc.RecalculatePositions(booking.BarberID)
	qSvc.RecalculateWaitTimes(booking.BarberID)
	qSvc.BroadcastQueueUpdate(booking.BarberID)

	if booking.PaymentStatus == "paid" {
		go h.processRefund(&booking)
	}

	utils.SuccessResponse(c, gin.H{"message": "Booking cancelled"})
}

func (h *AdminBookingHandler) AdminRescheduleBooking(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	bookingID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var req struct {
		NewStart string `json:"new_start" binding:"required"`
		NewEnd   string `json:"new_end" binding:"required"`
		Reason   string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "New start and end times are required")
		return
	}

	newStart, err := time.Parse(time.RFC3339, req.NewStart)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid new_start format, use RFC3339")
		return
	}
	newEnd, err := time.Parse(time.RFC3339, req.NewEnd)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid new_end format, use RFC3339")
		return
	}

	if !newEnd.After(newStart) {
		utils.BadRequestResponse(c, "End time must be after start time")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, bookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	if booking.Status == models.BookingStatusCancelled {
		utils.BadRequestResponse(c, "Cancelled bookings cannot be rescheduled")
		return
	}
	if booking.Status == models.BookingStatusCompleted {
		utils.BadRequestResponse(c, "Completed bookings cannot be rescheduled")
		return
	}

	oldStart := booking.ScheduledStart
	oldEnd := booking.ScheduledEnd
	booking.ScheduledStart = newStart
	booking.ScheduledEnd = newEnd
	booking.Status = models.BookingStatusRescheduled
	h.db.Save(&booking)

	rescheduleReason := req.Reason
	if rescheduleReason == "" {
		rescheduleReason = "Rescheduled by admin"
	}
	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     booking.Status,
		ToStatus:       models.BookingStatusRescheduled,
		ChangedBy:      adminID,
		ChangedByRole:  claims.Role,
		Reason:         rescheduleReason,
	})

	qSvc := queue.NewQueueService(h.db, h.hub, h.dispatcher)
	qSvc.RecalculatePositions(booking.BarberID)
	qSvc.RecalculateWaitTimes(booking.BarberID)
	qSvc.BroadcastQueueUpdate(booking.BarberID)

	utils.SuccessResponse(c, gin.H{
		"message":           "Booking rescheduled",
		"old_start":         oldStart,
		"old_end":           oldEnd,
		"new_start":         newStart,
		"new_end":           newEnd,
	})
}

func (h *AdminBookingHandler) GetBookingTimeline(c *gin.Context) {
	bookingID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var logs []models.BookingStatusLog
	if err := h.db.Where("booking_id = ?", bookingID).
		Order("created_at ASC").
		Find(&logs).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to fetch booking timeline")
		return
	}

	utils.SuccessResponse(c, logs)
}

func (h *AdminBookingHandler) processRefund(booking *models.Booking) {
	var payment models.Payment
	if err := h.db.Where("order_id = ?", booking.ID).First(&payment).Error; err != nil {
		refund := models.RefundRequest{
			OrderID:      booking.ID,
			CustomerID:   booking.CustomerID,
			Reason:       "Admin-initiated cancellation",
			RefundType:   "full",
			RefundAmount: booking.FinalPrice,
			Status:       "approved",
		}
		h.db.Create(&refund)
		return
	}

	now := time.Now()
	refund := models.RefundRequest{
		OrderID:      booking.ID,
		CustomerID:   booking.CustomerID,
		Reason:       "Admin-initiated cancellation",
		RefundType:   "full",
		RefundAmount: booking.FinalPrice,
		Status:       "approved",
		ProcessedAt:  &now,
	}
	h.db.Create(&refund)

	payment.RefundAmount = booking.FinalPrice
	payment.RefundStatus = "approved"
	payment.RefundedAt = &now
	h.db.Save(&payment)

	h.db.Model(&models.Booking{}).Where("id = ?", booking.ID).Update("payment_status", "refunded")
}
