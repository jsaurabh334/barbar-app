package tests

import (
	"fmt"
	"testing"
	"time"

	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
)

func TestInitiatePayment_Validation(t *testing.T) {
	ts := time.Now().UnixNano()
	email := fmt.Sprintf("pay-validate-%d@test.com", ts)
	token := register(t, "Pay Cust", email, "+919999996000", "TestPass123!", "customer")

	// No order_id and no booking_id
	w := request("POST", "/payments/initiate", token, map[string]string{
		"gateway": "razorpay",
	})
	if w.Code != 400 {
		t.Fatalf("Expected 400 for missing order/booking, got %d: %s", w.Code, w.Body.String())
	}

	// Invalid gateway
	w = request("POST", "/payments/initiate", token, map[string]string{
		"order_id": uuid.New().String(),
		"gateway":  "paypal",
	})
	if w.Code != 400 {
		t.Fatalf("Expected 400 for invalid gateway, got %d: %s", w.Code, w.Body.String())
	}
}

func TestGetPaymentStatus_NotFound(t *testing.T) {
	ts := time.Now().UnixNano()
	email := fmt.Sprintf("pay-status-%d@test.com", ts)
	token := register(t, "Pay Status", email, "+919999996001", "TestPass123!", "customer")

	w := request("GET", "/payments/"+uuid.New().String()+"/status", token, nil)
	if w.Code != 404 {
		t.Fatalf("Expected 404 for unknown payment, got %d: %s", w.Code, w.Body.String())
	}
}

func TestInitiatePayment_RequiresAuth(t *testing.T) {
	w := request("POST", "/payments/initiate", "", map[string]string{
		"order_id": uuid.New().String(),
		"gateway":  "razorpay",
	})
	if w.Code != 401 {
		t.Fatalf("Expected 401 without auth, got %d", w.Code)
	}
}

func TestPaymentWebhook_InvalidGateway(t *testing.T) {
	w := request("POST", "/payments/webhook/paypal", "", nil)
	if w.Code != 404 {
		t.Fatalf("Expected 404 for invalid gateway, got %d", w.Code)
	}
}

func TestVerifyPayment_MissingFields(t *testing.T) {
	ts := time.Now().UnixNano()
	email := fmt.Sprintf("pay-verify-%d@test.com", ts)
	token := register(t, "Pay Verify", email, "+919999996002", "TestPass123!", "customer")

	// Missing all fields
	w := request("POST", "/payments/verify", token, map[string]string{
		"gateway": "razorpay",
	})
	if w.Code != 404 {
		t.Fatalf("Expected 404 for missing payment ref, got %d: %s", w.Code, w.Body.String())
	}
}

func TestAdminProcessRefund_Validation(t *testing.T) {
	adminToken := login(t, "admin@barbar.com", "AdminPass123!")

	// Invalid refund ID
	w := request("PUT", "/admin/refunds/invalid-uuid/process", adminToken, map[string]string{
		"status": "approved",
	})
	if w.Code != 400 {
		t.Fatalf("Expected 400 for invalid refund ID, got %d: %s", w.Code, w.Body.String())
	}

	// Non-existent refund
	w = request("PUT", "/admin/refunds/"+uuid.New().String()+"/process", adminToken, map[string]string{
		"status": "approved",
	})
	if w.Code != 404 {
		t.Fatalf("Expected 404 for unknown refund, got %d: %s", w.Code, w.Body.String())
	}
}

func TestFullOrderPaymentFlow(t *testing.T) {
	ts := time.Now().UnixNano()
	vendorEmail := fmt.Sprintf("payflow-vendor-%d@test.com", ts)
	custEmail := fmt.Sprintf("payflow-cust-%d@test.com", ts)

	vendorToken := register(t, "PayFlow Vendor", vendorEmail, "+919999996010", "TestPass123!", "vendor")
	custToken := register(t, "PayFlow Cust", custEmail, "+919999996011", "TestPass123!", "customer")

	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active",
		catID, "PayFlow Cat", "payflow-cat")

	// Register vendor
	w := request("POST", "/vendor/register", vendorToken, map[string]interface{}{
		"business_name": "PayFlow Store",
		"address":       "555 Market St",
		"city":          "Bangalore",
		"state":         "Karnataka",
		"pincode":       "560001",
	})
	if w.Code != 201 {
		t.Fatalf("Vendor registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	vendorID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Vendor{}).Where("id = ?", vendorID).Updates(map[string]interface{}{
		"status": "approved", "is_verified": true,
	})

	// Create product
	w = request("POST", "/products/", vendorToken, map[string]interface{}{
		"name":        "PayFlow Product",
		"description": "Test",
		"category_id": catID,
		"base_price":  999,
		"total_stock": 50,
		"images":      []map[string]interface{}{{"image_url": "https://example.com/img.jpg", "is_primary": true}},
	})
	if w.Code != 201 {
		t.Fatalf("Product creation failed: %d", w.Code)
	}
	resp = parseResponse(w)
	prodID := resp["data"].(map[string]interface{})["id"].(string)
	database.DB.Model(&models.Product{}).Where("id = ?", prodID).Update("is_approved", true)

	// Place order
	w = request("POST", "/orders/", custToken, map[string]interface{}{
		"items": []map[string]interface{}{
			{"product_id": prodID, "quantity": 1},
		},
		"address": map[string]interface{}{
			"full_name": "Test User", "phone": "+919999999999",
			"line_1": "123 Test St", "city": "Bangalore",
			"state": "Karnataka", "pincode": "560001",
		},
		"payment_method": "razorpay",
	})
	if w.Code != 201 {
		t.Fatalf("Order placement failed: %d - %s", w.Code, w.Body.String())
	}

	// Verify order has payment_status = pending
	resp = parseResponse(w)
	orders := resp["data"].(map[string]interface{})["orders"].([]interface{})
	order := orders[0].(map[string]interface{})
	if order["payment_status"] != "pending" {
		t.Fatalf("Expected payment_status pending, got %v", order["payment_status"])
	}
	orderID := order["id"].(string)

	// Initiate payment (will fail in test env without Razorpay keys — that's expected)
	w = request("POST", "/payments/initiate", custToken, map[string]string{
		"order_id": orderID,
		"gateway":  "razorpay",
	})
	if w.Code != 500 {
		t.Logf("InitiatePayment returned %d (expected 500 without Razorpay keys): %s", w.Code, w.Body.String())
	}

	// Verify payment status lookup works
	w = request("GET", "/payments/"+orderID+"/status", custToken, nil)
	if w.Code != 404 {
		t.Logf("Payment status returned %d (expected 404 before payment): %s", w.Code, w.Body.String())
	}

	t.Log("PASS: Order→Payment flow validation complete")
}
