package tests

import (
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"golang.org/x/crypto/bcrypt"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/routes"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

var testRouter *gin.Engine
var baseURL = "/api/v1"

func TestMain(m *testing.M) {
	os.Setenv("BARBAR_ENV", "test")
	os.Setenv("DB_NAME", "barbar_app_test")
	os.Setenv("DB_USER", "postgres")
	os.Setenv("DB_PASSWORD", "postgres")
	os.Setenv("JWT_SECRET", "test-secret-for-dev-32-chars-long!!")
	os.Setenv("REDIS_HOST", "localhost")
	os.Setenv("REDIS_PORT", "6379")

	gin.SetMode(gin.TestMode)

	cfg := config.Load()
	db := database.InitPostgres(&cfg.Database)

	db.Exec("DROP SCHEMA IF EXISTS public CASCADE")
	db.Exec("CREATE SCHEMA IF NOT EXISTS public")
	database.RunMigrations(db)
	database.SeedData(db, &cfg.App)

	// Create admin user used by moderation tests
	adminHash, _ := bcrypt.GenerateFromPassword([]byte("AdminPass123!"), bcrypt.DefaultCost)
	db.Create(&models.User{
		Email:        "admin@barbar.com",
		PasswordHash: string(adminHash),
		FullName:     "Admin",
		Role:         "admin",
		Status:       "active",
	})

	rdb := database.InitRedis(&cfg.Redis)
	utils.NewCacheService(rdb)
	utils.NewWorkerPool(4, 100)

	jwtManager := auth.NewJWTManager(&cfg.JWT)
	hub := websocket.NewHub(cfg, jwtManager)
	go hub.Run()

	testRouter = routes.SetupRouter(db, cfg, jwtManager, hub)

	os.Exit(m.Run())
}

func request(method, path, token string, body interface{}) *httptest.ResponseRecorder {
	var reqBody string
	if body != nil {
		b, _ := json.Marshal(body)
		reqBody = string(b)
	}
	req := httptest.NewRequest(method, baseURL+path, strings.NewReader(reqBody))
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	testRouter.ServeHTTP(w, req)
	return w
}

func parseResponse(w *httptest.ResponseRecorder) map[string]interface{} {
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	return resp
}

func login(t *testing.T, email, password string) string {
	w := request("POST", "/auth/login", "", map[string]string{
		"email":    email,
		"password": password,
	})
	if w.Code != 200 {
		t.Fatalf("Login failed: %d - %s", w.Code, w.Body.String())
	}
	resp := parseResponse(w)
	token, _ := resp["data"].(map[string]interface{})["tokens"].(map[string]interface{})["access_token"].(string)
	return token
}

func register(t *testing.T, name, email, phone, password, role string) string {
	w := request("POST", "/auth/register", "", map[string]string{
		"full_name": name,
		"email":     email,
		"phone":     phone,
		"password":  password,
		"role":      role,
	})
	if w.Code != 201 {
		t.Fatalf("Registration failed: %d - %s", w.Code, w.Body.String())
	}
	resp := parseResponse(w)
	token, _ := resp["data"].(map[string]interface{})["tokens"].(map[string]interface{})["access_token"].(string)
	return token
}

func TestHealthCheck(t *testing.T) {
	w := httptest.NewRequest("GET", "/health", nil)
	resp := httptest.NewRecorder()
	testRouter.ServeHTTP(resp, w)
	if resp.Code != 200 {
		t.Fatalf("Health check failed: %d", resp.Code)
	}
}

func TestAuthFlow(t *testing.T) {
	ts := time.Now().UnixNano()
	email := fmt.Sprintf("test-auth-%d@test.com", ts)
	token := register(t, "Test User", email, "+919999999990", "TestPass123!", "customer")
	if token == "" {
		t.Fatal("No token returned from registration")
	}

	loginToken := login(t, email, "TestPass123!")
	if loginToken == "" {
		t.Fatal("No token returned from login")
	}

	w := request("GET", "/auth/profile", "", nil)
	if w.Code != 401 {
		t.Fatal("Profile without auth should return 401")
	}

	w = request("GET", "/auth/profile", token, nil)
	if w.Code != 200 {
		t.Fatalf("Profile request failed: %d - %s", w.Code, w.Body.String())
	}
}

func TestFullBarberFlow(t *testing.T) {
	ts := time.Now().UnixNano()
	barberEmail := fmt.Sprintf("barber-flow-%d@test.com", ts)
	custEmail := fmt.Sprintf("cust-flow-%d@test.com", ts)

	barberToken := register(t, "Test Barber", barberEmail, "+919999999991", "TestPass123!", "barber")
	custToken := register(t, "Test Customer", custEmail, "+919999999992", "TestPass123!", "customer")

	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Test Barber Shop",
		"address":    "123 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "description": "Classic cut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d - %s", w.Code, w.Body.String())
	}
	resp := parseResponse(w)
	barberID, _ := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	w = request("GET", "/barber/dashboard", barberToken, nil)
	if w.Code != 200 {
		t.Fatalf("Barber dashboard failed: %d - %s", w.Code, w.Body.String())
	}

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	w = request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id":       barberID,
		"service_ids":     []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	bookingData, _ := resp["data"].(map[string]interface{})
	if bookingData["queue_position"].(float64) != 1 {
		t.Fatalf("Expected queue position 1, got %v", bookingData["queue_position"])
	}

	w = request("GET", "/barber/queue", barberToken, nil)
	if w.Code != 200 {
		t.Fatalf("Barber queue failed: %d - %s", w.Code, w.Body.String())
	}
}

func TestFullVendorFlow(t *testing.T) {
	ts := time.Now().UnixNano()
	vendorEmail := fmt.Sprintf("vendor-flow-%d@test.com", ts)
	custEmail := fmt.Sprintf("cust-order-%d@test.com", ts)

	vendorToken := register(t, "Test Vendor", vendorEmail, "+919999999993", "TestPass123!", "vendor")
	custToken := register(t, "Order Customer", custEmail, "+919999999994", "TestPass123!", "customer")

	w := request("POST", "/vendor/register", vendorToken, map[string]interface{}{
		"store_name": "Test Store",
		"address":    "456 Market St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
	})
	if w.Code != 201 {
		t.Fatalf("Vendor registration failed: %d - %s", w.Code, w.Body.String())
	}
	resp := parseResponse(w)
	vendorID, _ := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Vendor{}).Where("id = ?", vendorID).Updates(map[string]interface{}{
		"status":      "approved",
		"is_verified": true,
	})

	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Test Cat", "test-cat")

	w = request("POST", "/products/", vendorToken, map[string]interface{}{
		"name":        "Test Product",
		"description": "Test description",
		"category_id": catID,
		"base_price":  499,
		"total_stock": 100,
		"images": []map[string]interface{}{
			{"image_url": "https://example.com/img.jpg", "is_primary": true},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Product creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	prodID, _ := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Product{}).Where("id = ?", prodID).Update("is_approved", true)

	w = request("GET", "/public/products", "", nil)
	if w.Code != 200 {
		t.Fatalf("Public products failed: %d", w.Code)
	}

	w = request("POST", "/cart/items", custToken, map[string]interface{}{
		"product_id": prodID,
		"quantity":   2,
	})
	if w.Code != 201 {
		t.Fatalf("Cart add failed: %d - %s", w.Code, w.Body.String())
	}

	w = request("GET", "/cart/", custToken, nil)
	if w.Code != 200 {
		t.Fatalf("Cart view failed: %d", w.Code)
	}

	w = request("POST", "/orders/", custToken, map[string]interface{}{
		"items": []map[string]interface{}{
			{"product_id": prodID, "quantity": 1},
		},
		"address": map[string]interface{}{
			"full_name": "Test User",
			"phone":     "+919999999999",
			"line_1":    "123 Test St",
			"city":      "Bangalore",
			"state":     "Karnataka",
			"pincode":   "560001",
		},
		"payment_method": "cod",
	})
	if w.Code != 201 {
		t.Fatalf("Order creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	orderData, _ := resp["data"].(map[string]interface{})
	orders, _ := orderData["orders"].([]interface{})
	if len(orders) < 1 {
		t.Fatal("Expected at least 1 order")
	}
}

func TestAdminAuth(t *testing.T) {
	w := request("GET", "/admin/settings", "", nil)
	if w.Code != 401 {
		t.Fatal("Admin endpoint without auth should return 401")
	}
}

func TestConcurrentBookingSameSlot(t *testing.T) {
	ts := time.Now().UnixNano()
	barberEmail := fmt.Sprintf("concur-barber-%d@test.com", ts)
	custPrefix := fmt.Sprintf("concur-cust-%d-", ts)
	password := "TestPass123!"

	barberToken := register(t, "Concur Barber", barberEmail, "+919999999996", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Concurrency Test Shop",
		"address":    "456 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d - %s", w.Code, w.Body.String())
	}
	resp := parseResponse(w)
	barberID, _ := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	// Create 50 customer tokens and fire parallel booking requests for the same slot
	numRequests := 50
	type result struct {
		code   int
		email  string
	}
	resultCh := make(chan result, numRequests)

	for i := 0; i < numRequests; i++ {
		i := i
		go func() {
			custEmail := fmt.Sprintf("%s%d@test.com", custPrefix, i)
			custToken := register(t, fmt.Sprintf("Concur Cust %d", i), custEmail, fmt.Sprintf("+919999990%02d", i), password, "customer")

			w := request("POST", "/bookings", custToken, map[string]interface{}{
				"barber_id":       barberID,
				"service_ids":     []string{svcID},
				"scheduled_start": tomorrow + "T14:00:00+05:30",
			})
			resultCh <- result{code: w.Code, email: custEmail}
		}()
	}

	successCount := 0
	failCount := 0
	for i := 0; i < numRequests; i++ {
		r := <-resultCh
		if r.code == 201 {
			successCount++
		} else {
			failCount++
		}
	}

	if successCount != 1 {
		t.Fatalf("Expected exactly 1 successful booking, got %d (failures: %d)", successCount, failCount)
	}
	t.Logf("PASS: %d concurrent requests, %d succeeded (expected 1), %d rejected", numRequests, successCount, failCount)
}

func TestConcurrentBookingDifferentSlots(t *testing.T) {
	ts := time.Now().UnixNano()
	barberEmail := fmt.Sprintf("diff-barber-%d@test.com", ts)
	custPrefix := fmt.Sprintf("diff-cust-%d-", ts)
	password := "TestPass123!"

	barberToken := register(t, "Diff Barber", barberEmail, "+919999999997", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Different Slot Shop",
		"address":    "789 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d - %s", w.Code, w.Body.String())
	}
	resp := parseResponse(w)
	barberID, _ := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	// 3 customers booking different slots — all should succeed
	slots := []string{
		tomorrow + "T10:00:00+05:30",
		tomorrow + "T10:35:00+05:30",
		tomorrow + "T11:10:00+05:30",
	}

	type slotResult struct {
		slot  string
		code  int
	}
	slotCh := make(chan slotResult, len(slots))

	for i, slot := range slots {
		i := i
		slot := slot
		go func() {
			custEmail := fmt.Sprintf("%s%d@test.com", custPrefix, i)
			custToken := register(t, fmt.Sprintf("Diff Cust %d", i), custEmail, fmt.Sprintf("+919999991%02d", i), password, "customer")

			w := request("POST", "/bookings", custToken, map[string]interface{}{
				"barber_id":       barberID,
				"service_ids":     []string{svcID},
				"scheduled_start": slot,
			})
			slotCh <- slotResult{slot: slot, code: w.Code}
		}()
	}

	successCount := 0
	for i := 0; i < len(slots); i++ {
		r := <-slotCh
		if r.code == 201 {
			successCount++
		} else {
			t.Errorf("Slot %s returned HTTP %d (expected 201)", r.slot, r.code)
		}
	}

	if successCount != len(slots) {
		t.Fatalf("Expected %d successful bookings, got %d", len(slots), successCount)
	}
	t.Logf("PASS: %d different slots, all %d succeeded", len(slots), successCount)
}

func TestServiceBelongsToBarber(t *testing.T) {
	ts := time.Now().UnixNano()
	barber1Email := fmt.Sprintf("svc-barber1-%d@test.com", ts)
	barber2Email := fmt.Sprintf("svc-barber2-%d@test.com", ts)
	custEmail := fmt.Sprintf("svc-cust-%d@test.com", ts)
	password := "TestPass123!"

	// Register two barbers
	barber1Token := register(t, "Svc Barber 1", barber1Email, "+919999999998", password, "barber")
	barber2Token := register(t, "Svc Barber 2", barber2Email, "+919999999999", password, "barber")

	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	// Barber 1 with service
	w1 := request("POST", "/barber/register", barber1Token, map[string]interface{}{
		"shop_name":  "Service Test Shop 1",
		"address":    "111 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w1.Code != 201 {
		t.Fatalf("Barber 1 registration failed: %d", w1.Code)
	}
	resp1 := parseResponse(w1)
	barber1ID := resp1["data"].(map[string]interface{})["id"].(string)

	// Barber 2 with service
	w2 := request("POST", "/barber/register", barber2Token, map[string]interface{}{
		"shop_name":  "Service Test Shop 2",
		"address":    "222 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Shave", "category_id": catID, "price": 149, "duration_minutes": 15},
		},
	})
	if w2.Code != 201 {
		t.Fatalf("Barber 2 registration failed: %d", w2.Code)
	}
	resp2 := parseResponse(w2)
	barber2ID := resp2["data"].(map[string]interface{})["id"].(string)

	// Approve both
	database.DB.Model(&models.Barber{}).Where("id = ?", barber1ID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})
	database.DB.Model(&models.Barber{}).Where("id = ?", barber2ID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	// Get service ID from barber 2
	var svc2ID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barber2ID).Select("id").First(&svc2ID)

	custToken := register(t, "Svc Cust", custEmail, "+919999991000", password, "customer")
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	// Try booking barber 1 with barber 2's service — should fail
	w := request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id":       barber1ID,
		"service_ids":     []string{svc2ID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 400 {
		t.Fatalf("Expected 400 for service mismatch, got %d: %s", w.Code, w.Body.String())
	}
	t.Logf("PASS: Service-belonging check correctly rejected foreign service with HTTP %d", w.Code)
}

func TestQueueProgress(t *testing.T) {
	ts := time.Now().UnixNano()
	barberEmail := fmt.Sprintf("qprog-barber-%d@test.com", ts)
	custPrefix := fmt.Sprintf("qprog-cust-%d-", ts)
	password := "TestPass123!"

	barberToken := register(t, "QProg Barber", barberEmail, "+919999999981", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Queue Progress Shop",
		"address":    "101 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	type bookingInfo struct {
		token string
		id    string
		slot  string
	}
	bookings := make([]bookingInfo, 3)
	customers := []string{"A", "B", "C"}
	slots := []string{
		tomorrow + "T10:00:00+05:30",
		tomorrow + "T10:35:00+05:30",
		tomorrow + "T11:10:00+05:30",
	}

	for i := 0; i < 3; i++ {
		custEmail := fmt.Sprintf("%s-%s-%d@test.com", custPrefix, customers[i], ts)
		custToken := register(t, fmt.Sprintf("QProg %s", customers[i]), custEmail, fmt.Sprintf("+919999992%02d", i), password, "customer")

		w := request("POST", "/bookings", custToken, map[string]interface{}{
			"barber_id":       barberID,
			"service_ids":     []string{svcID},
			"scheduled_start": slots[i],
		})
		if w.Code != 201 {
			t.Fatalf("Booking %s failed: %d", customers[i], w.Code)
		}
		resp := parseResponse(w)
		bookingData := resp["data"].(map[string]interface{})
		bookings[i] = bookingInfo{
			token: custToken,
			id:    bookingData["id"].(string),
			slot:  slots[i],
		}
		if bookingData["queue_position"].(float64) != float64(i+1) {
			t.Fatalf("Customer %s expected position %d, got %v", customers[i], i+1, bookingData["queue_position"])
		}
	}
	t.Log("Initial positions: A=1, B=2, C=3 ✓")

	// Step 0: Barber confirms A (pending → confirmed)
	w = request("PUT", "/barber/bookings/"+bookings[0].id+"/status", barberToken, map[string]interface{}{
		"status": "confirmed",
		"notes":  "Confirming A",
	})
	if w.Code != 200 {
		t.Fatalf("Confirm A failed: %d - %s", w.Code, w.Body.String())
	}

	// Step 1: Barber starts A (confirmed → in_progress)
	w = request("PUT", "/barber/bookings/"+bookings[0].id+"/status", barberToken, map[string]interface{}{
		"status": "in_progress",
		"notes":  "Starting A",
	})
	if w.Code != 200 {
		t.Fatalf("Start A failed: %d - %s", w.Code, w.Body.String())
	}

	// Check B's queue position — should still be 2
	w = request("GET", "/barber/queue/"+bookings[1].id, bookings[1].token, nil)
	if w.Code != 200 {
		t.Fatalf("Fetch B position failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data := resp["data"].(map[string]interface{})
	if data["current_position"].(float64) != 2 {
		t.Fatalf("After starting A, B expected position 2, got %v", data["current_position"])
	}
	t.Log("After start A: B position = 2 ✓")

	// Step 2: Barber completes A
	w = request("PUT", "/barber/bookings/"+bookings[0].id+"/status", barberToken, map[string]interface{}{
		"status": "completed",
	})
	if w.Code != 200 {
		t.Fatalf("Complete A failed: %d", w.Code)
	}

	// Check B's queue position — should now be 1
	w = request("GET", "/barber/queue/"+bookings[1].id, bookings[1].token, nil)
	if w.Code != 200 {
		t.Fatalf("Fetch B position failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data = resp["data"].(map[string]interface{})
	if data["current_position"].(float64) != 1 {
		t.Fatalf("After completing A, B expected position 1, got %v", data["current_position"])
	}

	// Check C's queue position — should now be 2
	w = request("GET", "/barber/queue/"+bookings[2].id, bookings[2].token, nil)
	if w.Code != 200 {
		t.Fatalf("Fetch C position failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data = resp["data"].(map[string]interface{})
	if data["current_position"].(float64) != 2 {
		t.Fatalf("After completing A, C expected position 2, got %v", data["current_position"])
	}
	t.Log("After complete A: B=1, C=2 ✓")
}

func TestCancelDuringQueue(t *testing.T) {
	ts := time.Now().UnixNano()
	barberEmail := fmt.Sprintf("cancel-barber-%d@test.com", ts)
	custPrefix := fmt.Sprintf("cancel-cust-%d-", ts)
	password := "TestPass123!"

	barberToken := register(t, "Cancel Barber", barberEmail, "+919999999982", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Cancel Queue Shop",
		"address":    "202 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	type bookingInfo struct {
		token string
		id    string
	}
	var customers [3]bookingInfo
	slots := []string{
		tomorrow + "T10:00:00+05:30",
		tomorrow + "T10:35:00+05:30",
		tomorrow + "T11:10:00+05:30",
	}

	for i := 0; i < 3; i++ {
		custEmail := fmt.Sprintf("%s-%d-%d@test.com", custPrefix, i, ts)
		custToken := register(t, fmt.Sprintf("Cancel %d", i), custEmail, fmt.Sprintf("+919999993%02d", i), password, "customer")

		w := request("POST", "/bookings", custToken, map[string]interface{}{
			"barber_id":       barberID,
			"service_ids":     []string{svcID},
			"scheduled_start": slots[i],
		})
		if w.Code != 201 {
			t.Fatalf("Booking %d failed: %d", i, w.Code)
		}
		resp := parseResponse(w)
		data := resp["data"].(map[string]interface{})
		customers[i] = bookingInfo{token: custToken, id: data["id"].(string)}
		if data["queue_position"].(float64) != float64(i+1) {
			t.Fatalf("Customer %d expected position %d, got %v", i, i+1, data["queue_position"])
		}
	}
	t.Log("Initial positions: A=1, B=2, C=3 ✓")

	// B cancels
	w = request("POST", "/bookings/"+customers[1].id+"/cancel", customers[1].token, map[string]interface{}{
		"reason": "Changed mind",
	})
	if w.Code != 200 {
		t.Fatalf("Cancel B failed: %d", w.Code)
	}

	// Verify A still at position 1
	w = request("GET", "/barber/queue/"+customers[0].id, customers[0].token, nil)
	if w.Code != 200 {
		t.Fatalf("Fetch A position failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data := resp["data"].(map[string]interface{})
	if data["current_position"].(float64) != 1 {
		t.Fatalf("After B cancels, A expected position 1, got %v", data["current_position"])
	}

	// Verify C promoted to position 2
	w = request("GET", "/barber/queue/"+customers[2].id, customers[2].token, nil)
	if w.Code != 200 {
		t.Fatalf("Fetch C position failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data = resp["data"].(map[string]interface{})
	if data["current_position"].(float64) != 2 {
		t.Fatalf("After B cancels, C expected position 2, got %v", data["current_position"])
	}
	t.Log("After B cancels: A=1, C=2 ✓")
}

func TestNoShowPromotion(t *testing.T) {
	ts := time.Now().UnixNano()
	barberEmail := fmt.Sprintf("noshow-barber-%d@test.com", ts)
	custPrefix := fmt.Sprintf("noshow-cust-%d-", ts)
	password := "TestPass123!"

	barberToken := register(t, "NoShow Barber", barberEmail, "+919999999983", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "NoShow Test Shop",
		"address":    "303 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	// Customer A books at 10:00
	custAEmail := fmt.Sprintf("%s-A-%d@test.com", custPrefix, ts)
	custAToken := register(t, "NoShow A", custAEmail, "+91999999401", password, "customer")
	w = request("POST", "/bookings", custAToken, map[string]interface{}{
		"barber_id":       barberID,
		"service_ids":     []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking A failed: %d", w.Code)
	}
	resp = parseResponse(w)
	aID := resp["data"].(map[string]interface{})["id"].(string)

	// Customer B books at 10:35
	custBEmail := fmt.Sprintf("%s-B-%d@test.com", custPrefix, ts)
	custBToken := register(t, "NoShow B", custBEmail, "+91999999402", password, "customer")
	w = request("POST", "/bookings", custBToken, map[string]interface{}{
		"barber_id":       barberID,
		"service_ids":     []string{svcID},
		"scheduled_start": tomorrow + "T10:35:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking B failed: %d", w.Code)
	}
	resp = parseResponse(w)
	bID := resp["data"].(map[string]interface{})["id"].(string)
	if resp["data"].(map[string]interface{})["queue_position"].(float64) != 2 {
		t.Fatalf("B expected position 2, got %v", resp["data"].(map[string]interface{})["queue_position"])
	}
	t.Log("Initial: A=1, B=2 ✓")

	// Confirm A first (pending → confirmed) then mark no-show
	w = request("PUT", "/barber/bookings/"+aID+"/status", barberToken, map[string]interface{}{
		"status": "confirmed",
	})
	if w.Code != 200 {
		t.Fatalf("Confirm A failed: %d", w.Code)
	}

	w = request("PUT", "/barber/bookings/"+aID+"/status", barberToken, map[string]interface{}{
		"status": "no_show",
		"notes":  "Did not arrive",
	})
	if w.Code != 200 {
		t.Fatalf("NoShow A failed: %d", w.Code)
	}

	// B should now be promoted to position 1
	w = request("GET", "/barber/queue/"+bID, custBToken, nil)
	if w.Code != 200 {
		t.Fatalf("Fetch B position failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data := resp["data"].(map[string]interface{})
	if data["current_position"].(float64) != 1 {
		t.Fatalf("After no-show, B expected position 1, got %v", data["current_position"])
	}
	t.Log("After A no-show: B=1 ✓")
}

func TestBarberAvailability(t *testing.T) {
	ts := time.Now().UnixNano()
	email := fmt.Sprintf("avail-%d@test.com", ts)
	token := register(t, "Avail Barber", email, "+919999999995", "TestPass123!", "barber")

	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", token, map[string]interface{}{
		"shop_name":  "Avail Shop",
		"address":    "123 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}

	w = request("PUT", "/barber/availability", token, map[string]interface{}{
		"is_available": false,
	})
	if w.Code != 200 {
		t.Fatalf("Availability update failed: %d - %s", w.Code, w.Body.String())
	}
}

func TestCreateReview_Valid(t *testing.T) {
	ts := time.Now().UnixNano()
	password := "TestPass123!"

	barberToken := register(t, "Review Barber", fmt.Sprintf("rev-barber-%d@test.com", ts), "+919999999961", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Review Test Shop",
		"address":    "999 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved",
		"is_verified":         true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)

	custToken := register(t, "Review Cust", fmt.Sprintf("rev-cust-%d@test.com", ts), "+919999999962", password, "customer")
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	w = request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id":       barberID,
		"service_ids":     []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	bookingID := resp["data"].(map[string]interface{})["id"].(string)

	// Manually mark as completed + paid
	completedAt := time.Now().Add(-1 * time.Hour)
	database.DB.Model(&models.Booking{}).Where("id = ?", bookingID).Updates(map[string]interface{}{
		"status":         models.BookingStatusCompleted,
		"payment_status": "paid",
		"completed_at":   completedAt,
		"actual_end":     completedAt,
	})
	database.DB.Create(&models.BookingStatusLog{
		BookingID:      uuid.MustParse(bookingID),
		ToStatus:       models.BookingStatusCompleted,
		ChangedBy:      uuid.MustParse("00000000-0000-0000-0000-000000000001"),
		ChangedByRole:  "barber",
	})

	// Submit review
	w = request("POST", "/reviews", custToken, map[string]interface{}{
		"booking_id": bookingID,
		"rating":     5,
		"comment":    "Excellent service! Highly recommended.",
	})
	if w.Code != 201 {
		t.Fatalf("Review creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	reviewData := resp["data"].(map[string]interface{})
	if reviewData["rating"].(float64) != 5 {
		t.Fatalf("Expected rating 5, got %v", reviewData["rating"])
	}
	t.Logf("PASS: Valid review created with HTTP %d", w.Code)
}

func TestCreateReview_NotCompleted(t *testing.T) {
	ts := time.Now().UnixNano()
	password := "TestPass123!"

	barberToken := register(t, "RevNC Barber", fmt.Sprintf("revnc-barber-%d@test.com", ts), "+919999999963", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "RevNC Shop", "address": "111 Test St", "city": "Bangalore",
		"state": "Karnataka", "pincode": "560001", "start_time": "09:00", "end_time": "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved", "is_verified": true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)

	custToken := register(t, "RevNC Cust", fmt.Sprintf("revnc-cust-%d@test.com", ts), "+919999999964", password, "customer")
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	w = request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id": barberID, "service_ids": []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	bookingID := resp["data"].(map[string]interface{})["id"].(string)

	w = request("POST", "/reviews", custToken, map[string]interface{}{
		"booking_id": bookingID, "rating": 4, "comment": "Good service!",
	})
	if w.Code != 400 {
		t.Fatalf("Expected 400 for non-completed booking, got %d: %s", w.Code, w.Body.String())
	}
	t.Logf("PASS: Not-completed booking correctly rejected with HTTP %d", w.Code)
}

func TestCreateReview_Duplicate(t *testing.T) {
	ts := time.Now().UnixNano()
	password := "TestPass123!"

	barberToken := register(t, "RevDup Barber", fmt.Sprintf("revdup-barber-%d@test.com", ts), "+919999999965", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name": "RevDup Shop", "address": "222 Test St", "city": "Bangalore",
		"state": "Karnataka", "pincode": "560001", "start_time": "09:00", "end_time": "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved", "is_verified": true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)

	custToken := register(t, "RevDup Cust", fmt.Sprintf("revdup-cust-%d@test.com", ts), "+919999999966", password, "customer")
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	w = request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id": barberID, "service_ids": []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking creation failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	bookingID := resp["data"].(map[string]interface{})["id"].(string)

	completedAt := time.Now().Add(-1 * time.Hour)
	database.DB.Model(&models.Booking{}).Where("id = ?", bookingID).Updates(map[string]interface{}{
		"status": models.BookingStatusCompleted, "payment_status": "paid",
		"completed_at": completedAt, "actual_end": completedAt,
	})

	// First review
	w = request("POST", "/reviews", custToken, map[string]interface{}{
		"booking_id": bookingID, "rating": 5, "comment": "Excellent service! Highly recommended.",
	})
	if w.Code != 201 {
		t.Fatalf("First review failed: %d - %s", w.Code, w.Body.String())
	}

	// Second review — duplicate
	w = request("POST", "/reviews", custToken, map[string]interface{}{
		"booking_id": bookingID, "rating": 3, "comment": "Changed my mind, this is a duplicate.",
	})
	if w.Code != 400 {
		t.Fatalf("Expected 400 for duplicate, got %d: %s", w.Code, w.Body.String())
	}
	t.Logf("PASS: Duplicate review correctly rejected with HTTP %d", w.Code)
}

func TestModerateReview_Approve(t *testing.T) {
	ts := time.Now().UnixNano()
	password := "TestPass123!"

	barberToken := register(t, "ModApp Barber", fmt.Sprintf("modapp-barber-%d@test.com", ts), "+919999999967", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name": "ModApp Shop", "address": "333 Test St", "city": "Bangalore",
		"state": "Karnataka", "pincode": "560001", "start_time": "09:00", "end_time": "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved", "is_verified": true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)

	custToken := register(t, "ModApp Cust", fmt.Sprintf("modapp-cust-%d@test.com", ts), "+919999999968", password, "customer")
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	w = request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id": barberID, "service_ids": []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	bookingID := resp["data"].(map[string]interface{})["id"].(string)

	completedAt := time.Now().Add(-1 * time.Hour)
	database.DB.Model(&models.Booking{}).Where("id = ?", bookingID).Updates(map[string]interface{}{
		"status": models.BookingStatusCompleted, "payment_status": "paid",
		"completed_at": completedAt, "actual_end": completedAt,
	})

	w = request("POST", "/reviews", custToken, map[string]interface{}{
		"booking_id": bookingID, "rating": 5, "comment": "Excellent haircut! Will come again.",
	})
	if w.Code != 201 {
		t.Fatalf("Review creation failed: %d", w.Code)
	}
	resp = parseResponse(w)
	reviewID := resp["data"].(map[string]interface{})["id"].(string)

	// Get admin token
	adminToken := login(t, "admin@barbar.com", "AdminPass123!")

	// Approve the review
	w = request("PUT", "/admin/reviews/"+reviewID+"/moderate", adminToken, map[string]interface{}{
		"status": "approved",
	})
	if w.Code != 200 {
		t.Fatalf("Moderate approve failed: %d - %s", w.Code, w.Body.String())
	}

	// Verify shop rating updated
	var barber models.Barber
	database.DB.First(&barber, "id = ?", barberID)
	if barber.Rating != 5.0 {
		t.Fatalf("Expected shop rating 5.0 after approving 5★ review, got %f", barber.Rating)
	}
	if barber.ReviewCount != 1 {
		t.Fatalf("Expected review count 1, got %d", barber.ReviewCount)
	}
	t.Logf("PASS: Review approved, shop rating=%.1f count=%d", barber.Rating, barber.ReviewCount)
}

func TestListPublicReviews(t *testing.T) {
	ts := time.Now().UnixNano()
	password := "TestPass123!"

	barberToken := register(t, "PubRev Barber", fmt.Sprintf("pubrev-barber-%d@test.com", ts), "+919999999969", password, "barber")
	catID := uuid.New().String()
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT (slug) DO UPDATE SET id = EXCLUDED.id, name = EXCLUDED.name, is_active = EXCLUDED.is_active", catID, "Hair", "hair")

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name": "PubRev Shop", "address": "444 Test St", "city": "Bangalore",
		"state": "Karnataka", "pincode": "560001", "start_time": "09:00", "end_time": "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category_id": catID, "price": 299, "duration_minutes": 30},
		},
	})
	if w.Code != 201 {
		t.Fatalf("Barber registration failed: %d", w.Code)
	}
	resp := parseResponse(w)
	barberID := resp["data"].(map[string]interface{})["id"].(string)

	database.DB.Model(&models.Barber{}).Where("id = ?", barberID).Updates(map[string]interface{}{
		"verification_status": "approved", "is_verified": true,
	})

	var svcID string
	database.DB.Model(&models.BarberService{}).Where("barber_id = ?", barberID).Select("id").First(&svcID)

	// Create customer + booking + complete + review
	custToken := register(t, "PubRev Cust", fmt.Sprintf("pubrev-cust-%d@test.com", ts), "+919999999970", password, "customer")
	tomorrow := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	w = request("POST", "/bookings", custToken, map[string]interface{}{
		"barber_id": barberID, "service_ids": []string{svcID},
		"scheduled_start": tomorrow + "T10:00:00+05:30",
	})
	if w.Code != 201 {
		t.Fatalf("Booking failed: %d - %s", w.Code, w.Body.String())
	}
	resp = parseResponse(w)
	bookingID := resp["data"].(map[string]interface{})["id"].(string)

	completedAt := time.Now().Add(-1 * time.Hour)
	database.DB.Model(&models.Booking{}).Where("id = ?", bookingID).Updates(map[string]interface{}{
		"status": models.BookingStatusCompleted, "payment_status": "paid",
		"completed_at": completedAt, "actual_end": completedAt,
	})

	w = request("POST", "/reviews", custToken, map[string]interface{}{
		"booking_id": bookingID, "rating": 4, "comment": "Good service, nice staff!",
	})
	if w.Code != 201 {
		t.Fatalf("Review failed: %d", w.Code)
	}
	resp = parseResponse(w)
	reviewID := resp["data"].(map[string]interface{})["id"].(string)

	// Admin approves
	adminToken := login(t, "admin@barbar.com", "AdminPass123!")
	w = request("PUT", "/admin/reviews/"+reviewID+"/moderate", adminToken, map[string]interface{}{
		"status": "approved",
	})
	if w.Code != 200 {
		t.Fatalf("Approve failed: %d", w.Code)
	}

	// Public endpoint — should show the review
	w = request("GET", "/public/barbers/"+barberID+"/reviews", "", nil)
	if w.Code != 200 {
		t.Fatalf("Public reviews failed: %d", w.Code)
	}
	resp = parseResponse(w)
	data := resp["data"].(map[string]interface{})
	reviews := data["reviews"].([]interface{})
	if len(reviews) != 1 {
		t.Fatalf("Expected 1 approved review, got %d", len(reviews))
	}
	summary := data["summary"].(map[string]interface{})
	if summary["avg_rating"].(float64) != 4.0 {
		t.Fatalf("Expected avg_rating 4.0, got %f", summary["avg_rating"].(float64))
	}
	t.Logf("PASS: Public reviews endpoint returns %d approved review, avg=%.1f", len(reviews), summary["avg_rating"].(float64))
}

func TestPublicEndpoints(t *testing.T) {
	paths := []string{
		"/public/barbers",
		"/public/products",
		"/public/categories",
	}
	for _, path := range paths {
		w := request("GET", path, "", nil)
		if w.Code != 200 {
			t.Fatalf("GET %s failed: %d - %s", path, w.Code, w.Body.String())
		}
	}
}
