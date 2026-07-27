package main

import (
	"log"

	"github.com/barbar-app/backend/internal/models"
	"gorm.io/gorm"
)

func seedNotificationTemplates(db *gorm.DB) {
	templates := []models.NotificationTemplate{
		{
			Name:     "booking_confirmed_en",
			Language: "en",
			Title:    "Booking Confirmed",
			Body:     "Hello {{.customer_name}}, your booking has been accepted!",
			Type:     models.NotifBookingConfirmed,
			IsActive: true,
		},
		{
			Name:     "booking_confirmed_hi",
			Language: "hi",
			Title:    "बुकिंग कन्फर्म हो गई",
			Body:     "नमस्ते {{.customer_name}}, आपकी बुकिंग स्वीकार कर ली गई है!",
			Type:     models.NotifBookingConfirmed,
			IsActive: true,
		},
		{
			Name:     "order_placed_en",
			Language: "en",
			Title:    "New Order Received",
			Body:     "You have received a new order from {{.customer_name}}.",
			Type:     models.NotifOrderPlaced,
			IsActive: true,
		},
		{
			Name:     "order_placed_hi",
			Language: "hi",
			Title:    "नया आर्डर मिला",
			Body:     "आपको {{.customer_name}} से एक नया आर्डर मिला है।",
			Type:     models.NotifOrderPlaced,
			IsActive: true,
		},
	}

	for _, t := range templates {
		var existing int64
		db.Model(&models.NotificationTemplate{}).Where("name = ? AND language = ?", t.Name, t.Language).Count(&existing)
		if existing == 0 {
			db.Create(&t)
			log.Printf("  Created template: %s (%s)", t.Name, t.Language)
		}
	}
}
