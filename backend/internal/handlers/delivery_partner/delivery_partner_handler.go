package delivery_partner

import (
    "errors"
    "math"
    "strconv"
    "strings"
    "time"



    "github.com/barbar-app/backend/internal/models"
    "github.com/barbar-app/backend/internal/utils"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

type DeliveryPartnerHandler struct {
    db *gorm.DB
}

func NewDeliveryPartnerHandler(db *gorm.DB) *DeliveryPartnerHandler {
    return &DeliveryPartnerHandler{db: db}
}

type RegisterDeliveryPartnerRequest struct {
    VehicleType   string  `json:"vehicle_type" binding:"required"`
    LicenseNumber string  `json:"license_number" binding:"required"`
    Latitude      float64 `json:"latitude"`
    Longitude     float64 `json:"longitude"`
}

// Register creates a new delivery partner profile linked to the authenticated user.
// Register creates a new delivery partner profile linked to the authenticated user.
// @Summary Register Delivery Partner
// @Tags DeliveryPartner
// @Accept json
// @Produce json
// @Param body body RegisterDeliveryPartnerRequest true "Register payload"
// @Success 201 {object} map[string]interface{} "Created"
// @Failure 400 {object} map[string]interface{} "Bad Request"
// @Failure 500 {object} map[string]interface{} "Internal Error"
// @Router /delivery-partners/register [post]
func (h *DeliveryPartnerHandler) Register(c *gin.Context) {
    userID := c.MustGet("user").(uuid.UUID)
    // Ensure user does not already have a delivery partner profile
    var existing models.DeliveryPartner
    if err := h.db.Where("user_id = ?", userID).First(&existing).Error; err == nil {
        // Duplicate exists
        utils.BadRequestResponse(c, "Delivery partner profile already exists")
        return
    } else if !errors.Is(err, gorm.ErrRecordNotFound) {
        // Unexpected DB error
        utils.InternalErrorResponse(c, "Failed to check existing delivery partner")
        return
    }

    var req RegisterDeliveryPartnerRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.BadRequestResponse(c, "Invalid input: "+err.Error())
        return
    }

    partner := models.DeliveryPartner{
        ID:               uuid.New(),
        UserID:           userID,
        VehicleType:      req.VehicleType,
        LicenseNumber:    req.LicenseNumber,
        CurrentLatitude:  req.Latitude,
        CurrentLongitude: req.Longitude,
        AvailabilityStatus: models.DeliveryPartnerStatusAvailable,
        CreatedAt:        time.Now(),
        UpdatedAt:        time.Now(),
    }

    // Attempt to create the delivery partner profile
    if err := h.db.Create(&partner).Error; err != nil {
        // Check for duplicate unique constraint violation (user_id)
        if strings.Contains(err.Error(), "UNIQUE constraint failed") || strings.Contains(err.Error(), "duplicate key") {
            utils.BadRequestResponse(c, "Delivery partner profile already exists")
        } else {
            utils.InternalErrorResponse(c, "Failed to create delivery partner profile")
        }
        return
    }
    utils.CreatedResponse(c, partner)
}

// GetProfile returns the delivery partner profile of the authenticated user.
// GetProfile returns the delivery partner profile of the authenticated user.
// @Summary Get Delivery Partner Profile
// @Tags DeliveryPartner
// @Produce json
// @Success 200 {object} map[string]interface{} "Success"
// @Failure 404 {object} map[string]interface{} "Not Found"
// @Failure 500 {object} map[string]interface{} "Internal Error"
// @Router /delivery-partners/profile [get]
func (h *DeliveryPartnerHandler) GetProfile(c *gin.Context) {
    userID := c.MustGet("user").(uuid.UUID)
    var partner models.DeliveryPartner
    if err := h.db.Where("user_id = ?", userID).First(&partner).Error; err != nil {
        utils.NotFoundResponse(c, "Delivery partner profile not found")
        return
    }
    utils.SuccessResponse(c, partner)
}

type UpdateLocationRequest struct {
    Latitude  float64 `json:"latitude" binding:"required"`
    Longitude float64 `json:"longitude" binding:"required"`
}

// UpdateLocation allows the partner to update its current GPS coordinates.
// UpdateLocation allows the partner to update its current GPS coordinates.
// @Summary Update Delivery Partner Location
// @Tags DeliveryPartner
// @Accept json
// @Produce json
// @Param body body UpdateLocationRequest true "Location payload"
// @Success 200 {object} map[string]interface{} "Location updated"
// @Failure 400 {object} map[string]interface{} "Bad Request"
// @Failure 500 {object} map[string]interface{} "Internal Error"
// @Router /delivery-partners/location [put]
func (h *DeliveryPartnerHandler) UpdateLocation(c *gin.Context) {
    userID := c.MustGet("user").(uuid.UUID)
    var req UpdateLocationRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.BadRequestResponse(c, "Invalid input: "+err.Error())
        return
    }
    if err := h.db.Model(&models.DeliveryPartner{}).Where("user_id = ?", userID).
        Updates(map[string]interface{}{"current_latitude": req.Latitude, "current_longitude": req.Longitude, "updated_at": time.Now()}).Error; err != nil {
        utils.InternalErrorResponse(c, "Failed to update location")
        return
    }
    utils.SuccessResponse(c, gin.H{"message": "Location updated"})
}

type UpdateAvailabilityRequest struct {
    Status string `json:"status" binding:"required,oneof=available busy offline"`
}

// UpdateAvailability enables the partner to change its availability status.
// UpdateAvailability enables the partner to change its availability status.
// @Summary Update Delivery Partner Availability
// @Tags DeliveryPartner
// @Accept json
// @Produce json
// @Param body body UpdateAvailabilityRequest true "Availability payload"
// @Success 200 {object} map[string]interface{} "Availability updated"
// @Failure 400 {object} map[string]interface{} "Bad Request"
// @Failure 500 {object} map[string]interface{} "Internal Error"
// @Router /delivery-partners/availability [put]
func (h *DeliveryPartnerHandler) UpdateAvailability(c *gin.Context) {
    userID := c.MustGet("user").(uuid.UUID)
    var req UpdateAvailabilityRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.BadRequestResponse(c, "Invalid input: "+err.Error())
        return
    }
    if err := h.db.Model(&models.DeliveryPartner{}).Where("user_id = ?", userID).
        Update("availability_status", req.Status).Error; err != nil {
        utils.InternalErrorResponse(c, "Failed to update availability")
        return
    }
    utils.SuccessResponse(c, gin.H{"message": "Availability updated"})
}

// ListNearby returns delivery partners near a given location (public endpoint).
// ListNearby returns delivery partners near a given location (public endpoint).
// @Summary List Nearby Delivery Partners
// @Tags DeliveryPartner
// @Produce json
// @Param lat query string false "Latitude"
// @Param lng query string false "Longitude"
// @Param radius query string false "Radius in km"
// @Success 200 {object} []models.DeliveryPartner "List of partners"
// @Failure 500 {object} map[string]interface{} "Internal Error"
// @Router /delivery-partners/nearby [get]
func (h *DeliveryPartnerHandler) ListNearby(c *gin.Context) {
    lat, _ := strconv.ParseFloat(c.Query("lat"), 64)
    lng, _ := strconv.ParseFloat(c.Query("lng"), 64)
    radius, _ := strconv.ParseFloat(c.Query("radius"), 64)
    if radius == 0 {
        radius = 10
    }

    var allPartners []models.DeliveryPartner
    h.db.Where("availability_status = ?", models.DeliveryPartnerStatusAvailable).Find(&allPartners)

    var nearbyPartners []models.DeliveryPartner
    for _, p := range allPartners {
        d := haversine(lat, lng, p.CurrentLatitude, p.CurrentLongitude)
        if d <= radius {
            nearbyPartners = append(nearbyPartners, p)
        }
    }
    utils.SuccessResponse(c, nearbyPartners)
}

func haversine(lat1, lon1, lat2, lon2 float64) float64 {
    const R = 6371
    dLat := (lat2 - lat1) * (math.Pi / 180)
    dLon := (lon2 - lon1) * (math.Pi / 180)
    a := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(lat1*(math.Pi/180))*math.Cos(lat2*(math.Pi/180))*math.Sin(dLon/2)*math.Sin(dLon/2)
    return R * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}
