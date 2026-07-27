package main

import (
	"log"

	"github.com/barbar-app/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func seedAdmin(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Where("email = ?", "admin@barbar.app").Count(&count)
	if count > 0 {
		log.Println("Admin user already exists, skipping...")
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte("Admin@123"), bcrypt.DefaultCost)
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
