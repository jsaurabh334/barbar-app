package delivery_partner

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/barbar-app/backend/internal/models"
    "github.com/barbar-app/backend/internal/utils"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
)

// helper to create a test router with DeliveryPartnerHandler
func setupTestRouter(t *testing.T) (*gin.Engine, *gorm.DB) {
    gin.SetMode(gin.TestMode)
    db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
    require.NoError(t, err)
    // Migrate required models
    err = db.AutoMigrate(&models.DeliveryPartner{})
    require.NoError(t, err)

    handler := NewDeliveryPartnerHandler(db)
    r := gin.New()
    // Middleware to inject a dummy user UUID for auth protected routes
    r.Use(func(c *gin.Context) {
        c.Set("user", uuid.New())
        c.Next()
    })
    dp := r.Group("/delivery-partners")
    dp.POST("/register", handler.Register)
    dp.GET("/profile", handler.GetProfile)
    dp.PUT("/location", handler.UpdateLocation)
    dp.PUT("/availability", handler.UpdateAvailability)
    dp.GET("/nearby", handler.ListNearby)
    return r, db
}

func TestRegisterSuccess(t *testing.T) {
    router, _ := setupTestRouter(t)
    payload := map[string]interface{}{
        "vehicle_type":   "bike",
        "license_number": "ABC123",
        "latitude":       12.34,
        "longitude":      56.78,
    }
    body, _ := json.Marshal(payload)
    req, _ := http.NewRequest(http.MethodPost, "/delivery-partners/register", bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusCreated, w.Code)
    var resp utils.Response
    err := json.Unmarshal(w.Body.Bytes(), &resp)
    assert.NoError(t, err)
    assert.Equal(t, utils.StatusCreated, resp.Status)
}

func TestRegisterDuplicate(t *testing.T) {
    router, db := setupTestRouter(t)
    // Create an existing partner directly
    userID := uuid.New()
    dp := models.DeliveryPartner{ID: uuid.New(), UserID: userID, VehicleType: "bike", LicenseNumber: "XYZ"}
    db.Create(&dp)
    // Inject same user ID via middleware
    router.Use(func(c *gin.Context) { c.Set("user", userID); c.Next() })
    payload := map[string]interface{}{ "vehicle_type": "bike", "license_number": "XYZ" }
    body, _ := json.Marshal(payload)
    req, _ := http.NewRequest(http.MethodPost, "/delivery-partners/register", bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestGetProfileNotFound(t *testing.T) {
    router, _ := setupTestRouter(t)
    req, _ := http.NewRequest(http.MethodGet, "/delivery-partners/profile", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestUpdateLocationSuccess(t *testing.T) {
    router, db := setupTestRouter(t)
    userID := uuid.New()
    // Create profile first
    db.Create(&models.DeliveryPartner{ID: uuid.New(), UserID: userID, VehicleType: "bike", LicenseNumber: "ABC"})
    router.Use(func(c *gin.Context) { c.Set("user", userID); c.Next() })
    payload := map[string]float64{"latitude": 10.0, "longitude": 20.0}
    body, _ := json.Marshal(payload)
    req, _ := http.NewRequest(http.MethodPut, "/delivery-partners/location", bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusOK, w.Code)
}

func TestUpdateAvailabilitySuccess(t *testing.T) {
    router, db := setupTestRouter(t)
    userID := uuid.New()
    db.Create(&models.DeliveryPartner{ID: uuid.New(), UserID: userID, VehicleType: "bike", LicenseNumber: "ABC"})
    router.Use(func(c *gin.Context) { c.Set("user", userID); c.Next() })
    payload := map[string]string{"status": "busy"}
    body, _ := json.Marshal(payload)
    req, _ := http.NewRequest(http.MethodPut, "/delivery-partners/availability", bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusOK, w.Code)
}

func TestListNearby(t *testing.T) {
    router, db := setupTestRouter(t)
    // create two partners, one available within radius
    db.Create(&models.DeliveryPartner{ID: uuid.New(), UserID: uuid.New(), VehicleType: "bike", LicenseNumber: "A", CurrentLatitude: 12.0, CurrentLongitude: 77.0, AvailabilityStatus: models.DeliveryPartnerStatusAvailable})
    db.Create(&models.DeliveryPartner{ID: uuid.New(), UserID: uuid.New(), VehicleType: "bike", LicenseNumber: "B", CurrentLatitude: 50.0, CurrentLongitude: 80.0, AvailabilityStatus: models.DeliveryPartnerStatusAvailable})
    req, _ := http.NewRequest(http.MethodGet, "/delivery-partners/nearby?lat=12.0&lng=77.0&radius=20", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    assert.Equal(t, http.StatusOK, w.Code)
    var resp utils.Response
    json.Unmarshal(w.Body.Bytes(), &resp)
    // Expect at least one partner in response data slice
    dataSlice, ok := resp.Data.([]interface{})
    assert.True(t, ok)
    assert.GreaterOrEqual(t, len(dataSlice), 1)
}
