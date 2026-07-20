package delivery

import (
	"context"
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PresenceService struct {
	db    *gorm.DB
	wsHub *websocket.Hub
}

func NewPresenceService(db *gorm.DB, wsHub *websocket.Hub) *PresenceService {
	return &PresenceService{db: db, wsHub: wsHub}
}

func redisKey(userID uuid.UUID) string {
	return "driver:presence:" + userID.String()
}

func (s *PresenceService) SetOnline(ctx context.Context, userID uuid.UUID, deviceID, appVersion string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	key := redisKey(userID)

	err := database.RedisClient.HSet(ctx, key, map[string]interface{}{
		"status":             "online",
		"last_seen_at":       now,
		"last_heartbeat_at":  now,
		"device_id":          deviceID,
		"app_version":        appVersion,
		"current_order_id":   "",
		"latitude":           "",
		"longitude":          "",
	}).Err()
	if err != nil {
		return fmt.Errorf("failed to set online: %w", err)
	}

	s.db.Create(&models.DeliveryPresenceLog{
		DeliveryUserID: userID,
		Status:         models.DriverOnline,
		AppVersion:     appVersion,
		DeviceID:       deviceID,
	})

	s.wsHub.BroadcastToRole("admin", &websocket.WSMessage{
		Type: websocket.MsgDriverOnline,
		Payload: map[string]interface{}{
			"user_id": userID.String(),
			"status":  "online",
		},
	})

	return nil
}

func (s *PresenceService) SetOffline(ctx context.Context, userID uuid.UUID) error {
	now := time.Now().UTC().Format(time.RFC3339)
	key := redisKey(userID)

	err := database.RedisClient.HSet(ctx, key, map[string]interface{}{
		"status":       "offline",
		"last_seen_at": now,
	}).Err()
	if err != nil {
		return fmt.Errorf("failed to set offline: %w", err)
	}

	s.db.Create(&models.DeliveryPresenceLog{
		DeliveryUserID: userID,
		Status:         models.DriverOffline,
	})

	s.wsHub.BroadcastToRole("admin", &websocket.WSMessage{
		Type: websocket.MsgDriverOffline,
		Payload: map[string]interface{}{
			"user_id": userID.String(),
			"status":  "offline",
		},
	})

	return nil
}

func (s *PresenceService) SetBusy(ctx context.Context, userID uuid.UUID, orderID uuid.UUID) error {
	key := redisKey(userID)

	err := database.RedisClient.HSet(ctx, key, map[string]interface{}{
		"status":           "busy",
		"current_order_id": orderID.String(),
	}).Err()
	if err != nil {
		return fmt.Errorf("failed to set busy: %w", err)
	}

	s.db.Create(&models.DeliveryPresenceLog{
		DeliveryUserID: userID,
		Status:         models.DriverBusy,
		CurrentOrderID: &orderID,
	})

	s.wsHub.BroadcastToRole("admin", &websocket.WSMessage{
		Type: websocket.MsgDriverBusy,
		Payload: map[string]interface{}{
			"user_id": userID.String(),
			"status":  "busy",
		},
	})

	return nil
}

func (s *PresenceService) SetAvailable(ctx context.Context, userID uuid.UUID) error {
	key := redisKey(userID)

	err := database.RedisClient.HSet(ctx, key, map[string]interface{}{
		"status":           "online",
		"current_order_id": "",
	}).Err()
	if err != nil {
		return fmt.Errorf("failed to set available: %w", err)
	}

	note := "became available"
	s.db.Create(&models.DeliveryPresenceLog{
		DeliveryUserID: userID,
		Status:         models.DriverOnline,
		Note:           note,
	})

	s.wsHub.BroadcastToRole("admin", &websocket.WSMessage{
		Type: websocket.MsgDriverAvailable,
		Payload: map[string]interface{}{
			"user_id": userID.String(),
			"status":  "online",
		},
	})

	return nil
}

func (s *PresenceService) Heartbeat(ctx context.Context, userID uuid.UUID) error {
	now := time.Now().UTC().Format(time.RFC3339)
	key := redisKey(userID)

	err := database.RedisClient.HSet(ctx, key, map[string]interface{}{
		"last_heartbeat_at": now,
	}).Err()
	if err != nil {
		return fmt.Errorf("failed to update heartbeat: %w", err)
	}

	return nil
}

func (s *PresenceService) GetPresence(ctx context.Context, userID uuid.UUID) (map[string]string, error) {
	key := redisKey(userID)

	result, err := database.RedisClient.HGetAll(ctx, key).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to get presence: %w", err)
	}

	if len(result) == 0 {
		return nil, fmt.Errorf("presence not found for driver %s", userID)
	}

	return result, nil
}

func (s *PresenceService) IsEligibleForAssignment(ctx context.Context, userID uuid.UUID) (bool, error) {
	key := redisKey(userID)

	result, err := database.RedisClient.HGetAll(ctx, key).Result()
	if err != nil {
		return false, fmt.Errorf("failed to check eligibility: %w", err)
	}

	if len(result) == 0 {
		return false, fmt.Errorf("driver %s has no presence record (offline)", userID)
	}

	if result["status"] != "online" {
		return false, fmt.Errorf("driver %s is not online (status: %s)", userID, result["status"])
	}

	if result["current_order_id"] != "" {
		return false, fmt.Errorf("driver %s already has an active order", userID)
	}

	return true, nil
}

func (s *PresenceService) ListOnlineDrivers(ctx context.Context) ([]map[string]string, error) {
	iter := database.RedisClient.Scan(ctx, 0, "driver:presence:*", 0).Iterator()

	var drivers []map[string]string
	for iter.Next(ctx) {
		result, err := database.RedisClient.HGetAll(ctx, iter.Val()).Result()
		if err != nil {
			continue
		}
		if result["status"] == "online" {
			result["user_id"] = iter.Val()[len("driver:presence:"):]
			drivers = append(drivers, result)
		}
	}

	if err := iter.Err(); err != nil {
		return nil, fmt.Errorf("failed to scan drivers: %w", err)
	}

	return drivers, nil
}

func (s *PresenceService) GetPresenceSummary(ctx context.Context) (map[string]int, error) {
	iter := database.RedisClient.Scan(ctx, 0, "driver:presence:*", 0).Iterator()

	summary := map[string]int{"online": 0, "busy": 0, "offline": 0}
	for iter.Next(ctx) {
		status, err := database.RedisClient.HGet(ctx, iter.Val(), "status").Result()
		if err != nil {
			continue
		}
		if _, ok := summary[status]; ok {
			summary[status]++
		}
	}

	if err := iter.Err(); err != nil {
		return nil, fmt.Errorf("failed to scan drivers: %w", err)
	}

	return summary, nil
}

type LocationUpdate struct {
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Accuracy  float64   `json:"accuracy,omitempty"`
	Speed     float64   `json:"speed,omitempty"`
	Bearing   float64   `json:"bearing,omitempty"`
	Timestamp time.Time `json:"timestamp"`
}

func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const R = 6371000
	dLat := (lat2 - lat1) * (math.Pi / 180)
	dLon := (lon2 - lon1) * (math.Pi / 180)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(lat1*(math.Pi/180))*math.Cos(lat2*(math.Pi/180))*math.Sin(dLon/2)*math.Sin(dLon/2)
	return R * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

func (s *PresenceService) calculateETA(ctx context.Context, lat, lng, speed float64, orderID uuid.UUID) (etaMinutes, distanceKm float64, err error) {
	var order models.Order
	if err := s.db.Preload("ShippingAddress").First(&order, orderID).Error; err != nil {
		return 0, 0, fmt.Errorf("failed to fetch order: %w", err)
	}

	if order.ShippingAddress == nil {
		return 0, 0, fmt.Errorf("order has no shipping address")
	}

	destLat := order.ShippingAddress.Latitude
	destLng := order.ShippingAddress.Longitude
	if destLat == 0 && destLng == 0 {
		return 0, 0, fmt.Errorf("shipping address has no coordinates")
	}

	distMeters := haversine(lat, lng, destLat, destLng)
	distanceKm = distMeters / 1000

	avgSpeed := speed
	if avgSpeed <= 0 {
		avgSpeed = 5.0
	}

	etaSeconds := distMeters / avgSpeed
	etaMinutes = etaSeconds / 60

	return etaMinutes, distanceKm, nil
}

func (s *PresenceService) UpdateLocation(ctx context.Context, userID uuid.UUID, loc LocationUpdate, orderID *uuid.UUID) (bool, error) {
	key := redisKey(userID)

	presence, err := database.RedisClient.HGetAll(ctx, key).Result()
	if err != nil {
		return false, fmt.Errorf("failed to get presence: %w", err)
	}
	if len(presence) == 0 {
		return false, fmt.Errorf("driver %s has no presence record", userID)
	}

	status := presence["status"]
	if status != "online" && status != "busy" {
		return false, fmt.Errorf("driver %s is not online or busy (status: %s)", userID, status)
	}

	if time.Since(loc.Timestamp) > 30*time.Second {
		return false, fmt.Errorf("location timestamp is stale (>30 seconds old)")
	}

	prevLatStr := presence["latitude"]
	prevLngStr := presence["longitude"]
	prevUpdatedStr := presence["updated_at"]

	if prevLatStr != "" && prevLngStr != "" && prevUpdatedStr != "" {
		var prevLat, prevLng float64
		fmt.Sscanf(prevLatStr, "%f", &prevLat)
		fmt.Sscanf(prevLngStr, "%f", &prevLng)
		prevUpdated, parseErr := time.Parse(time.RFC3339, prevUpdatedStr)
		if parseErr == nil {
			dist := haversine(prevLat, prevLng, loc.Latitude, loc.Longitude)
			elapsed := time.Since(prevUpdated)
			if dist < 20 && elapsed < 5*time.Second {
				return false, nil
			}
		}
	}

	now := time.Now().UTC()
	updatedAt := now.Format(time.RFC3339)

	err = database.RedisClient.HSet(ctx, key, map[string]interface{}{
		"latitude":     fmt.Sprintf("%.7f", loc.Latitude),
		"longitude":    fmt.Sprintf("%.7f", loc.Longitude),
		"speed":        fmt.Sprintf("%.2f", loc.Speed),
		"bearing":      fmt.Sprintf("%.2f", loc.Bearing),
		"accuracy":     fmt.Sprintf("%.2f", loc.Accuracy),
		"updated_at":   updatedAt,
		"last_seen_at": updatedAt,
	}).Err()
	if err != nil {
		return false, fmt.Errorf("failed to update location: %w", err)
	}

	var etaMinutes, distanceKm float64
	if orderID != nil {
		etaMinutes, distanceKm, _ = s.calculateETA(ctx, loc.Latitude, loc.Longitude, loc.Speed, *orderID)
		if etaMinutes > 0 {
			etaKey := "driver:eta:" + orderID.String()
			database.RedisClient.HSet(ctx, etaKey, map[string]interface{}{
				"eta_minutes": fmt.Sprintf("%.1f", etaMinutes),
				"distance_km": fmt.Sprintf("%.2f", distanceKm),
				"updated_at":  updatedAt,
			})
		}
	}

	wsPayload := map[string]interface{}{
		"version":   1,
		"event":     "driver.location_updated",
		"user_id":   userID.String(),
		"latitude":  loc.Latitude,
		"longitude": loc.Longitude,
		"speed":     loc.Speed,
		"bearing":   loc.Bearing,
		"accuracy":  loc.Accuracy,
		"timestamp": loc.Timestamp,
	}

	if orderID != nil {
		orderPayload := map[string]interface{}{
			"version":  1,
			"event":    "driver.location_updated",
			"order_id": orderID.String(),
			"driver": map[string]interface{}{
				"latitude":  loc.Latitude,
				"longitude": loc.Longitude,
				"bearing":   loc.Bearing,
				"speed":     loc.Speed,
			},
		}
		if etaMinutes > 0 {
			orderPayload["eta"] = map[string]interface{}{
				"minutes":     etaMinutes,
				"distance_km": distanceKm,
			}
		}
		s.wsHub.SendToRoom("order:"+orderID.String(), &websocket.WSMessage{
			Type:    websocket.MsgDriverLocation,
			Payload: orderPayload,
		})
	}

	s.wsHub.BroadcastToRole("admin", &websocket.WSMessage{
		Type:    websocket.MsgDriverLocation,
		Payload: wsPayload,
	})

	return true, nil
}

func (s *PresenceService) GetETA(ctx context.Context, orderID uuid.UUID) (map[string]float64, error) {
	key := "driver:eta:" + orderID.String()
	result, err := database.RedisClient.HGetAll(ctx, key).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to get ETA: %w", err)
	}
	if len(result) == 0 {
		return nil, fmt.Errorf("ETA not found for order %s", orderID)
	}

	eta, _ := strconv.ParseFloat(result["eta_minutes"], 64)
	dist, _ := strconv.ParseFloat(result["distance_km"], 64)

	return map[string]float64{
		"eta_minutes": eta,
		"distance_km": dist,
	}, nil
}

func (s *PresenceService) StartStalePresenceCleanup(ctx context.Context) {
	ticker := time.NewTicker(2 * time.Minute)
	go func() {
		for {
			select {
			case <-ticker.C:
				s.cleanupStalePresence(ctx)
			case <-ctx.Done():
				ticker.Stop()
				return
			}
		}
	}()
}

func (s *PresenceService) cleanupStalePresence(ctx context.Context) {
	iter := database.RedisClient.Scan(ctx, 0, "driver:presence:*", 0).Iterator()
	now := time.Now()

	for iter.Next(ctx) {
		key := iter.Val()
		status, err := database.RedisClient.HGet(ctx, key, "status").Result()
		if err != nil || status != "online" {
			continue
		}

		hbStr, err := database.RedisClient.HGet(ctx, key, "last_heartbeat_at").Result()
		if err != nil || hbStr == "" {
			continue
		}

		hbTime, err := time.Parse(time.RFC3339, hbStr)
		if err != nil {
			continue
		}

		if now.Sub(hbTime) > 5*time.Minute {
			userIDStr := key[len("driver:presence:"):]
			userID, parseErr := uuid.Parse(userIDStr)
			if parseErr != nil {
				continue
			}

			database.RedisClient.HSet(ctx, key, map[string]interface{}{
				"status":       "offline",
				"last_seen_at": now.UTC().Format(time.RFC3339),
			})

			s.db.Create(&models.DeliveryPresenceLog{
				DeliveryUserID: userID,
				Status:         models.DriverOffline,
				Note:           "auto-offline (stale heartbeat)",
			})

			s.wsHub.BroadcastToRole("admin", &websocket.WSMessage{
				Type: websocket.MsgDriverOffline,
				Payload: map[string]interface{}{
					"user_id": userID.String(),
					"status":  "offline",
					"reason":  "stale_heartbeat",
				},
			})
		}
	}
}
