package booking

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/barbar-app/backend/internal/services/queue"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BookingHandler struct {
	db       *gorm.DB
	notifSvc notifService.Dispatcher
	hub      *websocket.Hub
}

func NewBookingHandler(db *gorm.DB, dispatcher notifService.Dispatcher, hub *websocket.Hub) *BookingHandler {
	return &BookingHandler{db: db, notifSvc: dispatcher, hub: hub}
}

func (h *BookingHandler) refreshQueue(barberID uuid.UUID) {
	qSvc := queue.NewQueueService(h.db, h.hub, h.notifSvc)
	qSvc.RecalculatePositions(barberID)
	qSvc.RecalculateWaitTimes(barberID)
	qSvc.BroadcastQueueUpdate(barberID)
}

func (h *BookingHandler) sendBookingNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}

	// Notify barber of new booking request
	var barber models.Barber
	h.db.First(&barber, booking.BarberID)
	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifBookingRequest,
		ReceiverID: barber.UserID,
		Role:       notifService.RoleBarber,
		Data:       map[string]interface{}{"booking_id": booking.ID.String()},
	})

	// Notify customer that their booking request was submitted
	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifBookingRequest,
		ReceiverID: booking.CustomerID,
		Role:       notifService.RoleCustomer,
		Data:       map[string]interface{}{"booking_id": booking.ID.String()},
	})
}

func (h *BookingHandler) sendCancellationNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	// Customer notification
	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifBookingCancelled,
		ReceiverID: booking.CustomerID,
		Role:       notifService.RoleCustomer,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
			"reason":     booking.CancellationReason,
		},
	})

	// Barber notification
	var barber models.Barber
	h.db.First(&barber, booking.BarberID)
	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifBookingCancelled,
		ReceiverID: barber.UserID,
		Role:       notifService.RoleBarber,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
		},
	})
}

func (h *BookingHandler) sendStatusUpdateNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	
	notifType := models.NotifBookingConfirmed
	switch booking.Status {
	case models.BookingStatusInProgress:
		notifType = models.NotifBarberStarted
	case models.BookingStatusCompleted:
		notifType = models.NotifBarberCompleted
	case models.BookingStatusNoShow:
		notifType = models.NotifBookingRejected // Or a separate NoShow type
	}

	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       notifType,
		ReceiverID: booking.CustomerID,
		Role:       notifService.RoleCustomer,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
			"status":     booking.Status,
		},
	})
}

func (h *BookingHandler) sendModificationNotifications(booking *models.Booking) {
	if h.notifSvc == nil {
		return
	}
	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifBookingModified,
		ReceiverID: booking.CustomerID,
		Role:       notifService.RoleCustomer,
		Data: map[string]interface{}{
			"booking_id": booking.ID.String(),
		},
	})
}

// (existing methods below)

type CreateBookingRequest struct {
	BarberID             uuid.UUID   `json:"barber_id" binding:"required"`
	ServiceIDs           []uuid.UUID `json:"service_ids" binding:"required,min=1,dive"`
	ScheduledStart       time.Time   `json:"scheduled_start" binding:"required"`
	CustomerNotes        string      `json:"customer_notes"`
	CouponCode           string      `json:"coupon_code,omitempty"`
	IsHomeService        bool        `json:"is_home_service"`
	HomeServiceAddressID *uuid.UUID  `json:"home_service_address_id,omitempty"`
	StaffID              *uuid.UUID  `json:"staff_id,omitempty"`
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

	// Home service validation
	var homeServiceAddress *models.Address
	if req.IsHomeService {
		if !barber.IsHomeServiceAvailable {
			utils.BadRequestResponse(c, "Barber does not offer home service")
			return
		}
		if req.HomeServiceAddressID == nil {
			utils.BadRequestResponse(c, "Home service address is required")
			return
		}
		var addr models.Address
		if err := h.db.Where("id = ? AND user_id = ?", *req.HomeServiceAddressID, customerID).First(&addr).Error; err != nil {
			utils.BadRequestResponse(c, "Address not found or does not belong to you")
			return
		}
		homeServiceAddress = &addr
	}

	// Validate working hours
	tStr := req.ScheduledStart.Format("15:04")
	if barber.StartTime != "" && barber.EndTime != "" {
		if tStr < barber.StartTime || tStr >= barber.EndTime {
			utils.BadRequestResponse(c, "Booking time must be within working hours ("+barber.StartTime+" - "+barber.EndTime+")")
			return
		}
	}

	// Validate break hours
	if barber.BreakStartTime != "" && barber.BreakEndTime != "" {
		if tStr >= barber.BreakStartTime && tStr < barber.BreakEndTime {
			utils.BadRequestResponse(c, "Booking time cannot be during break hours ("+barber.BreakStartTime+" - "+barber.BreakEndTime+")")
			return
		}
	}

	// Validate queue capacity
	if barber.CurrentQueueLength >= barber.MaxQueueSize {
		utils.BadRequestResponse(c, "Queue is full")
		return
	}

	// Validate duplicate booking by same customer
	var customerDuplicate int64
	h.db.Model(&models.Booking{}).Where("customer_id = ? AND scheduled_start = ? AND status IN ?", customerID, req.ScheduledStart, []models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress}).Count(&customerDuplicate)
	if customerDuplicate > 0 {
		utils.BadRequestResponse(c, "You already have a booking at this time")
		return
	}

	// Assign staff and calculate queue/wait times
	assignment, err := h.findBestStaff(barber, req.StaffID, req.ServiceIDs, req.ScheduledStart, req.IsHomeService)
	if err != nil {
		utils.BadRequestResponse(c, err.Error())
		return
	}

	totalDuration := assignment.TotalDuration
	totalPrice := assignment.TotalPrice
	queuePosition := assignment.QueuePosition
	estimatedWait := assignment.EstimatedWaitMin
	services := assignment.Services
	assignedStaffID := assignment.StaffID

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

	// Calculate home service distance & travel charge
	var travelDistance float64
	var travelCharge float64
	if req.IsHomeService && homeServiceAddress != nil {
		travelDistance = haversineKm(
			barber.Latitude, barber.Longitude,
			homeServiceAddress.Latitude, homeServiceAddress.Longitude,
		)
		if barber.ServiceRadiusKm > 0 && travelDistance > barber.ServiceRadiusKm {
			utils.BadRequestResponse(c, fmt.Sprintf("Address is %.1f km away, exceeds barber's service radius of %.1f km", travelDistance, barber.ServiceRadiusKm))
			return
		}
		travelCharge = barber.BaseTravelCharge + (travelDistance * barber.TravelChargePerKm)
	}

	travelTimeMin := 0
	if req.IsHomeService {
		travelTimeMin = int(travelDistance*2 + 5) // roughly 2 mins per km + 5 min buffer
	}

	finalPrice := totalPrice - discountAmount + travelCharge
	if finalPrice < 0 {
		finalPrice = 0
	}

	// Check if slot is in past
	if req.ScheduledStart.Before(time.Now()) {
		utils.BadRequestResponse(c, "Cannot book in the past")
		return
	}

	tx := h.db.Begin()

	// Advisory lock: prevent concurrent double-booking even when no rows exist yet
	lockKey := fmt.Sprintf("%s@%s", req.BarberID.String(), req.ScheduledStart.Format("2006-01-02T15:04:05"))
	if err := tx.Exec("SELECT pg_advisory_xact_lock(hashtext(?)::bigint)", lockKey).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to acquire slot lock, try again")
		return
	}

	// Row lock slot double booking check
	var doubleBookingCount int64
	tx.Set("gorm:query_option", "FOR UPDATE").
		Model(&models.Booking{}).
		Where("barber_id = ? AND scheduled_start = ? AND status IN ?",
			req.BarberID,
			req.ScheduledStart,
			[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		).
		Count(&doubleBookingCount)

	if doubleBookingCount > 0 {
		tx.Rollback()
		utils.BadRequestResponse(c, "Slot already booked")
		return
	}

	bookingStatus := models.BookingStatusPending
	if req.IsHomeService {
		bookingStatus = models.BookingStatusHomeServicePending
	}
	booking := models.Booking{
		BarberID:         req.BarberID,
		StaffID:          &assignedStaffID,
		CustomerID:       customerID,
		Status:           bookingStatus,
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
		IsHomeService:    req.IsHomeService,
		TravelDistanceKm: travelDistance,
		TravelTimeMin:    travelTimeMin,
		TravelCharge:     travelCharge,
	}
	if req.IsHomeService && homeServiceAddress != nil {
		booking.HomeServiceAddressID = &homeServiceAddress.ID
		addrBytes, _ := json.Marshal(homeServiceAddress)
		booking.HomeServiceAddress = string(addrBytes)
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
		ToStatus:       bookingStatus,
		ChangedBy:      customerID,
		ChangedByRole:  "customer",
	})

	// Update barber's current queue length (shop bookings only)
	if !req.IsHomeService {
		tx.Model(&barber).Update("current_queue_length", barber.CurrentQueueLength+1)
	}

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

	h.refreshQueue(booking.BarberID)

	// Reload with relations
	h.db.Preload("Services").Preload("Staff").Preload("Barber").Preload("Customer").First(&booking, booking.ID)

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

	if booking.Status != models.BookingStatusPending && booking.Status != models.BookingStatusConfirmed && booking.Status != models.BookingStatusHomeServicePending {
		utils.BadRequestResponse(c, "Booking cannot be cancelled from status: "+string(booking.Status))
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

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

	// Reduce queue count (not for home service pending — never queued)
	if originalStatus != models.BookingStatusHomeServicePending {
		h.db.Model(&models.Barber{}).Where("id = ?", booking.BarberID).Update("current_queue_length", gorm.Expr("GREATEST(current_queue_length - 1, 0)"))
	}

	// Recalculate queue positions, wait times and broadcast WebSocket updates
	h.refreshQueue(booking.BarberID)

	// Refund if paid
	if booking.PaymentStatus == "paid" {
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
	toStatus := models.BookingStatus(req.Status)

	// Validate status transition
	allowed := false
	switch fromStatus {
	case models.BookingStatusPending:
		if toStatus == models.BookingStatusConfirmed || toStatus == models.BookingStatusCancelled {
			allowed = true
		}
	case models.BookingStatusConfirmed:
		if toStatus == models.BookingStatusInProgress || toStatus == models.BookingStatusCancelled || toStatus == models.BookingStatusNoShow {
			allowed = true
		}
	case models.BookingStatusInProgress:
		if toStatus == models.BookingStatusCompleted {
			allowed = true
		}
	}

	if !allowed {
		utils.BadRequestResponse(c, "Invalid booking status transition from "+string(fromStatus)+" to "+string(toStatus))
		return
	}

	// Prevent staff member from having multiple active (in progress) services
	if toStatus == models.BookingStatusInProgress {
		var activeCount int64
		if booking.StaffID != nil {
			h.db.Model(&models.Booking{}).Where("staff_id = ? AND status = ? AND id != ?", booking.StaffID, models.BookingStatusInProgress, booking.ID).Count(&activeCount)
		} else {
			h.db.Model(&models.Booking{}).Where("barber_id = ? AND staff_id IS NULL AND status = ? AND id != ?", booking.BarberID, models.BookingStatusInProgress, booking.ID).Count(&activeCount)
		}
		if activeCount > 0 {
			utils.BadRequestResponse(c, "Cannot start service: staff member is already serving another client")
			return
		}
	}

	booking.Status = toStatus
	booking.BarberNotes = req.Notes

	now := time.Now()
	switch req.Status {
	case "in_progress":
		booking.ActualStart = &now
	case "completed":
		booking.ActualEnd = &now
		booking.CompletedAt = &now
		h.db.Model(&models.Barber{}).Where("id = ?", booking.BarberID).Update("current_queue_length", gorm.Expr("GREATEST(current_queue_length - 1, 0)"))
	case "no_show":
		h.db.Model(&models.Barber{}).Where("id = ?", booking.BarberID).Update("current_queue_length", gorm.Expr("GREATEST(current_queue_length - 1, 0)"))
	}

	h.db.Save(&booking)

	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     fromStatus,
		ToStatus:       toStatus,
		ChangedBy:      userID,
		ChangedByRole:  claims.Role,
		Reason:         req.Notes,
	})

	// Recalculate queue positions, wait times and broadcast WebSocket updates
	h.refreshQueue(booking.BarberID)

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
	query.Preload("Barber").Preload("Staff").Preload("Services").
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
	query.Preload("Customer").Preload("Staff").Preload("Services").
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
	h.db.Preload("Staff").Preload("Services").
		Where("barber_id = ? AND status IN ? AND scheduled_start >= ?",
		barber.ID,
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		time.Now()).
		Order("staff_id ASC, queue_position ASC, scheduled_start ASC").
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
	todayStart := time.Date(time.Now().Year(), time.Now().Month(), time.Now().Day(), 0, 0, 0, 0, time.Now().Location())
	todayEnd := todayStart.Add(24 * time.Hour)

	var aheadBookings []models.Booking
	h.db.Where("staff_id = ? AND status IN ? AND scheduled_start >= ? AND scheduled_start < ? AND (queue_position < ? OR (queue_position = ? AND created_at < ?)) AND id != ?",
		booking.StaffID,
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		todayStart, todayEnd,
		booking.QueuePosition, booking.QueuePosition, booking.CreatedAt, booking.ID).
		Order("queue_position ASC, scheduled_start ASC").
		Find(&aheadBookings)

	var barber models.Barber
	h.db.First(&barber, booking.BarberID)

	currentWait := 0
	for _, ab := range aheadBookings {
		duration := ab.TotalDuration
		if duration <= 0 {
			duration = barber.SlotDuration
		}
		
		if ab.Status == models.BookingStatusInProgress {
			start := ab.CreatedAt
			if ab.ActualStart != nil {
				start = *ab.ActualStart
			} else if !ab.ScheduledStart.IsZero() {
				start = ab.ScheduledStart
			}
			elapsed := int(time.Since(start).Minutes())
			remaining := duration - elapsed
			if remaining < 0 {
				remaining = 0
			}
			currentWait += remaining + barber.BufferBetweenSlots
		} else {
			currentWait += duration + barber.BufferBetweenSlots
		}
	}

	utils.SuccessResponse(c, gin.H{
		"booking_id":            booking.ID,
		"current_position":      len(aheadBookings) + 1,
		"people_ahead":          len(aheadBookings),
		"estimated_wait_min":    currentWait,
		"status":                booking.Status,
		"scheduled_start":       booking.ScheduledStart,
	})
}

type ReorderQueueRequest struct {
	BookingIDs []uuid.UUID `json:"booking_ids" binding:"required,min=1"`
}

func (h *BookingHandler) ReorderQueue(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var req ReorderQueueRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	tx := h.db.Begin()

	for i, id := range req.BookingIDs {
		result := tx.Model(&models.Booking{}).
			Where("id = ? AND barber_id = ? AND status IN ?",
				id,
				barber.ID,
				[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
			).
			Update("queue_position", i+1)

		if result.Error != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to update queue position")
			return
		}
	}

	tx.Commit()

	qSvc := queue.NewQueueService(h.db, h.hub, h.notifSvc)
	qSvc.RecalculateWaitTimes(barber.ID)
	qSvc.BroadcastQueueUpdate(barber.ID)

	utils.SuccessResponse(c, gin.H{"message": "Queue reordered successfully"})
}

func (h *BookingHandler) ListHomeServiceRequests(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	page, pageSize := utils.GetPageParams(c)
	var bookings []models.Booking
	var total int64

	query := h.db.Where("barber_id = ? AND status = ?", barber.ID, models.BookingStatusHomeServicePending)
	query.Model(&models.Booking{}).Count(&total)
	query.Preload("Customer").Preload("Services").
		Offset((page - 1) * pageSize).Limit(pageSize).
		Order("created_at DESC").Find(&bookings)

	utils.PaginatedResponse(c, bookings, page, pageSize, total)
}

func (h *BookingHandler) AcceptHomeService(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	bookingID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.Preload("Services").First(&booking, bookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	if booking.BarberID != barber.ID {
		utils.ForbiddenResponse(c, "This booking does not belong to you")
		return
	}

	if booking.Status != models.BookingStatusHomeServicePending {
		utils.BadRequestResponse(c, "Booking is not in home service pending status")
		return
	}

	if !booking.IsHomeService {
		utils.BadRequestResponse(c, "Booking is not a home service booking")
		return
	}

	// Travel buffer check — accounts for travel_to/travel_back of all bookings
	travelTimeMin := booking.TravelTimeMin
	if travelTimeMin <= 0 {
		travelTimeMin = int(booking.TravelDistanceKm*2 + 5)
	}
	newBlockedStart := booking.ScheduledStart.Add(-time.Duration(travelTimeMin) * time.Minute)
	newBlockedEnd := booking.ScheduledStart.Add(time.Duration(booking.TotalDuration+travelTimeMin) * time.Minute)

	var existing []models.Booking
	h.db.Where("barber_id = ? AND id != ? AND status IN ?",
		barber.ID, booking.ID,
		[]models.BookingStatus{models.BookingStatusConfirmed, models.BookingStatusInProgress},
	).Find(&existing)

	for _, eb := range existing {
		ebStart := eb.ScheduledStart
		ebEnd := eb.ScheduledEnd
		if eb.IsHomeService {
			ebTravel := eb.TravelTimeMin
			if ebTravel <= 0 {
				ebTravel = int(eb.TravelDistanceKm*2 + 5)
			}
			ebStart = eb.ScheduledStart.Add(-time.Duration(ebTravel) * time.Minute)
			ebEnd = eb.ScheduledEnd.Add(time.Duration(ebTravel) * time.Minute)
		}
		if ebStart.Before(newBlockedEnd) && ebEnd.After(newBlockedStart) {
			utils.BadRequestResponse(c, "Cannot accept: time conflicts with existing bookings (travel buffer overlap)")
			return
		}
	}

	// Calculate queue position
	var aheadBookings []models.Booking
	h.db.Where("barber_id = ? AND status IN ? AND (scheduled_start < ? OR (scheduled_start = ? AND created_at < ?))",
		barber.ID,
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
		booking.ScheduledStart, booking.ScheduledStart, booking.CreatedAt).
		Order("queue_position ASC, scheduled_start ASC").
		Find(&aheadBookings)

	queuePosition := len(aheadBookings) + 1

	estimatedWait := 0
	for _, ab := range aheadBookings {
		duration := ab.TotalDuration
		if duration <= 0 {
			duration = barber.SlotDuration
		}
		if ab.Status == models.BookingStatusInProgress {
			start := ab.CreatedAt
			if ab.ActualStart != nil {
				start = *ab.ActualStart
			} else if !ab.ScheduledStart.IsZero() {
				start = ab.ScheduledStart
			}
			elapsed := int(time.Since(start).Minutes())
			remaining := duration - elapsed
			if remaining < 0 {
				remaining = 0
			}
			estimatedWait += remaining + barber.BufferBetweenSlots
		} else {
			estimatedWait += duration + barber.BufferBetweenSlots
		}
	}

	estimatedWait += travelTimeMin

	tx := h.db.Begin()

	oldStatus := booking.Status
	booking.Status = models.BookingStatusConfirmed
	booking.QueuePosition = queuePosition
	booking.EstimatedWaitMin = estimatedWait

	if err := tx.Save(&booking).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to accept booking")
		return
	}

	tx.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     oldStatus,
		ToStatus:       models.BookingStatusConfirmed,
		ChangedBy:      userID,
		ChangedByRole:  "barber",
	})

	tx.Model(&barber).Update("current_queue_length", barber.CurrentQueueLength+1)

	tx.Commit()

	h.refreshQueue(barber.ID)

	go h.sendBookingNotifications(&booking)

	utils.SuccessResponse(c, booking)
}

func (h *BookingHandler) RejectHomeService(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	bookingID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, bookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	if booking.BarberID != barber.ID {
		utils.ForbiddenResponse(c, "This booking does not belong to you")
		return
	}

	if booking.Status != models.BookingStatusHomeServicePending {
		utils.BadRequestResponse(c, "Booking is not in home service pending status")
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	now := time.Now()
	oldStatus := booking.Status
	booking.Status = models.BookingStatusCancelled
	booking.CancellationReason = req.Reason
	booking.CancelledBy = &userID
	booking.CancelledAt = &now
	h.db.Save(&booking)

	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     oldStatus,
		ToStatus:       models.BookingStatusCancelled,
		ChangedBy:      userID,
		ChangedByRole:  "barber",
		Reason:         req.Reason,
	})

	go h.sendCancellationNotifications(&booking)

	utils.SuccessResponse(c, gin.H{"message": "Home service request rejected"})
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

	h.db.Model(&models.Booking{}).Where("id = ?", booking.ID).Update("payment_status", "refunded")
}

type PayBookingRequest struct {
	Method    string `json:"method" binding:"required,oneof=cash upi card wallet"`
	Status    string `json:"status" binding:"required,oneof=pending paid"`
	Reference string `json:"reference"`
}

func (h *BookingHandler) PayBooking(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid booking ID")
		return
	}

	var req PayBookingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	// Reject direct UPI/Card/Wallet payment attempts from this endpoint
	// Online payments must go through POST /api/v1/payments/initiate
	if req.Method != "cash" && req.Status == "paid" {
		utils.BadRequestResponse(c, "Online payments must be processed via the payment gateway endpoint")
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, id).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	// Verify that the user is the customer or the barber of this booking
	var barber models.Barber
	isBarber := false
	if h.db.Where("user_id = ?", userID).First(&barber).Error == nil {
		if barber.ID == booking.BarberID {
			isBarber = true
		}
	}

	if booking.CustomerID != userID && !isBarber {
		utils.ForbiddenResponse(c, "Not authorized to pay for this booking")
		return
	}

	// Security: Only barber can mark cash as paid.
	if req.Status == "paid" {
		if req.Method != "cash" {
			utils.BadRequestResponse(c, "Only cash payments can be marked as paid directly")
			return
		}
		if !isBarber {
			utils.ForbiddenResponse(c, "Only the barber can mark cash as paid")
			return
		}
	}

	now := time.Now()
	booking.PaymentMethod = req.Method

	if req.Status == "paid" {
		booking.PaymentStatus = "paid"
		booking.PaymentID = req.Method + ":" + req.Reference
	}

	if err := h.db.Save(&booking).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update booking payment info")
		return
	}

	// Create Payment record only for confirmed payments (status == "paid")
	if req.Status == "paid" {
		payment := models.Payment{
			OrderID:       booking.ID,
			UserID:        booking.CustomerID,
			Amount:        booking.FinalPrice,
			Gateway:       models.GatewayCash,
			Currency:      "INR",
			Status:        models.PayStatusSuccess,
			PaymentMethod: req.Method,
		}
		payment.PaidAt = &now
		h.db.Create(&payment)
	}

	// Log payment event
	h.db.Create(&models.BookingStatusLog{
		BookingID:      booking.ID,
		FromStatus:     booking.Status,
		ToStatus:       booking.Status,
		ChangedBy:      userID,
		ChangedByRole:  claims.Role,
		Reason:         "Payment " + req.Status + " via " + req.Method + " by " + claims.Role,
	})

	// Send payment notifications
	if h.notifSvc != nil {
		if req.Method == "cash" && req.Status == "pending" {
			// Customer selected cash → notify the barber
			var barberRecord models.Barber
			if h.db.First(&barberRecord, booking.BarberID).Error == nil {
				h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
					Type:       models.NotifPaymentSuccess,
					ReceiverID: barberRecord.UserID,
					Role:       notifService.RoleBarber,
					Data: map[string]interface{}{
						"booking_id": booking.ID.String(),
						"method":     "cash",
						"status":     "pending",
						"amount":     booking.FinalPrice,
						"message":    "Customer opted for cash payment",
					},
				})
			}
		}
		if req.Status == "paid" {
			// Barber confirmed cash received → notify the customer
			h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
				Type:       models.NotifPaymentSuccess,
				ReceiverID: booking.CustomerID,
				Role:       notifService.RoleCustomer,
				Data: map[string]interface{}{
					"booking_id": booking.ID.String(),
					"method":     req.Method,
					"status":     "paid",
					"amount":     booking.FinalPrice,
				},
			})
		}
	}

	utils.SuccessResponse(c, booking)
}

// haversineKm calculates the distance in km between two lat/lng points
func haversineKm(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}

// ListAvailableStaff returns available staff for a barber at a given time slot
func (h *BookingHandler) ListAvailableStaff(c *gin.Context) {
	barberID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid barber ID")
		return
	}

	dateStr := c.Query("date")
	timeStr := c.Query("time")
	serviceIDsStr := c.Query("service_ids")

	if dateStr == "" || timeStr == "" {
		utils.BadRequestResponse(c, "date and time query parameters are required")
		return
	}

	scheduledStart, err := time.Parse("2006-01-02 15:04", dateStr+" "+timeStr)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid date or time format (use YYYY-MM-DD and HH:MM)")
		return
	}

	var barber models.Barber
	if err := h.db.First(&barber, barberID).Error; err != nil {
		utils.NotFoundResponse(c, "Barber not found")
		return
	}

	// Parse service IDs if provided
	var serviceIDs []uuid.UUID
	if serviceIDsStr != "" {
		for _, s := range strings.Split(serviceIDsStr, ",") {
			id, err := uuid.Parse(strings.TrimSpace(s))
			if err == nil {
				serviceIDs = append(serviceIDs, id)
			}
		}
	}

	// Fetch active staff with their services
	var staffList []models.BarberStaff
	h.db.Preload("Services.Service").Where("barber_id = ? AND is_active = ?", barberID, true).Find(&staffList)

	tStr := scheduledStart.Format("15:04")
	dayOfWeek := int(scheduledStart.Weekday())

	type StaffAvailability struct {
		StaffID     uuid.UUID `json:"staff_id"`
		Name        string    `json:"name"`
		Image       string    `json:"image,omitempty"`
		Role        string    `json:"role"`
		Rating      float64   `json:"rating"`
		ReviewCount int       `json:"review_count"`
		Available   bool      `json:"available"`
		Reason      string    `json:"reason,omitempty"`
	}

	var results []StaffAvailability

	for _, staff := range staffList {
		result := StaffAvailability{
			StaffID:     staff.ID,
			Name:        staff.Name,
			Image:       staff.Image,
			Role:        string(staff.Role),
			Rating:      staff.Rating,
			ReviewCount: staff.ReviewCount,
			Available:   true,
		}

		// Check day off
		if staff.DayOff == dayOfWeek {
			result.Available = false
			result.Reason = "Staff is off today"
			results = append(results, result)
			continue
		}

		// Check working hours
		startTime := staff.StartTime
		endTime := staff.EndTime
		if startTime == "" || endTime == "" {
			startTime = barber.StartTime
			endTime = barber.EndTime
		}
		if startTime != "" && endTime != "" {
			if tStr < startTime || tStr >= endTime {
				result.Available = false
				result.Reason = "Outside working hours"
				results = append(results, result)
				continue
			}
		}

		// Check service capability
		if len(serviceIDs) > 0 {
			staffServiceMap := make(map[uuid.UUID]bool)
			for _, ss := range staff.Services {
				if ss.IsActive {
					staffServiceMap[ss.ServiceID] = true
				}
			}
			canPerformAll := true
			for _, sid := range serviceIDs {
				if !staffServiceMap[sid] {
					canPerformAll = false
					break
				}
			}
			if !canPerformAll {
				result.Available = false
				result.Reason = "Cannot perform requested services"
				results = append(results, result)
				continue
			}
		}

		// Check queue capacity — count active bookings for this staff
		var activeCount int64
		h.db.Model(&models.Booking{}).Where("staff_id = ? AND status IN ? AND scheduled_start >= ?",
			staff.ID,
			[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
			scheduledStart,
		).Count(&activeCount)

		if activeCount >= int64(barber.MaxQueueSize) {
			result.Available = false
			result.Reason = "Staff queue is full"
		}

		results = append(results, result)
	}

	utils.SuccessResponse(c, results)
}
