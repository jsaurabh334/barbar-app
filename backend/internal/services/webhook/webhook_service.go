package webhook

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WebhookService struct {
	db      *gorm.DB
	client  *http.Client
}

func NewWebhookService(db *gorm.DB) *WebhookService {
	return &WebhookService{
		db: db,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (s *WebhookService) Dispatch(event string, payload interface{}) {
	var endpoints []models.WebhookEndpoint
	s.db.Where("status = ?", models.WebhookActive).Find(&endpoints)

	for _, ep := range endpoints {
		var subscribedEvents []string
		json.Unmarshal(ep.Events, &subscribedEvents)

		if !contains(subscribedEvents, event) && !contains(subscribedEvents, "*") {
			continue
		}

		s.sendWebhook(ep, event, payload)
	}
}

func (s *WebhookService) sendWebhook(ep models.WebhookEndpoint, event string, payload interface{}) {
	body := map[string]interface{}{
		"event":     event,
		"timestamp": time.Now().Unix(),
		"data":      payload,
	}

	bodyBytes, _ := json.Marshal(body)

	logEntry := models.WebhookEvent{
		EndpointID: ep.ID,
		Event:      event,
		Payload:    models.JSONB(bodyBytes),
		Status:     models.WebhookEventPending,
		MaxRetries: ep.RetryCount,
	}

	s.db.Create(&logEntry)

	utils.DefaultPool.SubmitNamed("webhook:"+event, func(data interface{}) error {
		return s.executeWebhook(ep, logEntry.ID, event, bodyBytes)
	}, nil)
}

func (s *WebhookService) executeWebhook(ep models.WebhookEndpoint, eventID uuid.UUID, event string, body []byte) error {
	req, err := http.NewRequest("POST", ep.URL, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Webhook-Event", event)
	req.Header.Set("User-Agent", "Barbar-App-Webhook/1.0")

	if ep.Secret != "" {
		mac := hmac.New(sha256.New, []byte(ep.Secret))
		mac.Write(body)
		signature := hex.EncodeToString(mac.Sum(nil))
		req.Header.Set("X-Webhook-Signature", signature)
	}

	resp, err := s.client.Do(req)
	if err != nil {
		s.updateEventStatus(eventID, models.WebhookEventFailed, err.Error(), 0)
		return fmt.Errorf("webhook request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		s.updateEventStatus(eventID, models.WebhookEventSent, "delivered", resp.StatusCode)
		return nil
	}

	errMsg := fmt.Sprintf("received status %d", resp.StatusCode)
	s.updateEventStatus(eventID, models.WebhookEventFailed, errMsg, resp.StatusCode)
	return fmt.Errorf("%s", errMsg)
}

func (s *WebhookService) updateEventStatus(eventID uuid.UUID, status models.WebhookEventStatus, response string, statusCode int) {
	updates := map[string]interface{}{
		"status":      status,
		"response":    response,
		"status_code": statusCode,
		"attempts":    gorm.Expr("attempts + 1"),
	}
	if status == models.WebhookEventFailed {
		nextRetry := time.Now().Add(5 * time.Minute)
		updates["next_retry"] = &nextRetry
	}
	s.db.Model(&models.WebhookEvent{}).Where("id = ?", eventID).Updates(updates)
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// RetryFailedEvents retries all events that are in failed status and due for retry
func (s *WebhookService) RetryFailedEvents() {
	var events []models.WebhookEvent
	now := time.Now()
	s.db.Where("status IN ? AND (next_retry IS NULL OR next_retry <= ?)",
		[]models.WebhookEventStatus{models.WebhookEventFailed, models.WebhookEventPending}, now).
		Find(&events)

	for _, event := range events {
		var ep models.WebhookEndpoint
		if err := s.db.First(&ep, event.EndpointID).Error; err != nil {
			continue
		}
		if ep.Status != models.WebhookActive {
			continue
		}

		utils.DefaultPool.SubmitNamed("webhook-retry:"+event.Event, func(data interface{}) error {
			return s.executeWebhook(ep, event.ID, event.Event, []byte(event.Payload))
		}, nil)
	}
}

// StartRetryScheduler runs retry logic periodically
func (s *WebhookService) StartRetryScheduler(interval time.Duration) {
	go func() {
		ticker := time.NewTicker(interval)
		for range ticker.C {
			s.RetryFailedEvents()
		}
	}()
	log.Printf("Webhook retry scheduler started with interval %v", interval)
}

// GetDeliveryLogs returns webhook event logs for an endpoint
func (s *WebhookService) GetDeliveryLogs(endpointID string) []models.WebhookEvent {
	var events []models.WebhookEvent
	s.db.Where("endpoint_id = ?", endpointID).Order("created_at DESC").Limit(50).Find(&events)
	return events
}
