package tracking

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/barbar-app/backend/internal/models"
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TrackingResponse struct {
	Version  int              `json:"version"`
	Status   models.OrderStatus `json:"status"`
	Driver   *DriverInfo      `json:"driver,omitempty"`
	Warehouse *WarehouseInfo  `json:"warehouse,omitempty"`
	Customer   *CustomerInfo    `json:"customer,omitempty"`
	ETA        *ETAInfo         `json:"eta,omitempty"`
	Timeline   []TimelineEntry  `json:"timeline"`
	DeliveryOTP     *string `json:"delivery_otp,omitempty"`
	ExpiresInSeconds *int64 `json:"expires_in_seconds,omitempty"`
}

type DriverInfo struct {
	ID            string  `json:"id"`
	Name          string  `json:"name"`
	Avatar        string  `json:"avatar"`
	Phone         string  `json:"phone"`
	VehicleType   string  `json:"vehicle_type"`
	VehicleNumber string  `json:"vehicle_number"`
	Rating        float64 `json:"rating"`
	Latitude      *float64 `json:"latitude,omitempty"`
	Longitude     *float64 `json:"longitude,omitempty"`
	Bearing       *float64 `json:"bearing,omitempty"`
	Speed         *float64 `json:"speed,omitempty"`
}

type WarehouseInfo struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Address   string  `json:"address"`
}

type CustomerInfo struct {
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	FullAddress string  `json:"full_address"`
}

type ETAInfo struct {
	Minutes    float64 `json:"minutes"`
	DistanceKM float64 `json:"distance_km"`
}

type TimelineEntry struct {
	Status    models.OrderStatus `json:"status"`
	Timestamp time.Time          `json:"timestamp"`
	Note      string             `json:"note,omitempty"`
}

type Service struct {
	db           *gorm.DB
	presenceSvc  *deliverySvc.PresenceService
}

func NewService(db *gorm.DB, presenceSvc *deliverySvc.PresenceService) *Service {
	return &Service{
		db:          db,
		presenceSvc: presenceSvc,
	}
}

func (s *Service) GetTracking(ctx context.Context, orderID uuid.UUID) (*TrackingResponse, error) {
	var order models.Order
	err := s.db.
		Preload("StatusLog").
		Preload("DeliveryPartner").
		Preload("PickupWarehouse").
		Preload("ShippingAddress").
		First(&order, orderID).Error
	if err != nil {
		return nil, fmt.Errorf("order not found: %w", err)
	}

	resp := &TrackingResponse{
		Version:  1,
		Status:   order.Status,
		Timeline: make([]TimelineEntry, 0),
	}

	// Timeline from DB (always available)
	for _, log := range order.StatusLog {
		resp.Timeline = append(resp.Timeline, TimelineEntry{
			Status:    log.ToStatus,
			Timestamp: log.CreatedAt,
			Note:      log.Note,
		})
	}

	// Warehouse from DB
	if order.PickupWarehouse != nil {
		resp.Warehouse = &WarehouseInfo{
			ID:        order.PickupWarehouse.ID.String(),
			Name:      order.PickupWarehouse.Name,
			Latitude:  order.PickupWarehouse.Latitude,
			Longitude: order.PickupWarehouse.Longitude,
			Address:   order.PickupWarehouse.Address,
		}
	}

	// Customer delivery address from DB
	if order.ShippingAddress != nil {
		resp.Customer = &CustomerInfo{
			Latitude:    order.ShippingAddress.Latitude,
			Longitude:   order.ShippingAddress.Longitude,
			FullAddress: buildFullAddress(order.ShippingAddress),
		}
	}

	// Driver info from DB + Redis overlay
	if order.DeliveryPartner != nil && order.DeliveryPartnerID != nil {
		driverInfo := &DriverInfo{
			ID:   order.DeliveryPartner.ID.String(),
			Name: order.DeliveryPartner.FullName,
		}
		if order.DeliveryPartner.Avatar != "" {
			driverInfo.Avatar = order.DeliveryPartner.Avatar
		}
		if order.DeliveryPartner.Phone != "" {
			driverInfo.Phone = order.DeliveryPartner.Phone
		}

		// Fetch DeliveryPartner details (vehicle, rating) — need another query
		var dp models.DeliveryPartner
		if err := s.db.Where("user_id = ?", *order.DeliveryPartnerID).First(&dp).Error; err == nil {
			driverInfo.VehicleType = dp.VehicleType
			driverInfo.VehicleNumber = dp.VehicleNumber
			driverInfo.Rating = dp.Rating
		}

		// Redis overlay: live GPS if available
		presence, err := s.presenceSvc.GetPresence(ctx, *order.DeliveryPartnerID)
		if err == nil {
			if lat, ok := parseFloatPtr(presence["latitude"]); ok {
				driverInfo.Latitude = lat
			}
			if lng, ok := parseFloatPtr(presence["longitude"]); ok {
				driverInfo.Longitude = lng
			}
			if bearing, ok := parseFloatPtr(presence["bearing"]); ok {
				driverInfo.Bearing = bearing
			}
			if speed, ok := parseFloatPtr(presence["speed"]); ok {
				driverInfo.Speed = speed
			}
		}

		resp.Driver = driverInfo
	}

	// ETA from Redis overlay
	eta, err := s.presenceSvc.GetETA(ctx, orderID)
	if err == nil {
		resp.ETA = &ETAInfo{
			Minutes:    eta["eta_minutes"],
			DistanceKM: eta["distance_km"],
		}
	}

	// Delivery OTP — only for active deliveries
	if order.Status == models.OrderStatusOutForDelivery || order.Status == models.OrderStatusPickedUp {
		var deliveryOTP models.DeliveryOTP
		if err := s.db.Where("order_id = ? AND verified_at IS NULL", order.ID).First(&deliveryOTP).Error; err == nil {
			otpVal := deliveryOTP.OTP
			resp.DeliveryOTP = &otpVal
			remaining := int64(time.Until(deliveryOTP.ExpiresAt).Seconds())
			if remaining > 0 {
				resp.ExpiresInSeconds = &remaining
			}
		}
	}

	return resp, nil
}

func buildFullAddress(addr *models.Address) string {
	result := addr.Line1
	if addr.Line2 != "" {
		result += ", " + addr.Line2
	}
	if addr.Landmark != "" {
		result += ", " + addr.Landmark
	}
	result += ", " + addr.City + ", " + addr.State
	if addr.Pincode != "" {
		result += " - " + addr.Pincode
	}
	return result
}

func parseFloatPtr(s string) (*float64, bool) {
	if s == "" {
		return nil, false
	}
	v, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return nil, false
	}
	return &v, true
}
