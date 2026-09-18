package main

import (
	"log"

	"github.com/barbar-app/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func seedAdmin(db *gorm.DB) {
	var user models.User
	err := db.Where("email = ? OR phone = ?", "admin@barbar.app", "+919999999999").First(&user).Error

	hash, _ := bcrypt.GenerateFromPassword([]byte("Admin@123"), bcrypt.DefaultCost)
	if err == nil {
		db.Model(&user).Updates(map[string]interface{}{
			"email":         "admin@barbar.app",
			"phone":         "+919999999999",
			"full_name":     "Super Admin",
			"password_hash": string(hash),
			"role":          models.RoleAdmin,
			"status":        models.UserStatusActive,
		})
		log.Printf("Admin user updated: admin@barbar.app / Admin@123")
		return
	}

	admin := models.User{
		FullName:     "Super Admin",
		Email:        "admin@barbar.app",
		Phone:        "+919999999999",
		PasswordHash: string(hash),
		Role:         models.RoleAdmin,
		Status:       models.UserStatusActive,
	}
	if err := db.Create(&admin).Error; err != nil {
		log.Fatalf("Failed to create admin: %v", err)
	}
	wallet := models.Wallet{UserID: &admin.ID, Balance: 0}
	db.Create(&wallet)
	log.Printf("Admin user created: admin@barbar.app / Admin@123")
}
