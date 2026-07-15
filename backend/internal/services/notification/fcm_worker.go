package notification

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"firebase.google.com/go/v4/messaging"
	"github.com/barbar-app/backend/internal/firebase"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"gorm.io/gorm"
)

// DispatchPushNotification sends push notifications using Firebase Admin SDK
// and records the attempts in NotificationLog
func DispatchPushNotification(db *gorm.DB, tokens []models.DeviceToken, notification models.Notification) {
	if len(tokens) == 0 {
		return
	}

	if firebase.MessagingClient == nil {
		log.Println("Skipping FCM dispatch: Firebase SDK not initialized")
		return
	}

	// Group tokens by platform if needed, but here we can just use MulticastMessage
	var registrationTokens []string
	tokenMap := make(map[string]models.DeviceToken)
	for _, t := range tokens {
		registrationTokens = append(registrationTokens, t.Token)
		tokenMap[t.Token] = t
	}

	utils.DefaultPool.SubmitNamed("fcm_dispatch_"+notification.ID.String(), func(p interface{}) error {
		ctx := context.Background()

		dataPayload := make(map[string]string)
		dataPayload["type"] = string(notification.Type)
		
		var dataMap map[string]interface{}
		if notification.Data != nil {
			json.Unmarshal(notification.Data, &dataMap)
			for k, v := range dataMap {
				dataPayload[k] = fmt.Sprintf("%v", v)
			}
		}

		// We now rely on notification.Action set by the Dispatcher, no string parsing here
		if notification.Action != "" {
			dataPayload["action"] = notification.Action
		}
		if notification.Link != "" {
			dataPayload["deep_link"] = notification.Link
		}

		fcmPriority := "normal"
		if notification.Priority == models.PriorityHigh {
			fcmPriority = "high"
		}

		message := &messaging.MulticastMessage{
			Tokens: registrationTokens,
			Notification: &messaging.Notification{
				Title:    notification.Title,
				Body:     notification.Body,
				ImageURL: notification.Image,
			},
			Data: dataPayload,
			Android: &messaging.AndroidConfig{
				Priority: fcmPriority,
				Notification: &messaging.AndroidNotification{
					ChannelID: "high_importance_channel",
				},
			},
			APNS: &messaging.APNSConfig{
				Payload: &messaging.APNSPayload{
					Aps: &messaging.Aps{
						Sound:            "default",
						ContentAvailable: true,
					},
				},
			},
		}

		response, err := firebase.MessagingClient.SendMulticast(ctx, message)
		if err != nil {
			// Record complete failure
			log.Printf("FCM Multicast error: %v", err)
			return err
		}

		if response.FailureCount > 0 {
			var failedTokens []string
			for idx, resp := range response.Responses {
				if !resp.Success {
					failedTokens = append(failedTokens, registrationTokens[idx])
					// If token is unregistered, remove it from DB
					if resp.Error != nil && messaging.IsUnregistered(resp.Error) {
						db.Model(&models.DeviceToken{}).Where("token = ?", registrationTokens[idx]).Update("is_active", false)
					}
				}
			}
			log.Printf("FCM partial failure for %d tokens: %v", response.FailureCount, failedTokens)
		}

		// Save log
		status := "Delivered"
		if response.FailureCount == len(registrationTokens) {
			status = "Failed"
		} else if response.FailureCount > 0 {
			status = "Partial Delivery"
		}

		logEntry := models.NotificationLog{
			NotificationID: notification.ID,
			Status:         status,
			Error:          fmt.Sprintf("Success: %d, Failed: %d", response.SuccessCount, response.FailureCount),
		}
		db.Create(&logEntry)

		return nil
	}, nil)
}
