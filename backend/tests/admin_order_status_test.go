package tests

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	orderService "github.com/barbar-app/backend/internal/services/order"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	cfg := config.Load()
	db := database.InitPostgres(&cfg.Database)
	return db
}

func createTestOrder(t *testing.T, db *gorm.DB, initialStatus models.OrderStatus) (*models.Order, *models.Product, *models.User, *models.User, *models.User) {
	t.Helper()
	// 1. Create Vendor user & profile
	vendorUser := &models.User{
		Email:    fmt.Sprintf("vendor_%s@test.com", uuid.New().String()[:8]),
		FullName: "Test Vendor User",
		Phone:    fmt.Sprintf("+9198%08d", time.Now().UnixNano()%100000000),
		Role:     models.RoleVendor,
		Status:   "active",
	}
	db.Create(vendorUser)

	vendor := &models.Vendor{
		UserID:       vendorUser.ID,
		BusinessName: "Test Barber Supplies",
		Status:       "active",
	}
	db.Create(vendor)

	// Vendor Wallet
	vWallet := &models.Wallet{
		UserID:   &vendorUser.ID,
		VendorID: &vendor.ID,
		Balance:  0.0,
	}
	db.Create(vWallet)

	// 2. Create Customer user & wallet
	custUser := &models.User{
		Email:    fmt.Sprintf("cust_%s@test.com", uuid.New().String()[:8]),
		FullName: "Test Customer User",
		Phone:    fmt.Sprintf("+9197%08d", time.Now().UnixNano()%100000000),
		Role:     models.RoleCustomer,
		Status:   "active",
	}
	db.Create(custUser)

	cWallet := &models.Wallet{
		UserID:   &custUser.ID,
		Balance:  500.0,
	}
	db.Create(cWallet)

	// 3. Create Delivery Partner user & profile & wallet
	dpUser := &models.User{
		Email:    fmt.Sprintf("dp_%s@test.com", uuid.New().String()[:8]),
		FullName: "Test Delivery Partner",
		Phone:    fmt.Sprintf("+9196%08d", time.Now().UnixNano()%100000000),
		Role:     models.RoleDelivery,
		Status:   "active",
	}
	db.Create(dpUser)

	dp := &models.DeliveryPartner{
		UserID:             dpUser.ID,
		Status:             models.DeliveryPartnerStatusApproved,
		AvailabilityStatus: models.DeliveryPartnerStatusAvailable,
		VehicleType:        "bike",
		VehicleNumber:      "DL01AB1234",
		LicenseNumber:      "DL1234567890",
	}
	db.Create(dp)

	dpWallet := &models.Wallet{
		UserID:   &dpUser.ID,
		Balance:  0.0,
	}
	db.Create(dpWallet)

	// 4. Create Product with initial stock
	prod := &models.Product{
		VendorID:       vendor.ID,
		Name:           "Pro Hair Pomade",
		BasePrice:      200.0,
		AvailableStock: 50,
		ReservedStock:  2,
		SoldCount:      0,
		IsActive:       true,
	}
	db.Create(prod)

	// 5. Create Order
	orderNum := fmt.Sprintf("ORD-%s", uuid.New().String()[:8])
	order := &models.Order{
		CustomerID:        custUser.ID,
		VendorID:          vendor.ID,
		DeliveryPartnerID: &dpUser.ID,
		OrderNumber:       orderNum,
		Status:            initialStatus,
		ItemsTotal:        200.0,
		ShippingCharge:    30.0,
		TaxAmount:         10.0,
		FinalAmount:       240.0,
		CommissionAmount:  24.0,
		VendorEarnings:    176.0,
		PlatformFee:       40.0,
		WalletUsed:        50.0,
		PaymentStatus:     models.PaymentStatusSuccess,
	}
	db.Create(order)

	// Order Item
	item := &models.OrderItem{
		OrderID:   order.ID,
		ProductID: prod.ID,
		Quantity:  2,
		UnitPrice: 100.0,
		TotalPrice: 200.0,
	}
	db.Create(item)

	return order, prod, vendorUser, custUser, dpUser
}

func TestAdminOrderStatusSafety(t *testing.T) {
	db := setupTestDB(t)
	cfg := config.Load()
	jwtManager := auth.NewJWTManager(&cfg.JWT)
	hub := websocket.NewHub(cfg, jwtManager)
	dispatcher := notifService.NewDispatcher(db, hub, nil)
	presenceSvc := deliverySvc.NewPresenceService(db, hub)
	orderSvc := orderService.NewOrderService(db, dispatcher, hub, presenceSvc)

	// Admin Token for HTTP tests
	adminToken := login(t, "admin@barbar.com", "AdminPass123!")

	// 1. RBAC Tests: Ensure Non-Admin tokens get 403 and unauthenticated gets 401
	t.Run("RBAC_Forbidden_For_Non_Admins", func(t *testing.T) {
		order, _, vendorUser, custUser, dpUser := createTestOrder(t, db, models.OrderStatusPending)

		// Unauthenticated -> 401
		wUnauth := request("PUT", fmt.Sprintf("/admin/orders/%s/status", order.ID), "", map[string]string{
			"status": "accepted",
		})
		if wUnauth.Code != http.StatusUnauthorized {
			t.Errorf("Expected 401 for unauthenticated request, got %d", wUnauth.Code)
		}

		// Vendor -> 403
		vendorPair, _ := jwtManager.GenerateTokenPair(vendorUser.ID, vendorUser.Email, vendorUser.Phone, string(models.RoleVendor))
		wVendor := request("PUT", fmt.Sprintf("/admin/orders/%s/status", order.ID), vendorPair.AccessToken, map[string]string{
			"status": "accepted",
		})
		if wVendor.Code != http.StatusForbidden {
			t.Errorf("Expected 403 for vendor, got %d", wVendor.Code)
		}

		// Customer -> 403
		custPair, _ := jwtManager.GenerateTokenPair(custUser.ID, custUser.Email, custUser.Phone, string(models.RoleCustomer))
		wCust := request("PUT", fmt.Sprintf("/admin/orders/%s/status", order.ID), custPair.AccessToken, map[string]string{
			"status": "accepted",
		})
		if wCust.Code != http.StatusForbidden {
			t.Errorf("Expected 403 for customer, got %d", wCust.Code)
		}

		// Delivery Partner -> 403
		dpPair, _ := jwtManager.GenerateTokenPair(dpUser.ID, dpUser.Email, dpUser.Phone, string(models.RoleDelivery))
		wDP := request("PUT", fmt.Sprintf("/admin/orders/%s/status", order.ID), dpPair.AccessToken, map[string]string{
			"status": "accepted",
		})
		if wDP.Code != http.StatusForbidden {
			t.Errorf("Expected 403 for delivery partner, got %d", wDP.Code)
		}
	})

	// 2. Valid Forward Lifecycle Transitions
	t.Run("Valid_Lifecycle_Transitions", func(t *testing.T) {
		order, _, _, _, _ := createTestOrder(t, db, models.OrderStatusPending)
		adminID := uuid.New()

		steps := []struct {
			toStatus models.OrderStatus
			note     string
		}{
			{models.OrderStatusAccepted, "Vendor accepted"},
			{models.OrderStatusPacked, "Items packed in box"},
			{models.OrderStatusReadyForPickup, "Ready at counter"},
			{models.OrderStatusDriverAssigned, "Driver assigned"},
			{models.OrderStatusDriverAccepted, "Driver accepted job"},
			{models.OrderStatusPickedUp, "Picked up from vendor"},
			{models.OrderStatusOutForDelivery, "Heading to destination"},
			{models.OrderStatusDelivered, "Delivered safely"},
		}

		for _, step := range steps {
			updated, err := orderSvc.TransitionOrder(context.Background(), order.ID, adminID, "admin", step.toStatus, step.note)
			if err != nil {
				t.Fatalf("Failed transition to %s: %v", step.toStatus, err)
			}
			if updated.Status != step.toStatus {
				t.Errorf("Expected status %s, got %s", step.toStatus, updated.Status)
			}
		}

		// Verify timeline logs were created
		var logs []models.OrderStatusLog
		db.Where("order_id = ?", order.ID).Order("created_at ASC").Find(&logs)
		if len(logs) != len(steps) {
			t.Errorf("Expected %d status logs, found %d", len(steps), len(logs))
		}
	})

	// 3. Blocked Transitions (Invalid State Jumps)
	t.Run("Blocked_Invalid_Transitions", func(t *testing.T) {
		adminID := uuid.New()

		// pending -> delivered (Blocked)
		o1, _, _, _, _ := createTestOrder(t, db, models.OrderStatusPending)
		_, err := orderSvc.TransitionOrder(context.Background(), o1.ID, adminID, "admin", models.OrderStatusDelivered, "")
		if err == nil {
			t.Errorf("Expected pending -> delivered to fail, but succeeded")
		}

		// pending -> out_for_delivery (Blocked)
		o2, _, _, _, _ := createTestOrder(t, db, models.OrderStatusPending)
		_, err = orderSvc.TransitionOrder(context.Background(), o2.ID, adminID, "admin", models.OrderStatusOutForDelivery, "")
		if err == nil {
			t.Errorf("Expected pending -> out_for_delivery to fail, but succeeded")
		}

		// delivered -> pending (Blocked)
		o3, _, _, _, _ := createTestOrder(t, db, models.OrderStatusDelivered)
		_, err = orderSvc.TransitionOrder(context.Background(), o3.ID, adminID, "admin", models.OrderStatusPending, "")
		if err == nil {
			t.Errorf("Expected delivered -> pending to fail, but succeeded")
		}

		// delivered -> cancelled (Blocked)
		o4, _, _, _, _ := createTestOrder(t, db, models.OrderStatusDelivered)
		_, err = orderSvc.TransitionOrder(context.Background(), o4.ID, adminID, "admin", models.OrderStatusCancelled, "too late")
		if err == nil {
			t.Errorf("Expected delivered -> cancelled to fail, but succeeded")
		}

		// cancelled -> delivered (Blocked)
		o5, _, _, _, _ := createTestOrder(t, db, models.OrderStatusCancelled)
		_, err = orderSvc.TransitionOrder(context.Background(), o5.ID, adminID, "admin", models.OrderStatusDelivered, "")
		if err == nil {
			t.Errorf("Expected cancelled -> delivered to fail, but succeeded")
		}

		// delivered -> accepted (Blocked)
		o6, _, _, _, _ := createTestOrder(t, db, models.OrderStatusDelivered)
		_, err = orderSvc.TransitionOrder(context.Background(), o6.ID, adminID, "admin", models.OrderStatusAccepted, "")
		if err == nil {
			t.Errorf("Expected delivered -> accepted to fail, but succeeded")
		}
	})

	// 4. Cancellation Financial & Inventory Side Effects
	t.Run("Cancellation_Restores_Stock_And_Refunds_Wallet", func(t *testing.T) {
		order, prod, _, custUser, _ := createTestOrder(t, db, models.OrderStatusAccepted)
		adminID := uuid.New()

		initStock := prod.AvailableStock

		// Cancel order
		updated, err := orderSvc.TransitionOrder(context.Background(), order.ID, adminID, "admin", models.OrderStatusCancelled, "Customer requested cancellation")
		if err != nil {
			t.Fatalf("Failed to cancel order: %v", err)
		}
		if updated.Status != models.OrderStatusCancelled {
			t.Fatalf("Status is not cancelled")
		}

		// Verify stock was restored (+2)
		var freshProd models.Product
		db.First(&freshProd, prod.ID)
		if freshProd.AvailableStock != initStock+2 {
			t.Errorf("Expected stock %d, got %d", initStock+2, freshProd.AvailableStock)
		}

		// Verify wallet refund (+50)
		var freshWallet models.Wallet
		db.Where("user_id = ?", custUser.ID).First(&freshWallet)
		if freshWallet.Balance != 550.0 {
			t.Errorf("Expected wallet balance 550.0, got %f", freshWallet.Balance)
		}
	})

	// 5. Financial Settlement Idempotency on Delivered
	t.Run("Delivery_Settlement_Idempotency", func(t *testing.T) {
		order, _, vendorUser, _, dpUser := createTestOrder(t, db, models.OrderStatusOutForDelivery)
		adminID := uuid.New()

		// Deliver order
		_, err := orderSvc.TransitionOrder(context.Background(), order.ID, adminID, "admin", models.OrderStatusDelivered, "Delivered successfully")
		if err != nil {
			t.Fatalf("Delivery transition failed: %v", err)
		}

		// Check vendor wallet & commission count
		var commCount int64
		db.Model(&models.CommissionTransaction{}).Where("order_id = ?", order.ID).Count(&commCount)
		if commCount != 1 {
			t.Errorf("Expected exactly 1 commission transaction, found %d", commCount)
		}

		var vendorWallet models.Wallet
		db.Where("user_id = ?", vendorUser.ID).First(&vendorWallet)
		if vendorWallet.Balance != 176.0 {
			t.Errorf("Expected vendor wallet balance 176.0, got %f", vendorWallet.Balance)
		}

		// Check driver wallet
		var driverWallet models.Wallet
		db.Where("user_id = ?", dpUser.ID).First(&driverWallet)
		if driverWallet.Balance != 30.0 {
			t.Errorf("Expected driver wallet balance 30.0, got %f", driverWallet.Balance)
		}

		// Simulate repeated transition / settlement attempt
		// TransitionOrder to delivered again (should fail transition validator)
		_, errRepeated := orderSvc.TransitionOrder(context.Background(), order.ID, adminID, "admin", models.OrderStatusDelivered, "Repeat")
		if errRepeated == nil {
			t.Errorf("Expected repeated transition from delivered to delivered to be rejected")
		}

		// Re-verify balances haven't changed
		db.Where("user_id = ?", vendorUser.ID).First(&vendorWallet)
		if vendorWallet.Balance != 176.0 {
			t.Errorf("Vendor wallet balance corrupted on repeat: %f", vendorWallet.Balance)
		}

		db.Where("user_id = ?", dpUser.ID).First(&driverWallet)
		if driverWallet.Balance != 30.0 {
			t.Errorf("Driver wallet balance corrupted on repeat: %f", driverWallet.Balance)
		}

		// Verify invoices are not duplicated
		time.Sleep(200 * time.Millisecond) // wait for goroutine
		var invCount int64
		db.Model(&models.Invoice{}).Where("order_id = ?", order.ID).Count(&invCount)
		if invCount != 1 {
			t.Errorf("Expected 1 invoice, found %d", invCount)
		}
	})

	// 6. Admin API Endpoint and Audit Logging
	t.Run("Admin_API_Endpoint_And_Audit_Logging", func(t *testing.T) {
		order, _, _, _, _ := createTestOrder(t, db, models.OrderStatusPending)

		// 1. Mandatory note for cancellation
		wCancelNoNote := request("PUT", fmt.Sprintf("/admin/orders/%s/status", order.ID), adminToken, map[string]string{
			"status": "cancelled",
			"note":   "",
		})
		if wCancelNoNote.Code != http.StatusBadRequest {
			t.Errorf("Expected 400 for cancellation without note, got %d", wCancelNoNote.Code)
		}

		// 2. Successful Admin update with note
		wAccept := request("PUT", fmt.Sprintf("/admin/orders/%s/status", order.ID), adminToken, map[string]string{
			"status": "accepted",
			"note":   "Admin accepted manually on vendor phone request",
		})
		if wAccept.Code != http.StatusOK {
			t.Fatalf("Admin update failed: %d - %s", wAccept.Code, wAccept.Body.String())
		}

		// 3. Verify models.AuditLog record in DB
		var auditLog models.AuditLog
		if err := db.Where("entity_id = ? AND action = ?", order.ID.String(), "order_status_update").
			Order("created_at DESC").First(&auditLog).Error; err != nil {
			t.Fatalf("Audit log not found in database: %v", err)
		}

		if auditLog.EntityType != "order" {
			t.Errorf("Expected entity_type 'order', got '%s'", auditLog.EntityType)
		}

		// 4. Verify OrderStatusLog in DB
		var statusLog models.OrderStatusLog
		if err := db.Where("order_id = ? AND to_status = ?", order.ID, models.OrderStatusAccepted).
			First(&statusLog).Error; err != nil {
			t.Fatalf("OrderStatusLog not found: %v", err)
		}
		if statusLog.Note != "Admin accepted manually on vendor phone request" {
			t.Errorf("Expected note to be saved in status log, got '%s'", statusLog.Note)
		}
	})
}
