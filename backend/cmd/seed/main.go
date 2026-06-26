package main

import (
	"log"

	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func main() {
	log.Println("Barbar App - Data Seeder")
	log.Println("=========================")

	cfg := config.Load()
	db := database.InitPostgres(&cfg.Database)
	database.RunMigrations(db)

	seedAdmin(db)
	seedCategories(db)
	seedSampleUsers(db)
	seedPlatformSettings(db)

	log.Println("Seeding complete!")
}

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

func seedCategories(db *gorm.DB) {
	categories := []models.Category{
		{Name: "Hair Care", Slug: "hair-care", Description: "Shampoos, conditioners, oils & styling products", IsActive: true, SortOrder: 1, CategoryType: "product"},
		{Name: "Beard Care", Slug: "beard-care", Description: "Beard oils, balms, shampoos & brushes", IsActive: true, SortOrder: 2, CategoryType: "product"},
		{Name: "Skin Care", Slug: "skin-care", Description: "Face washes, moisturizers & lotions", IsActive: true, SortOrder: 3, CategoryType: "product"},
		{Name: "Shaving", Slug: "shaving", Description: "Razors, creams, aftershaves & brushes", IsActive: true, SortOrder: 4, CategoryType: "product"},
		{Name: "Grooming Kits", Slug: "grooming-kits", Description: "Complete grooming kits & sets", IsActive: true, SortOrder: 5, CategoryType: "product"},
		{Name: "Accessories", Slug: "accessories", Description: "Combs, brushes, clippers & trimmers", IsActive: true, SortOrder: 6, CategoryType: "product"},
	}

	for _, cat := range categories {
		var existing int64
		db.Model(&models.Category{}).Where("slug = ?", cat.Slug).Count(&existing)
		if existing == 0 {
			db.Create(&cat)
			log.Printf("  Created category: %s", cat.Name)
		}
	}
}

func seedSampleUsers(db *gorm.DB) {
	if count := db.Where("email = ?", "customer@demo.com").Find(&models.User{}).RowsAffected; count > 0 {
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte("Demo@123"), bcrypt.DefaultCost)

	customer := models.User{
		FullName:     "Demo Customer",
		Email:        "customer@demo.com",
		Phone:        "+919876543210",
		PasswordHash: string(hash),
		Role:         models.RoleCustomer,
		Status:       models.UserStatusActive,
	}
	db.Create(&customer)
	db.Create(&models.Wallet{UserID: &customer.ID, Balance: 1000})
	log.Println("  Created demo customer: customer@demo.com / Demo@123")

	barberUser := models.User{
		FullName:     "Demo Barber",
		Email:        "barber@demo.com",
		Phone:        "+919876543211",
		PasswordHash: string(hash),
		Role:         models.RoleBarber,
		Status:       models.UserStatusActive,
	}
	db.Create(&barberUser)
	db.Create(&models.Wallet{UserID: &barberUser.ID, Balance: 0})

	barber := models.Barber{
		UserID:             barberUser.ID,
		ShopName:           "Classic Cuts Studio",
		ShopDescription:    "Premium barber shop with 10+ years of experience. Specializing in modern and classic haircuts, beard styling, and grooming services.",
		Address:            "101, MG Road, Indiranagar",
		City:               "Bangalore",
		State:              "Karnataka",
		Pincode:            "560038",
		Latitude:           12.9716,
		Longitude:          77.5946,
		StartTime:          "09:00",
		EndTime:            "21:00",
		SlotDuration:       30,
		BufferBetweenSlots: 5,
		Status:             models.BarberStatusActive,
		VerificationStatus: models.BarberVerifApproved,
		IsVerified:         true,
		IsAvailable:        true,
		Rating:             4.5,
		ReviewCount:        128,
		ExperienceYears:    8,
		BusinessDays:       []byte(`["monday","tuesday","wednesday","thursday","friday","saturday"]`),
	}
	db.Create(&barber)

	services := []models.BarberService{
		{BarberID: barber.ID, Name: "Classic Haircut", Description: "Professional haircut with scissors and clippers", Category: "hair", Price: 399, DurationMin: 30, IsActive: true, SortOrder: 1},
		{BarberID: barber.ID, Name: "Beard Trim & Shape", Description: "Precision beard trimming and shaping", Category: "grooming", Price: 199, DurationMin: 15, IsActive: true, SortOrder: 2},
		{BarberID: barber.ID, Name: "Hair Wash", Description: "Shampoo + conditioner wash", Category: "hair", Price: 99, DurationMin: 10, IsActive: true, SortOrder: 3, IsAddon: true},
		{BarberID: barber.ID, Name: "Head Massage", Description: "Relaxing head massage (15 min)", Category: "grooming", Price: 149, DurationMin: 15, IsActive: true, SortOrder: 4, IsAddon: true},
		{BarberID: barber.ID, Name: "Hair Color", Description: "Professional hair coloring", Category: "hair", Price: 999, DurationMin: 60, IsActive: true, SortOrder: 5},
		{BarberID: barber.ID, Name: "Facial", Description: "Deep cleansing facial", Category: "skin", Price: 299, DurationMin: 20, IsActive: true, SortOrder: 6, IsAddon: true},
	}
	for _, svc := range services {
		db.Create(&svc)
	}
	log.Printf("  Created demo barber: barber@demo.com / Demo@123 (%s)", barber.ShopName)

	vendorUser := models.User{
		FullName:     "Demo Vendor",
		Email:        "vendor@demo.com",
		Phone:        "+919876543212",
		PasswordHash: string(hash),
		Role:         models.RoleVendor,
		Status:       models.UserStatusActive,
	}
	db.Create(&vendorUser)

	vendor := models.Vendor{
		UserID:   vendorUser.ID,
		StoreName: "Style Products Hub",
		StoreSlug: "style-products-hub",
		StoreDescription: "Premium barber and grooming products. Authentic brands, best prices.",
		Address:  "202, Brigade Road, MG Road",
		City:     "Bangalore",
		State:    "Karnataka",
		Pincode:  "560001",
		Status:   models.VendorStatusApproved,
		IsVerified: true,
		IsActive: true,
		Rating:   4.2,
	}
	db.Create(&vendor)
	db.Create(&models.Wallet{VendorID: &vendor.ID, Balance: 0})

	log.Printf("  Created demo vendor: vendor@demo.com / Demo@123 (%s)", vendor.StoreName)
}

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
