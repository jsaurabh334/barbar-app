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
	os.Setenv("DB_NAME", "barbar_app_test")
	os.Setenv("DB_USER", "saurabhjain")
	os.Setenv("DB_PASSWORD", "")
	os.Setenv("JWT_SECRET", "test-secret-for-integration-tests-32-chars!!")
	os.Setenv("REDIS_HOST", "localhost")
	os.Setenv("REDIS_PORT", "6379")

	gin.SetMode(gin.TestMode)

	cfg := config.Load()
	db := database.InitPostgres(&cfg.Database)

	if err := db.Exec("DROP SCHEMA public CASCADE").Error; err != nil {
		panic("Failed to drop schema: " + err.Error())
	}
	if err := db.Exec("CREATE SCHEMA public").Error; err != nil {
		panic("Failed to create schema: " + err.Error())
	}
	database.RunMigrations(db)
	database.SeedData(db, &cfg.App)

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

	w := request("POST", "/barber/register", barberToken, map[string]interface{}{
		"shop_name":  "Test Barber Shop",
		"address":    "123 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "description": "Classic cut", "category": "hair", "price": 299, "duration_minutes": 30},
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

	w = request("POST", "/bookings/", custToken, map[string]interface{}{
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
	database.DB.Exec("INSERT INTO categories (id, name, slug, is_active) VALUES (?, ?, ?, true) ON CONFLICT DO NOTHING", catID, "Test Cat", "test-cat")

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

func TestBarberAvailability(t *testing.T) {
	ts := time.Now().UnixNano()
	email := fmt.Sprintf("avail-%d@test.com", ts)
	token := register(t, "Avail Barber", email, "+919999999995", "TestPass123!", "barber")

	w := request("POST", "/barber/register", token, map[string]interface{}{
		"shop_name":  "Avail Shop",
		"address":    "123 Test St",
		"city":       "Bangalore",
		"state":      "Karnataka",
		"pincode":    "560001",
		"start_time": "09:00",
		"end_time":   "21:00",
		"services": []map[string]interface{}{
			{"name": "Haircut", "category": "hair", "price": 299, "duration_minutes": 30},
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
