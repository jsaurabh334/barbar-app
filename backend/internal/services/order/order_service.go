package order

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"
	"os"
	"time"

	"github.com/barbar-app/backend/internal/models"
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

var otpPepper = func() string {
	if p := os.Getenv("OTP_PEPPER"); p != "" {
		return p
	}
	return "barbar-otp-pepper-v1"
}()

var AllowedTransitions = map[models.OrderStatus][]models.OrderStatus{
	models.OrderStatusPending:          {models.OrderStatusAccepted, models.OrderStatusCancelled},
	models.OrderStatusAccepted:         {models.OrderStatusPacked, models.OrderStatusCancelled},
	models.OrderStatusPacked:           {models.OrderStatusReadyForPickup},
	models.OrderStatusReadyForPickup:   {models.OrderStatusDriverAssigned},
	models.OrderStatusDriverAssigned:   {models.OrderStatusDriverAccepted, models.OrderStatusReadyForPickup},
	models.OrderStatusDriverAccepted:   {models.OrderStatusPickedUp},
	models.OrderStatusPickedUp:         {models.OrderStatusOutForDelivery},
	models.OrderStatusOutForDelivery:   {models.OrderStatusDelivered},
	models.OrderStatusDelivered:        {models.OrderStatusReturnRequested},
}

type OrderService struct {
	db         *gorm.DB
	dispatcher notification.Dispatcher
	wsHub      *websocket.Hub
	presenceSvc *deliverySvc.PresenceService
}

func NewOrderService(db *gorm.DB, dispatcher notification.Dispatcher, wsHub *websocket.Hub, presenceSvc *deliverySvc.PresenceService) *OrderService {
	return &OrderService{
		db:          db,
		dispatcher:  dispatcher,
		wsHub:       wsHub,
		presenceSvc: presenceSvc,
	}
}

func (s *OrderService) ValidateTransition(from, to models.OrderStatus) bool {
	allowed, ok := AllowedTransitions[from]
	if !ok {
		return false
	}
	for _, st := range allowed {
		if st == to {
			return true
		}
	}
	return false
}

func (s *OrderService) TransitionOrder(ctx context.Context, orderID, userID uuid.UUID, role string, newStatus models.OrderStatus, note string) (*models.Order, error) {
	var order models.Order
	if err := s.db.First(&order, orderID).Error; err != nil {
		return nil, fmt.Errorf("order not found")
	}

	if !s.ValidateTransition(order.Status, newStatus) {
		return nil, fmt.Errorf("invalid transition from %s to %s", order.Status, newStatus)
	}

	fromStatus := order.Status
	now := time.Now()

	switch newStatus {
	case models.OrderStatusCancelled:
		order.CancelledAt = &now
		order.CancellationReason = note
	case models.OrderStatusDelivered:
		order.DeliveredAt = &now
		s.db.Transaction(func(tx *gorm.DB) error {
			tx.Create(&models.CommissionTransaction{
				OrderID:          order.ID,
				VendorID:         order.VendorID,
				OrderAmount:      order.FinalAmount,
				CommissionRate:   order.CommissionAmount / order.FinalAmount,
				CommissionAmount: order.CommissionAmount,
				PlatformFee:      order.PlatformFee,
				NetAmount:        order.VendorEarnings,
				Status:           "settled",
			})
			var wallet models.Wallet
			if err := tx.Where("vendor_id = ?", order.VendorID).First(&wallet).Error; err == nil {
				tx.Model(&wallet).Update("balance", gorm.Expr("balance + ?", order.VendorEarnings))
				tx.Create(&models.WalletTransaction{
					WalletID:      wallet.ID,
					TxnType:       models.TxnTypeCredit,
					Amount:        order.VendorEarnings,
					ReferenceType: models.TxnRefOrder,
					ReferenceID:   order.OrderNumber,
					Description:   "Earnings from order " + order.OrderNumber,
					TxnDate:       now,
				})
			}
			if order.DeliveryPartnerID != nil {
				deliveryBase := order.ShippingCharge
				if deliveryBase == 0 {
					deliveryBase = 30.0
				}
				tx.Create(&models.DeliveryEarning{
					DeliveryPartnerID: *order.DeliveryPartnerID,
					OrderID:           order.ID,
					BaseAmount:        deliveryBase,
					TotalAmount:       deliveryBase,
					Status:            models.EarningStatusPending,
					Description:       "Delivery fee for order " + order.OrderNumber,
				})
				var dwallet models.Wallet
				if err := tx.Where("user_id = ?", order.DeliveryPartnerID).First(&dwallet).Error; err == nil {
					tx.Model(&dwallet).Update("balance", gorm.Expr("balance + ?", deliveryBase))
					tx.Create(&models.WalletTransaction{
						WalletID:      dwallet.ID,
						TxnType:       models.TxnTypeCredit,
						Amount:        deliveryBase,
						ReferenceType: models.TxnRefDeliveryEarning,
						ReferenceID:   order.OrderNumber,
						Description:   "Delivery earnings for order " + order.OrderNumber,
						TxnDate:       now,
					})
				}
			}
			return nil
		})
		go s.generateInvoice(&order)
	case models.OrderStatusDriverAssigned:
		order.DeliveryPartnerID = &userID
		order.AssignedAt = &now
		s.db.Create(&models.OrderDeliveryAssignment{
			OrderID:        order.ID,
			DeliveryUserID: userID,
			AssignedAt:     now,
			ExpiresAt:      now.Add(5 * time.Minute),
			Status:         models.AssignmentPending,
		})
	case models.OrderStatusDriverAccepted:
		if order.DeliveryPartnerID != nil {
			var assignment models.OrderDeliveryAssignment
			if err := s.db.Where("order_id = ? AND delivery_user_id = ? AND status = ?",
				order.ID, *order.DeliveryPartnerID, models.AssignmentPending).
				Order("created_at DESC").First(&assignment).Error; err == nil {
				s.db.Model(&assignment).Updates(map[string]interface{}{
					"status":      models.AssignmentAccepted,
					"accepted_at": now,
				})
			}
		}
	case models.OrderStatusReadyForPickup:
		if fromStatus == models.OrderStatusDriverAssigned && order.DeliveryPartnerID != nil {
			var assignment models.OrderDeliveryAssignment
			if err := s.db.Where("order_id = ? AND delivery_user_id = ? AND status = ?",
				order.ID, *order.DeliveryPartnerID, models.AssignmentPending).
				Order("created_at DESC").First(&assignment).Error; err == nil {
				s.db.Model(&assignment).Updates(map[string]interface{}{
					"status":        models.AssignmentRejected,
					"rejected_at":   now,
					"timeout_count": gorm.Expr("timeout_count + 1"),
				})
			}
			order.DeliveryPartnerID = nil
			order.AssignedAt = nil
		}
	case models.OrderStatusPickedUp:
		order.PickedUpAt = &now
	case models.OrderStatusOutForDelivery:
		s.generateDeliveryOTP(&order)
	}

	order.Status = newStatus
	if err := s.db.Save(&order).Error; err != nil {
		return nil, fmt.Errorf("failed to update order")
	}

	s.db.Create(&models.OrderStatusLog{
		OrderID:    order.ID,
		FromStatus: fromStatus,
		ToStatus:   newStatus,
		ChangedBy:  userID,
		Role:       role,
		Note:       note,
	})

	notifType := s.getNotificationForTransition(newStatus)
	if fromStatus == models.OrderStatusDriverAssigned && newStatus == models.OrderStatusReadyForPickup {
		notifType = models.NotifOrderAssignmentExpired
	}
	s.dispatchWSEvent(&order, notifType)
	s.dispatchNotificationEvent(ctx, &order, notifType)

	return &order, nil
}

func (s *OrderService) generateInvoice(order *models.Order) {
	invoiceNo := "INV-" + order.OrderNumber + "-" + time.Now().Format("20060102150405")
	invoice := models.Invoice{
		OrderID:       order.ID,
		InvoiceNumber: invoiceNo,
		TotalAmount:   order.FinalAmount,
		TaxAmount:     order.TaxAmount,
	}
	s.db.Create(&invoice)
}

func (s *OrderService) getNotificationForTransition(toStatus models.OrderStatus) models.NotificationType {
	switch toStatus {
	case models.OrderStatusAccepted:
		return models.NotifOrderAccepted
	case models.OrderStatusPacked:
		return models.NotifOrderPacked
	case models.OrderStatusReadyForPickup:
		return models.NotifOrderReadyForPickup
	case models.OrderStatusDriverAssigned:
		return models.NotifOrderDriverAssigned
	case models.OrderStatusDriverAccepted:
		return models.NotifOrderDriverAccepted
	case models.OrderStatusPickedUp:
		return models.NotifOrderPickedUp
	case models.OrderStatusOutForDelivery:
		return models.NotifOrderOutForDelivery
	case models.OrderStatusDelivered:
		return models.NotifOrderDelivered
	case models.OrderStatusCancelled:
		return models.NotifOrderCancelled
	}
	return ""
}

func (s *OrderService) dispatchWSEvent(order *models.Order, notifType models.NotificationType) {
	if s.wsHub == nil {
		return
	}

	// Legacy order_update message
	updateMsg := &websocket.WSMessage{
		Type: websocket.MsgOrderUpdate,
		Payload: map[string]interface{}{
			"order_id":     order.ID.String(),
			"status":       order.Status,
			"order_number": order.OrderNumber,
		},
	}
	s.wsHub.SendToUser(order.CustomerID, updateMsg)
	s.wsHub.SendToRoom("order:"+order.ID.String(), updateMsg)

	// New order.status_changed message with timeline
	var statusLogs []models.OrderStatusLog
	s.db.Where("order_id = ?", order.ID).Order("created_at ASC").Find(&statusLogs)

	timeline := make([]map[string]interface{}, 0)
	for _, log := range statusLogs {
		timeline = append(timeline, map[string]interface{}{
			"status":    log.ToStatus,
			"timestamp": log.CreatedAt,
			"note":      log.Note,
		})
	}

	statusMsg := &websocket.WSMessage{
		Type: websocket.MsgOrderStatusChanged,
		Payload: map[string]interface{}{
			"version":  1,
			"event":    "order.status_changed",
			"order_id": order.ID.String(),
			"status":   order.Status,
			"timeline": timeline,
		},
	}
	s.wsHub.SendToUser(order.CustomerID, statusMsg)
	s.wsHub.SendToRoom("order:"+order.ID.String(), statusMsg)

	switch notifType {
	case models.NotifOrderDriverAssigned:
		if order.DeliveryPartnerID != nil {
			s.wsHub.SendToUser(*order.DeliveryPartnerID, updateMsg)
			s.wsHub.SendToUser(*order.DeliveryPartnerID, statusMsg)
		}
	case models.NotifOrderDriverAccepted:
		s.wsHub.BroadcastToRole("vendor", updateMsg)
	case models.NotifOrderAssignmentExpired:
		s.wsHub.BroadcastToRole("delivery", updateMsg)
	}
}

func (s *OrderService) dispatchNotificationEvent(ctx context.Context, order *models.Order, notifType models.NotificationType) {
	if s.dispatcher == nil {
		return
	}

	notify := func(receiverID uuid.UUID, role string) {
		s.dispatcher.Dispatch(ctx, notification.NotificationEvent{
			Type:       notifType,
			ReceiverID: receiverID,
			Role:       role,
			Data:       map[string]interface{}{"order_id": order.ID.String()},
		})
	}

	switch notifType {
	case models.NotifOrderAccepted, models.NotifOrderPacked, models.NotifOrderOutForDelivery, models.NotifOrderDelivered:
		notify(order.CustomerID, notification.RoleCustomer)
	case models.NotifOrderReadyForPickup:
		notify(order.CustomerID, notification.RoleCustomer)
	case models.NotifOrderDriverAssigned:
		notify(order.CustomerID, notification.RoleCustomer)
		if order.DeliveryPartnerID != nil {
			notify(*order.DeliveryPartnerID, notification.RoleDelivery)
		}
	case models.NotifOrderDriverAccepted:
		notify(order.CustomerID, notification.RoleCustomer)
	case models.NotifOrderAssignmentExpired:
		notify(order.CustomerID, notification.RoleCustomer)
	case models.NotifOrderPickedUp:
		notify(order.CustomerID, notification.RoleCustomer)
	case models.NotifOrderCancelled:
		notify(order.CustomerID, notification.RoleCustomer)
		var vendor models.Vendor
		if err := s.db.First(&vendor, order.VendorID).Error; err == nil {
			notify(vendor.UserID, notification.RoleVendor)
		}
	}
}

// AssignDriver creates a new assignment and transitions order to driver_assigned
func (s *OrderService) AssignDriver(ctx context.Context, orderID, deliveryUserID uuid.UUID, role string) (*models.Order, error) {
	eligible, err := s.presenceSvc.IsEligibleForAssignment(ctx, deliveryUserID)
	if err != nil {
		return nil, fmt.Errorf("eligibility check failed: %w", err)
	}
	if !eligible {
		return nil, fmt.Errorf("driver %s is not eligible for assignment", deliveryUserID)
	}

	return s.TransitionOrder(ctx, orderID, deliveryUserID, role, models.OrderStatusDriverAssigned, "")
}

// AcceptAssignment transitions driver_assigned → driver_accepted
func (s *OrderService) AcceptAssignment(ctx context.Context, orderID, userID uuid.UUID) (*models.Order, error) {
	var order models.Order
	if err := s.db.First(&order, orderID).Error; err != nil {
		return nil, fmt.Errorf("order not found")
	}
	if order.DeliveryPartnerID == nil || *order.DeliveryPartnerID != userID {
		return nil, fmt.Errorf("not the assigned driver")
	}
	return s.TransitionOrder(ctx, orderID, userID, "delivery", models.OrderStatusDriverAccepted, "")
}

// RejectAssignment transitions driver_assigned → ready_for_pickup (rejected)
func (s *OrderService) RejectAssignment(ctx context.Context, orderID, userID uuid.UUID) (*models.Order, error) {
	var order models.Order
	if err := s.db.First(&order, orderID).Error; err != nil {
		return nil, fmt.Errorf("order not found")
	}
	if order.DeliveryPartnerID == nil || *order.DeliveryPartnerID != userID {
		return nil, fmt.Errorf("not the assigned driver")
	}
	return s.TransitionOrder(ctx, orderID, userID, "delivery", models.OrderStatusReadyForPickup, "driver rejected assignment")
}

// GetOrderByID returns an order by its ID
func (s *OrderService) GetOrderByID(ctx context.Context, orderID uuid.UUID) (*models.Order, error) {
	var order models.Order
	if err := s.db.First(&order, orderID).Error; err != nil {
		return nil, fmt.Errorf("order not found: %w", err)
	}
	return &order, nil
}

// FindActiveOrderByDriver returns the active order for a delivery partner
func (s *OrderService) FindActiveOrderByDriver(ctx context.Context, deliveryUserID uuid.UUID) (*models.Order, error) {
	var order models.Order
	err := s.db.Where("delivery_partner_id = ? AND status IN (?)",
		deliveryUserID,
		[]models.OrderStatus{
			models.OrderStatusDriverAssigned,
			models.OrderStatusDriverAccepted,
			models.OrderStatusPickedUp,
			models.OrderStatusOutForDelivery,
		},
	).First(&order).Error
	if err != nil {
		return nil, fmt.Errorf("no active order for driver %s: %w", deliveryUserID, err)
	}
	return &order, nil
}

// ExpireAssignments checks for expired pending assignments and returns them to ready_for_pickup
func (s *OrderService) ExpireAssignments(ctx context.Context) (int, error) {
	var assignments []models.OrderDeliveryAssignment
	now := time.Now()
	s.db.Where("status = ? AND expires_at <= ?", models.AssignmentPending, now).Find(&assignments)

	expired := 0
	for _, a := range assignments {
		s.db.Model(&a).Updates(map[string]interface{}{
			"status":        models.AssignmentExpired,
			"rejected_at":   now,
			"timeout_count": gorm.Expr("timeout_count + 1"),
		})

		var order models.Order
		if err := s.db.First(&order, a.OrderID).Error; err == nil && order.Status == models.OrderStatusDriverAssigned {
			if order.DeliveryPartnerID != nil && *order.DeliveryPartnerID == a.DeliveryUserID {
				order.DeliveryPartnerID = nil
				order.AssignedAt = nil
				order.Status = models.OrderStatusReadyForPickup
				s.db.Save(&order)

				s.db.Create(&models.OrderStatusLog{
					OrderID:    order.ID,
					FromStatus: models.OrderStatusDriverAssigned,
					ToStatus:   models.OrderStatusReadyForPickup,
					ChangedBy:  a.DeliveryUserID,
					Role:       "delivery",
					Note:       "assignment expired",
				})
			}

			s.dispatchWSEvent(&order, models.NotifOrderAssignmentExpired)
			s.dispatchNotificationEvent(ctx, &order, models.NotifOrderAssignmentExpired)
		}

		expired++
	}
	return expired, nil
}

func (s *OrderService) generateDeliveryOTP(order *models.Order) {
	code := fmt.Sprintf("%04d", mustRandomInt(10000))
	otpHash := hashOTP(code)

	now := time.Now()
	otp := models.DeliveryOTP{
		OrderID:   order.ID,
		OTP:       otpHash,
		ExpiresAt: now.Add(10 * time.Minute),
	}
	if err := s.db.Create(&otp).Error; err != nil {
		return
	}

	s.wsHub.SendToRoom("order:"+order.ID.String(), &websocket.WSMessage{
		Type: websocket.MsgDeliveryOTPGenerated,
		Payload: map[string]interface{}{
			"version":              1,
			"event":                "delivery_otp_generated",
			"order_id":             order.ID.String(),
			"delivery_otp":         code,
			"expires_in_seconds":   600,
		},
	})
}

func (s *OrderService) VerifyDeliveryOTP(ctx context.Context, orderID, userID uuid.UUID, otp string, otpType string) (*models.Order, error) {
	var order models.Order
	if err := s.db.First(&order, orderID).Error; err != nil {
		return nil, fmt.Errorf("order not found")
	}

	if order.DeliveryPartnerID == nil || *order.DeliveryPartnerID != userID {
		return nil, fmt.Errorf("not the assigned driver for this order")
	}

	if order.Status != models.OrderStatusOutForDelivery {
		return nil, fmt.Errorf("order is not out for delivery")
	}

	var deliveryOTP models.DeliveryOTP
	if err := s.db.Where("order_id = ? AND verified_at IS NULL", orderID).First(&deliveryOTP).Error; err != nil {
		return nil, fmt.Errorf("no active OTP found for this order")
	}

	if deliveryOTP.IsExpired() {
		return nil, fmt.Errorf("OTP has expired")
	}

	if !deliveryOTP.CanRetry() {
		return nil, fmt.Errorf("maximum OTP attempts exceeded")
	}

	deliveryOTP.Attempts++

	if deliveryOTP.OTP != hashOTP(otp) {
		s.db.Save(&deliveryOTP)
		return nil, fmt.Errorf("invalid OTP")
	}

	now := time.Now()
	deliveryOTP.VerifiedAt = &now
	s.db.Save(&deliveryOTP)

	return s.TransitionOrder(ctx, orderID, userID, "delivery", models.OrderStatusDelivered, "OTP verified")
}

func mustRandomInt(max int64) int64 {
	n, err := rand.Int(rand.Reader, big.NewInt(max))
	if err != nil {
		return 0
	}
	return n.Int64()
}

func hashOTP(otp string) string {
	mac := hmac.New(sha256.New, []byte(otpPepper))
	mac.Write([]byte(otp))
	return hex.EncodeToString(mac.Sum(nil))
}

func (s *OrderService) RegenerateOTP(ctx context.Context, orderID, userID uuid.UUID, role string) (*models.Order, error) {
	var order models.Order
	if err := s.db.First(&order, orderID).Error; err != nil {
		return nil, fmt.Errorf("order not found")
	}

	if order.Status != models.OrderStatusOutForDelivery {
		return nil, fmt.Errorf("order is not out for delivery")
	}

	if role == "delivery" {
		if order.DeliveryPartnerID == nil || *order.DeliveryPartnerID != userID {
			return nil, fmt.Errorf("not the assigned driver for this order")
		}
	}

	var existing models.DeliveryOTP
	if err := s.db.Where("order_id = ? AND verified_at IS NULL", orderID).First(&existing).Error; err == nil {
		if !existing.IsExpired() && existing.CanRetry() {
			return nil, fmt.Errorf("current OTP is still valid, cannot regenerate")
		}
		s.db.Model(&existing).Update("verified_at", time.Now())
	}

	s.generateDeliveryOTP(&order)

	var updated models.Order
	s.db.Preload("DeliveryPartner").Preload("StatusLogs").First(&updated, orderID)
	return &updated, nil
}
