package order

import (
	"context"
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

func (s *OrderService) BroadcastDeliveryOffer(ctx context.Context, order *models.Order) {
	var vendor models.Vendor
	if err := s.db.First(&vendor, order.VendorID).Error; err != nil {
		fmt.Printf("BroadcastDeliveryOffer: failed to load vendor %s\n", order.VendorID)
		return
	}

	lat := vendor.Latitude
	lng := vendor.Longitude

	appConfig := config.Load().App
	radiusKm := float64(appConfig.DeliveryBroadcastRadiusKm)
	if radiusKm <= 0 {
		radiusKm = 5
	}

	// 1. Initial Broadcast to closest 5 drivers
	drivers, err := s.presenceSvc.GetOnlineDriversNearby(ctx, lat, lng, radiusKm, 5)
	if err != nil {
		fmt.Printf("BroadcastDeliveryOffer: failed to get nearby drivers: %v\n", err)
		return
	}

	if len(drivers) == 0 {
		fmt.Printf("BroadcastDeliveryOffer: no drivers found within %f km\n", radiusKm)
	}

	notifiedDriverIDs := make(map[string]bool)

	for _, d := range drivers {
		userIDStr := d["user_id"].(string)
		userID, parseErr := uuid.Parse(userIDStr)
		if parseErr != nil {
			continue
		}
		notifiedDriverIDs[userIDStr] = true

		s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
			Type:       models.NotifDeliveryOffer,
			ReceiverID: userID,
			Data: map[string]interface{}{
				"action":    "NEW_DELIVERY_AVAILABLE",
				"entity_id": order.ID.String(),
			},
		})
	}

	// 2. Wait 30 seconds
	time.Sleep(30 * time.Second)

	// Check if order is still unassigned
	var currentOrder models.Order
	if err := s.db.First(&currentOrder, order.ID).Error; err != nil {
		return
	}
	if currentOrder.DeliveryPartnerID != nil || currentOrder.Status != models.OrderStatusReadyForPickup {
		return // Order accepted
	}

	// 3. Expand search radius
	expandedRadius := radiusKm * 2
	drivers2, err := s.presenceSvc.GetOnlineDriversNearby(ctx, lat, lng, expandedRadius, 20)
	if err == nil {
		for _, d := range drivers2 {
			userIDStr := d["user_id"].(string)
			if notifiedDriverIDs[userIDStr] {
				continue // already notified
			}
			userID, parseErr := uuid.Parse(userIDStr)
			if parseErr != nil {
				continue
			}
			notifiedDriverIDs[userIDStr] = true

			s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
				Type:       models.NotifDeliveryOffer,
				ReceiverID: userID,
				Data: map[string]interface{}{
					"action":    "NEW_DELIVERY_AVAILABLE",
					"entity_id": order.ID.String(),
				},
			})
		}
	}

	// 4. Wait remaining timeout
	timeoutSec := appConfig.DeliveryBroadcastTimeoutSec
	if timeoutSec <= 30 {
		timeoutSec = 120
	}
	remainingWait := time.Duration(timeoutSec-30) * time.Second
	time.Sleep(remainingWait)

	// 5. Final check
	if err := s.db.First(&currentOrder, order.ID).Error; err != nil {
		return
	}
	if currentOrder.DeliveryPartnerID == nil && currentOrder.Status == models.OrderStatusReadyForPickup {
		fmt.Printf("BroadcastDeliveryOffer: Order %s expired with no acceptance after %d seconds\n", order.ID, timeoutSec)
		// Optionally trigger an escalation notification to admins here
	}
}

// ClaimDeliveryOrder atomically assigns a delivery partner to an order
func (s *OrderService) ClaimDeliveryOrder(ctx context.Context, orderID, userID uuid.UUID) (*models.Order, error) {
	// First check if driver is eligible
	eligible, err := s.presenceSvc.IsEligibleForAssignment(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("driver not eligible: %w", err)
	}
	if !eligible {
		return nil, fmt.Errorf("driver is not eligible for assignment")
	}

	var updatedOrder models.Order
	
	err = s.db.Transaction(func(tx *gorm.DB) error {
		var order models.Order
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&order, orderID).Error; err != nil {
			return fmt.Errorf("order not found")
		}

		if order.Status != models.OrderStatusReadyForPickup {
			return fmt.Errorf("order is not ready for pickup")
		}

		if order.DeliveryPartnerID != nil {
			return fmt.Errorf("this order has already been taken by another driver")
		}

		now := time.Now()
		
		result := tx.Model(&order).Where("id = ? AND status = ? AND delivery_partner_id IS NULL", orderID, models.OrderStatusReadyForPickup).Updates(map[string]interface{}{
			"delivery_partner_id": userID,
			"status":              models.OrderStatusDriverAssigned,
			"assigned_at":         now,
		})

		if result.Error != nil {
			return result.Error
		}

		if result.RowsAffected == 0 {
			return fmt.Errorf("this order has already been taken by another driver")
		}
		
		updatedOrder = order
		updatedOrder.DeliveryPartnerID = &userID
		updatedOrder.Status = models.OrderStatusDriverAssigned
		updatedOrder.AssignedAt = &now

		return nil
	})

	if err != nil {
		return nil, err
	}

	// Trigger notifications since claim was successful
		s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
			Type:       models.NotifOrderDriverAssigned,
			ReceiverID: updatedOrder.VendorID,
			Role:       notification.RoleVendor,
			Data: map[string]interface{}{
				"action":    "OPEN_ORDER",
				"entity_id": updatedOrder.ID.String(),
			},
		})

		s.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
			Type:       models.NotifOrderDriverAssigned,
			ReceiverID: updatedOrder.CustomerID,
			Role:       notification.RoleCustomer,
		Data: map[string]interface{}{
			"action":    "OPEN_ORDER",
			"entity_id": updatedOrder.ID.String(),
		},
	})

	return &updatedOrder, nil
}
