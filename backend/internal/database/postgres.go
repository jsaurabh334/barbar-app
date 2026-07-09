package database

import (
	"fmt"
	"log"
	"os"

	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func InitPostgres(cfg *config.DatabaseConfig) *gorm.DB {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s TimeZone=Asia/Kolkata search_path=public",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.Name, cfg.SSLMode,
	)

	prepareStmt := true
	disableFK := false
	if os.Getenv("BARBAR_ENV") == "test" {
		prepareStmt = false
		disableFK = true
	}
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
		PrepareStmt: prepareStmt,
		DisableForeignKeyConstraintWhenMigrating: disableFK,
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying DB: %v", err)
	}

	sqlDB.SetMaxOpenConns(cfg.MaxOpenConns)
	sqlDB.SetMaxIdleConns(cfg.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	DB = db
	return db
}

func RunMigrations(db *gorm.DB) {
	if os.Getenv("BARBAR_ENV") == "test" {
		db.Exec("SET session_replication_role = 'replica'")
	}

	// Ensure the UUID generation extension is available
	if err := db.Exec(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`).Error; err != nil {
		log.Fatalf("Failed to create uuid-ossp extension: %v", err)
	}

	err := db.AutoMigrate(
		// Foundation — no FK dependencies
		&models.User{},
		&models.Category{},
		&models.PlatformSetting{},
		&models.TaxSetting{},
		&models.NotificationTemplate{},

		// User-level — FK → User
		&models.UserSession{},
		&models.Address{},
		&models.KYCDocument{},
		&models.DeviceToken{},
		&models.AuditLog{},
		&models.DeliveryPartner{},

		// Shop-level — FK → User, Category
		&models.Barber{},
		&models.BarberAvailability{},
		&models.BarberHoliday{},
		&models.BarberDocument{},
		&models.Vendor{},
		&models.VendorDocument{},
		&models.VendorBankAccount{},

		// Service/Product-level — FK → Barber, Category, Vendor
		&models.BarberService{},
		&models.Product{},
		&models.ProductVariant{},
		&models.ProductImage{},
		&models.SubCategory{},

		// Transaction-level — FK → User, Barber, Vendor, Product, Category
		&models.Booking{},
		&models.BookingService{},
		&models.BookingStatusLog{},
		&models.CartItem{},
		&models.WishlistItem{},
		&models.Coupon{},
		&models.CouponUsage{},
		&models.ProductReview{},
		&models.FeaturedListing{},

		// Order-level — FK → User, Vendor, Product, Address
		&models.Order{},
		&models.OrderItem{},
		&models.OrderStatusLog{},
		&models.ShippingAddress{},
		&models.Payment{},
		&models.PaymentGatewayLog{},
		&models.Invoice{},
		&models.CommissionTransaction{},
		&models.RefundRequest{},
		&models.WithdrawalRequest{},

		// Wallet — FK → User, Vendor
		&models.Wallet{},
		&models.WalletTransaction{},
		&models.VendorPayout{},

		// Review-level — FK → Booking, User, Barber, Review
		&models.Review{},
		&models.ReviewImage{},
		&models.ReviewReply{},
		&models.ReviewReport{},

		// Notifications — FK → User
		&models.Notification{},

		// Dispute — FK → User, Order, Booking
		&models.Dispute{},
		&models.DisputeMessage{},

		// Webhook — FK → Vendor, Barber
		&models.WebhookEndpoint{},
		&models.WebhookEvent{},
	)
	if err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}
	log.Println("Database migrations completed successfully")

	if os.Getenv("BARBAR_ENV") == "test" {
		db.Exec("SET session_replication_role = 'origin'")
	}
}

func SeedData(db *gorm.DB, cfg *config.AppConfig) {
	var count int64
	db.Model(&models.PlatformSetting{}).Count(&count)
	if count > 0 {
		return
	}

	settings := []models.PlatformSetting{
		{Key: "platform_name", Value: cfg.Name},
		{Key: "platform_currency", Value: cfg.Currency},
		{Key: "commission_rate", Value: fmt.Sprintf("%.2f", cfg.CommissionRate)},
		{Key: "platform_fee", Value: fmt.Sprintf("%.2f", cfg.PlatformFee)},
		{Key: "tax_rate", Value: fmt.Sprintf("%.2f", cfg.TaxRate)},
		{Key: "support_email", Value: cfg.SupportEmail},
		{Key: "support_phone", Value: cfg.SupportPhone},
		{Key: "max_booking_days_in_advance", Value: "30"},
		{Key: "booking_cancellation_minutes", Value: "60"},
		{Key: "auto_cancel_no_show_minutes", Value: "15"},
		{Key: "max_queue_size_per_barber", Value: "50"},
		{Key: "refund_period_days", Value: "7"},
		{Key: "return_period_days", Value: "10"},
		{Key: "minimum_withdrawal_amount", Value: "500"},
		{Key: "max_withdrawal_per_month", Value: "5"},
		{Key: "otp_expiry_seconds", Value: "300"},
		{Key: "jwt_access_ttl_minutes", Value: "15"},
		{Key: "jwt_refresh_ttl_days", Value: "7"},
		{Key: "free_delivery_min_amount", Value: "499"},
		{Key: "delivery_charge", Value: "49"},
	}
	for _, s := range settings {
		db.Create(&s)
	}
	log.Println("Seed data inserted successfully")
}
