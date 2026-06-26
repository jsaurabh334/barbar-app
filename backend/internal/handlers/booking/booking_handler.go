package booking

import (
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BookingHandler struct {
	db      *gorm.DB
	notifSvc *notifService.NotificationService
}

func NewBookingHandler(db *gorm.DB, notifSvc *notifService.NotificationService) *BookingHandler {
	return &BookingHandler{db: db, notifSvc: notifSvc}
}

func (h *BookingHandler) sendBookingNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	h.notifSvc.SendBookingConfirmation(booking)
}

func (h *BookingHandler) sendCancellationNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	customerNotif := notifService.SendNotificationInput{
		UserID: booking.CustomerID,
		Title:  "Booking Cancelled",
		Body:   "Your booking has been cancelled",
		Type:   models.NotifBookingCancelled,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
			"reason":     booking.CancellationReason,
		},
	}
	h.notifSvc.Send(customerNotif)

	var barber models.Barber
	h.db.First(&barber, booking.BarberID)
	barberNotif := notifService.SendNotificationInput{
		UserID: barber.UserID,
		Title:  "Booking Cancelled",
		Body:   "A booking has been cancelled",
		Type:   models.NotifBookingCancelled,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
		},
	}
	h.notifSvc.Send(barberNotif)
}

func (h *BookingHandler) sendStatusUpdateNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	title := "Booking Updated"
	switch booking.Status {
	case models.BookingStatusInProgress:
		title = "Service Started"
	case models.BookingStatusCompleted:
		title = "Service Completed"
	case models.BookingStatusNoShow:
		title = "Missed Appointment"
	}

	notif := notifService.SendNotificationInput{
		UserID: booking.CustomerID,
		Title:  title,
		Body:   "Your booking status: " + string(booking.Status),
		Type:   models.NotifBookingConfirmed,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
			"status":     booking.Status,
		},
	}
	h.notifSvc.Send(notif)
}

func (h *BookingHandler) sendModificationNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	notif := notifService.SendNotificationInput{
		UserID: booking.CustomerID,
		Title:  "Booking Modified",
		Body:   "Your booking services have been modified",
		Type:   models.NotifBookingModified,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
		},
	}
	h.notifSvc.Send(notif)
}

// (existing methods below)

type CreateBookingRequest struct {
	BarberID  uuid.UUID `json:"barber_id" binding:"required"`
	ServiceIDs []uuid.UUID `json:"service_ids" binding:"required,min=1,dive"`
	ScheduledStart time.Time `json:"scheduled_start" binding:"required"`
	CustomerNotes  string    `json:"customer_notes"`
	CouponCode     string    `json:"coupon_code,omitempty"`
}

func (h *BookingHandler) Create(c *gin.Context) {
	customerID := c.MustGet("user").(uuid.UUID)

	var req CreateBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	// Validate barber
	var barber models.Barber
	if err := h.db.First(&barber, req.BarberID).Error; err != nil {
		utils.BadRequestResponse(c, "Barber not found")
		return
	}

	if !barber.IsAvailable || barber.Status != models.BarberStatusActive {
		utils.BadRequestResponse(c, "Barber is not available")
		return
	}

	// Validate services and calculate totals
	var services []models.BarberService
	if err := h.db.Where("id IN ? AND barber_id = ? AND is_active = ?", req.ServiceIDs, req.BarberID, true).Find(&services).Error; err != nil {
		utils.BadRequestResponse(c, "Services not found")
		return
	}

	if len(services) == 0 {
		utils.BadRequestResponse(c, "No valid services found")
		return
	}

	var totalDuration int
	var totalPrice float64
	for _, svc := range services {
		totalDuration += svc.DurationMin
		totalPrice += svc.Price
	}

	// Calculate estimated wait time based on current queue
	var queueAhead int64
	h.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status IN ? AND (scheduled_start < ? OR (scheduled_start = ? AND created_at < ?))",
			req.BarberID,
			[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
			req.ScheduledStart, req.ScheduledStart, time.Now()).
		Count(&queueAhead)

	estimatedWait := int(queueAhead) * (barber.SlotDuration + barber.BufferBetweenSlots)

	// Calculate queue position
	queuePosition := int(queueAhead) + 1

	// Apply coupon if provided
	var discountAmount float64
	var coupon models.Coupon
	if req.CouponCode != "" {
		if err := h.db.Where("code = ? AND is_active = ? AND valid_from <= ? AND valid_to >= ?",
			req.CouponCode, true, time.Now(), time.Now()).First(&coupon).Error; err == nil {
			if coupon.UsedCount < coupon.UsageLimit || coupon.UsageLimit == 0 {
				if totalPrice >= coupon.MinOrderAmount {
					switch coupon.Type {
					case models.CouponTypePercentage:
						discountAmount = totalPrice * coupon.Value / 100
						if coupon.MaxDiscount > 0 && discountAmount > coupon.MaxDiscount {
							discountAmount = coupon.MaxDiscount
						}
					case models.CouponTypeFixed:
						discountAmount = coupon.Value
					}
				}
			}
		}
	}

	finalPrice := totalPrice - discountAmount
	if finalPrice < 0 {
		finalPrice = 0
	}

	// Check if slot is in past
	if req.ScheduledStart.Before(time.Now()) {
		utils.BadRequestResponse(c, "Cannot book in the past")
		return
	}

	tx := h.db.Begin()

	booking := models.Booking{
		BarberID:         req.BarberID,
		CustomerID:       customerID,
		Status:           models.BookingStatusPending,
		ScheduledStart:   req.ScheduledStart,
		ScheduledEnd:     req.ScheduledStart.Add(time.Duration(totalDuration) * time.Minute),
		QueuePosition:    queuePosition,
		EstimatedWaitMin: estimatedWait,
		TotalDuration:    totalDuration,
		TotalPrice:       totalPrice,
		DiscountAmount:   discountAmount,
		FinalPrice:       finalPrice,
		CustomerNotes:    req.CustomerNotes,
		Source:           "app",
	}

	if err := tx.Create(&booking).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to create booking")
		return
	}

	// Create booking services
	for _, svc := range services {
		bs := models.BookingService{
			BookingID:   booking.ID,
			ServiceID:   svc.ID,
			ServiceName: svc.Name,
			Quantity:    1,
			UnitPrice:   svc.Price,
			TotalPrice:  svc.Price,
			DurationMin: svc.DurationMin,
			AddedBy:     "customer",
		}
		if err := tx.Create(&bs).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to create booking services")
			return
		}
	}

	// Create status log
	tx.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		ToStatus:       models.BookingStatusPending,
		ChangedBy:      customerID,
		ChangedByRole:  "customer",
	})

	// Update barber's current queue length
	tx.Model(&barber).Update("current_queue_length", barber.CurrentQueueLength+1)

	// Update coupon usage
	if req.CouponCode != "" && discountAmount > 0 {
		tx.Model(&models.Coupon{}).Where("code = ?", req.CouponCode).Update("used_count", gorm.Expr("used_count + 1"))
		tx.Create(&models.CouponUsage{
			CouponID: coupon.ID,
			UserID:   customerID,
			OrderID:  uuid.Nil,
			Discount: discountAmount,
		})
	}

	tx.Commit()

	// Reload with relations
	h.db.Preload("Services").Preload("Barber").Preload("Customer").First(&booking, booking.ID)

	// Send notifications
	go h.sendBookingNotifications(&booking)

	utils.CreatedResponse(c, booking)
}

func (h *BookingHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.Preload("Services").Preload("Barber").Preload("Customer").Preload("StatusLog").First(&booking, id).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	utils.SuccessResponse(c, booking)
}

func (h *BookingHandler) Cancel(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, id).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	// Only customer, barber, or admin can cancel
	if booking.CustomerID != userID && claims.Role != string(models.RoleAdmin) && claims.Role != string(models.RoleSuperAdmin) {
		// Check if user is the barber
		var barber models.Barber
		if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil || barber.ID != booking.BarberID {
			utils.ForbiddenResponse(c, "Not authorized to cancel this booking")
			return
		}
	}

	if booking.Status == models.BookingStatusCompleted || booking.Status == models.BookingStatusCancelled {
		utils.BadRequestResponse(c, "Booking cannot be cancelled")
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&req)

	now := time.Now()
	originalStatus := booking.Status
	booking.Status = models.BookingStatusCancelled
	booking.CancellationReason = req.Reason
	booking.CancelledBy = &userID
	booking.CancelledAt = &now
	h.db.Save(&booking)

	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     originalStatus,
		ToStatus:       models.BookingStatusCancelled,
		ChangedBy:      userID,
		ChangedByRole:  claims.Role,
		Reason:         req.Reason,
	})

	// Reduce queue count
	h.db.Model(&models.Barber{}).Where("id = ?", booking.BarberID).Update("current_queue_length", gorm.Expr("GREATEST(current_queue_length - 1, 0)"))

	// Refund if paid
	if booking.PaymentStatus == "paid" || booking.PaymentStatus == "success" {
		go h.processRefund(&booking)
	}

	go h.sendCancellationNotifications(&booking)

	utils.SuccessResponse(c, gin.H{"message": "Booking cancelled"})
}

func (h *BookingHandler) UpdateStatus(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var req struct {
		Status string `json:"status" binding:"required,oneof=confirmed in_progress completed no_show"`
		Notes  string `json:"notes"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, id).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	fromStatus := booking.Status
	booking.Status = models.BookingStatus(req.Status)
	booking.BarberNotes = req.Notes

	now := time.Now()
	switch req.Status {
	case "in_progress":
		booking.ActualStart = &now
		h.db.Model(&models.Booking{}).Where("barber_id = ? AND status = ? AND id != ?", booking.BarberID, models.BookingStatusPending, booking.ID).
			Update("queue_position", gorm.Expr("queue_position - 1"))
	case "completed":
		booking.ActualEnd = &now
		booking.CompletedAt = &now
	}

	h.db.Save(&booking)

	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     fromStatus,
		ToStatus:       models.BookingStatus(req.Status),
		ChangedBy:      userID,
		ChangedByRole:  claims.Role,
		Reason:         req.Notes,
	})

	go h.sendStatusUpdateNotifications(&booking)

	utils.SuccessResponse(c, booking)
}

func (h *BookingHandler) ModifyServices(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.Preload("Services").First(&booking, id).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	// Only barber can modify services
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil || barber.ID != booking.BarberID {
		utils.ForbiddenResponse(c, "Only the barber can modify services")
		return
	}

	var req struct {
		AddServices    []uuid.UUID `json:"add_services"`
		RemoveServices []uuid.UUID `json:"remove_services"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	tx := h.db.Begin()

	// Add new services
	if len(req.AddServices) > 0 {
		var newServices []models.BarberService
		tx.Where("id IN ? AND barber_id = ? AND is_active = ?", req.AddServices, booking.BarberID, true).Find(&newServices)
		for _, svc := range newServices {
			bs := models.BookingService{
				BookingID:   booking.ID,
				ServiceID:   svc.ID,
				ServiceName: svc.Name,
				Quantity:    1,
				UnitPrice:   svc.Price,
				TotalPrice:  svc.Price,
				DurationMin: svc.DurationMin,
				AddedBy:     "barber",
				IsAddon:     true,
			}
			tx.Create(&bs)
			booking.TotalDuration += svc.DurationMin
			booking.TotalPrice += svc.Price
		}
	}

	// Remove services
	if len(req.RemoveServices) > 0 {
		tx.Where("booking_id = ? AND service_id IN ? AND added_by = ?", booking.ID, req.RemoveServices, "barber").Delete(&models.BookingService{})
	}

	// Recalculate
	if len(req.AddServices) > 0 {
		booking.FinalPrice = booking.TotalPrice - booking.DiscountAmount
		booking.ScheduledEnd = booking.ScheduledStart.Add(time.Duration(booking.TotalDuration) * time.Minute)
		tx.Save(&booking)
	}

	tx.Commit()

	h.db.Preload("Services").First(&booking, booking.ID)

	go h.sendModificationNotifications(&booking)

	utils.SuccessResponse(c, booking)
}

func (h *BookingHandler) ListCustomerBookings(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")

	var bookings []models.Booking
	var total int64

	query := h.db.Where("customer_id = ?", userID)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	query.Model(&models.Booking{}).Count(&total)
	query.Preload("Barber").Preload("Services").
		Offset((page - 1) * pageSize).Limit(pageSize).
		Order("scheduled_start DESC").Find(&bookings)

	utils.PaginatedResponse(c, bookings, page, pageSize, total)
}

func (h *BookingHandler) ListBarberBookings(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")
	date := c.Query("date")

	var bookings []models.Booking
	var total int64

	query := h.db.Where("barber_id = ?", barber.ID)
	if status != "" {
		query = query.Where("status = ?", status)
	}
	if date != "" {
		query = query.Where("DATE(scheduled_start) = DATE(?)", date)
	}

	query.Model(&models.Booking{}).Count(&total)
	query.Preload("Customer").Preload("Services").
		Offset((page-1)*pageSize).Limit(pageSize).
		Order("scheduled_start ASC").Find(&bookings)

	utils.PaginatedResponse(c, bookings, page, pageSize, total)
}

func (h *BookingHandler) GetQueue(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var bookings []models.Booking
	h.db.Where("barber_id = ? AND status IN ? AND scheduled_start >= ?",
		barber.ID,
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		time.Now()).
		Order("queue_position ASC, scheduled_start ASC").
		Find(&bookings)

	utils.SuccessResponse(c, bookings)
}

func (h *BookingHandler) GetMyQueuePosition(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	bookingID, err := uuid.Parse(c.Param("booking_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, bookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	if booking.CustomerID != userID {
		utils.ForbiddenResponse(c, "Not your booking")
		return
	}

	// Calculate current queue position & wait time
	var aheadCount int64
	h.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status IN ? AND (queue_position < ? OR (queue_position = ? AND created_at < ?)) AND id != ?",
			booking.BarberID,
			[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
			booking.QueuePosition, booking.QueuePosition, booking.CreatedAt, booking.ID).
		Count(&aheadCount)

	var barber models.Barber
	h.db.First(&barber, booking.BarberID)

	currentWait := int(aheadCount) * (barber.SlotDuration + barber.BufferBetweenSlots)

	utils.SuccessResponse(c, gin.H{
		"booking_id":            booking.ID,
		"current_position":      aheadCount + 1,
		"people_ahead":          aheadCount,
		"estimated_wait_min":    currentWait,
		"status":                booking.Status,
		"scheduled_start":       booking.ScheduledStart,
	})
}

func (h *BookingHandler) processRefund(booking *models.Booking) {
	var payment models.Payment
	if err := h.db.Where("order_id = ?", booking.ID).First(&payment).Error; err != nil {
		// No payment record found, just create refund request
		refund := models.RefundRequest{
			OrderID:     booking.ID,
			CustomerID:  booking.CustomerID,
			Reason:      "Booking cancelled",
			RefundType:  "full",
			RefundAmount: booking.FinalPrice,
			Status:      "approved",
		}
		h.db.Create(&refund)
		return
	}

	now := time.Now()
	refund := models.RefundRequest{
		OrderID:     booking.ID,
		CustomerID:  booking.CustomerID,
		Reason:      "Booking cancelled",
		RefundType:  "full",
		RefundAmount: booking.FinalPrice,
		Status:      "approved",
		ProcessedAt: &now,
	}
	h.db.Create(&refund)

	payment.RefundAmount = booking.FinalPrice
	payment.RefundStatus = "approved"
	payment.RefundedAt = &now
	h.db.Save(&payment)

	h.db.Model(booking).Update("payment_status", "refunded")
}
