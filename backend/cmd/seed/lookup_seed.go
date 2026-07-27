package main

import (
	"log"

	"github.com/barbar-app/backend/internal/models"
	"gorm.io/gorm"
)

func seedPlatformSettings(db *gorm.DB) {
	settings := []models.PlatformSetting{
		{Key: "platform_name", Value: "Barbar App"},
		{Key: "platform_currency", Value: "INR"},
		{Key: "commission_rate", Value: "10.00"},
		{Key: "platform_fee", Value: "5.00"},
		{Key: "tax_rate", Value: "18.00"},
		{Key: "support_email", Value: "support@barbar.app"},
		{Key: "support_phone", Value: "+91-1800-123-4567"},
		{Key: "free_delivery_min_amount", Value: "499"},
		{Key: "delivery_charge", Value: "49"},
		{Key: "max_booking_days_in_advance", Value: "30"},
		{Key: "booking_cancellation_minutes", Value: "60"},
		{Key: "auto_cancel_no_show_minutes", Value: "15"},
		{Key: "refund_period_days", Value: "7"},
		{Key: "return_period_days", Value: "10"},
		{Key: "minimum_withdrawal_amount", Value: "500"},
		{Key: "max_withdrawal_per_month", Value: "5"},
	}
	for _, s := range settings {
		var existing int64
		db.Model(&models.PlatformSetting{}).Where("key = ?", s.Key).Count(&existing)
		if existing == 0 {
			db.Create(&s)
		}
	}
	log.Println("Platform settings seeded")
}
