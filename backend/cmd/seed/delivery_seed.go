package main

import (
	"log"

	"github.com/barbar-app/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func seedDemoDelivery(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Where("phone = ?", "+916666666666").Count(&count)

	hash, _ := bcrypt.GenerateFromPassword([]byte("Demo@123"), bcrypt.DefaultCost)

	if count == 0 {
		deliveryUser := models.User{
			FullName:     "Demo Delivery",
			Email:        "delivery@demo.com",
			Phone:        "+916666666666",
			PasswordHash: string(hash),
			Role:         models.RoleDelivery,
			Status:       models.UserStatusActive,
		}
		db.Create(&deliveryUser)
		db.Create(&models.Wallet{UserID: &deliveryUser.ID, Balance: 0})
	} else {
		var deliveryUser models.User
		db.Where("phone = ?", "+916666666666").First(&deliveryUser)
		db.Model(&deliveryUser).Updates(map[string]interface{}{
			"full_name":     "Demo Delivery",
			"role":          models.RoleDelivery,
			"password_hash": string(hash),
		})
	}
	log.Println("  Created delivery: delivery@demo.com / Demo@123")
}
