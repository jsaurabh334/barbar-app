package main

import (
	"fmt"
	"log"

	"gorm.io/gorm"
)

func resetDemoData(db *gorm.DB) {
	tables := []string{
		"wallet_transactions", "wallets",
		"product_reviews", "product_images", "product_variants", "products",
		"barber_services", "barber_documents", "barber_availability", "barber_holidays",
		"bookings", "booking_services", "booking_status_logs",
		"barbers", "vendors", "addresses",
		"barbers", "vendors", "addresses",
		"categories", "platform_settings", "notification_templates",
	}
	for _, t := range tables {
		db.Exec(fmt.Sprintf("DELETE FROM %s", t))
	}
	db.Exec("DELETE FROM users WHERE role != 'admin'")
	log.Println("Existing demo data cleared.")
}
