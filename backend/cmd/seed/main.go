package main

import (
	"flag"
	"fmt"
	"log"
	"strings"

	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func main() {
	reset := flag.Bool("reset", false, "Delete existing demo data and re-seed")
	flag.Parse()

	log.Println("Barbar App - Data Seeder")
	log.Println("=========================")

	cfg := config.Load()
	db := database.InitPostgres(&cfg.Database)
	database.RunMigrations(db)

	if *reset {
		log.Println("--reset flag detected, clearing existing demo data...")
		resetDemoData(db)
		log.Println("Existing demo data cleared.")
	}

	seedAdmin(db)
	seedCategories(db)
	seedPlatformSettings(db)
	seedAllData(db)

	// Generate demo images (always, idempotent)
	log.Println("Generating demo placeholder images...")
	shopNames := getShopNames()
	generateDemoImages("static/demo", shopNames)

	log.Println("=========================")
	log.Println("Seeding complete!")
	log.Printf("  Vendors:   5")
	log.Printf("  Shops:     15")
	log.Printf("  Services:  90")
	log.Printf("  Products:  30")
	log.Printf("  Categories: 6")
	log.Printf("  Demo images: ~75")
}

func resetDemoData(db *gorm.DB) {
	tables := []string{
		"wallet_transactions", "wallets",
		"product_reviews", "product_images", "product_variants", "products",
		"barber_services", "barber_documents", "barber_availability", "barber_holidays",
		"bookings", "booking_services", "booking_status_logs",
		"barbers", "vendors", "addresses",
		"categories", "platform_settings",
	}
	for _, t := range tables {
		db.Exec(fmt.Sprintf("DELETE FROM %s", t))
	}
	db.Exec("DELETE FROM users WHERE role != 'admin'")
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

// ──────────────────────────────────────────────
// DATA DEFINITIONS
// ──────────────────────────────────────────────

type seedService struct {
	Name        string
	Description string
	Category    string
	Price       float64
	DurationMin int
	IsAddon     bool
}

type seedShop struct {
	ID              int
	ShopName        string
	Description     string
	Address         string
	City            string
	State           string
	Pincode         string
	Lat             float64
	Lng             float64
	Rating          float64
	ReviewCount     int
	QueueLength     int
	AvgWaitTime     float64
	ExperienceYears int
	StartTime       string
	EndTime         string
	ClosedDays      string
	HomeService     bool
	Services        []seedService
	VendorIdx       int
}

func getShopNames() []string {
	shops := getShopData()
	names := make([]string, len(shops))
	for i, s := range shops {
		names[i] = s.ShopName
	}
	return names
}

func getShopData() []seedShop {
	return []seedShop{
		// ─── BANGALORE (5) ───
		{ID: 1, ShopName: "Classic Cuts Studio", VendorIdx: 0,
			Description: "Premium barber shop with 10+ years of experience. Specializing in modern and classic haircuts, beard styling, and grooming services.",
			Address: "101, MG Road, Indiranagar", City: "Bangalore", State: "Karnataka", Pincode: "560038",
			Lat: 12.9716, Lng: 77.5946, Rating: 4.5, ReviewCount: 340, QueueLength: 4, AvgWaitTime: 15, ExperienceYears: 8,
			StartTime: "09:00", EndTime: "21:00", ClosedDays: "", HomeService: true,
			Services: []seedService{
				{"Classic Haircut", "Professional haircut with scissors and clippers", "Haircut", 399, 30, false},
				{"Beard Trim & Shape", "Precision beard trimming and shaping", "Beard", 199, 15, false},
				{"Hair Wash", "Shampoo + conditioner wash with scalp massage", "Haircut", 99, 10, true},
				{"Head Massage", "Relaxing head massage (15 min)", "Spa", 149, 15, true},
				{"Hair Color", "Professional hair coloring with premium products", "Hair Color", 999, 60, false},
				{"Facial", "Deep cleansing facial for glowing skin", "Facial", 299, 20, true},
			}},
		{ID: 2, ShopName: "Raj Hair Studio", VendorIdx: 0,
			Description: "Affordable and quality grooming since 2015. Known for precision cuts and friendly service.",
			Address: "45, 12th Main, Koramangala", City: "Bangalore", State: "Karnataka", Pincode: "560034",
			Lat: 12.9352, Lng: 77.6245, Rating: 4.2, ReviewCount: 215, QueueLength: 6, AvgWaitTime: 22, ExperienceYears: 6,
			StartTime: "09:30", EndTime: "20:30", ClosedDays: "", HomeService: false,
			Services: []seedService{
				{"Haircut", "Regular haircut - comb & scissors", "Haircut", 249, 25, false},
				{"Beard Trim", "Quick beard shaping and trim", "Beard", 149, 15, false},
				{"Royal Shave", "Traditional hot towel shave experience", "Beard", 199, 25, false},
				{"Facial Cleanup", "Basic face cleansing and massage", "Facial", 249, 20, false},
				{"Hair Wash", "Shampoo and towel dry", "Haircut", 79, 10, true},
				{"Sideburns Trim", "Precision sideburns styling", "Beard", 99, 5, true},
			}},
		{ID: 3, ShopName: "Urban Fade Studio", VendorIdx: 0,
			Description: "Trend-setting fade specialists. The go-to place for modern hairstyles and premium grooming.",
			Address: "88, Church Street, MG Road", City: "Bangalore", State: "Karnataka", Pincode: "560001",
			Lat: 12.9733, Lng: 77.6099, Rating: 4.8, ReviewCount: 550, QueueLength: 8, AvgWaitTime: 25, ExperienceYears: 5,
			StartTime: "10:00", EndTime: "21:00", ClosedDays: "", HomeService: false,
			Services: []seedService{
				{"Premium Fade Haircut", "Expert fade haircut - skin, mid or high fade", "Haircut", 599, 35, false},
				{"Designer Beard", "Detailed beard design and sculpting", "Beard", 349, 20, false},
				{"Hair Spa", "Nourishing hair spa treatment", "Spa", 799, 45, false},
				{"Hair Color & Style", "Full color + styling", "Hair Color", 1499, 75, false},
				{"Keratin Treatment", "Smoothing keratin treatment", "Premium Grooming", 2499, 90, false},
				{"Scalp Treatment", "Deep scalp cleansing and massage", "Spa", 499, 30, false},
			}},
		{ID: 4, ShopName: "The Grooming Lounge", VendorIdx: 1,
			Description: "A relaxing lounge-style salon. Perfect for a complete grooming session with friends.",
			Address: "201, Brigade Road, MG Road", City: "Bangalore", State: "Karnataka", Pincode: "560001",
			Lat: 12.9708, Lng: 77.6078, Rating: 3.8, ReviewCount: 102, QueueLength: 2, AvgWaitTime: 8, ExperienceYears: 4,
			StartTime: "10:00", EndTime: "22:00", ClosedDays: "[\"tuesday\"]", HomeService: true,
			Services: []seedService{
				{"Standard Haircut", "Clean haircut - any style", "Haircut", 299, 25, false},
				{"Beard Grooming", "Full beard care - wash, trim, oil", "Beard", 249, 20, false},
				{"Hair Wash & Blow Dry", "Wash + blow dry styling", "Haircut", 199, 15, true},
				{"Head Massage", "Stress relief head massage", "Spa", 199, 20, false},
				{"Mustache Trim", "Precision mustache shaping", "Beard", 99, 10, true},
				{"Hair Oil Treatment", "Hot oil treatment for dry hair", "Haircut", 299, 20, true},
			}},
		{ID: 5, ShopName: "Trim & Style Salon", VendorIdx: 1,
			Description: "Budget-friendly salon for the whole family. Kids welcome!",
			Address: "12, 80 Feet Road, HSR Layout", City: "Bangalore", State: "Karnataka", Pincode: "560102",
			Lat: 12.9116, Lng: 77.6389, Rating: 3.2, ReviewCount: 56, QueueLength: 1, AvgWaitTime: 5, ExperienceYears: 3,
			StartTime: "08:00", EndTime: "20:00", ClosedDays: "[\"monday\"]", HomeService: false,
			Services: []seedService{
				{"Basic Haircut", "Simple haircut - any style", "Haircut", 149, 20, false},
				{"Kids Haircut", "Child-friendly haircut with lollipop!", "Haircut", 199, 20, false},
				{"Beard Trim", "Basic beard trim", "Beard", 99, 10, false},
				{"Shave", "Classic straight razor shave", "Beard", 149, 15, false},
				{"Eyebrow Trim", "Eyebrow shaping", "Beard", 49, 5, true},
			}},
		// ─── HYDERABAD (3) ───
		{ID: 6, ShopName: "Elite Cuts & Spa", VendorIdx: 1,
			Description: "Hyderabad's premier grooming destination. Luxury meets tradition in every service.",
			Address: "1-98/1, Jubilee Hills Road No 36", City: "Hyderabad", State: "Telangana", Pincode: "500033",
			Lat: 17.4319, Lng: 78.4107, Rating: 4.6, ReviewCount: 420, QueueLength: 7, AvgWaitTime: 20, ExperienceYears: 10,
			StartTime: "09:00", EndTime: "21:00", ClosedDays: "", HomeService: true,
			Services: []seedService{
				{"Signature Haircut", "Premium haircut with consultation", "Haircut", 699, 35, false},
				{"Beard Sculpting", "Detailed beard sculpting and styling", "Beard", 399, 25, false},
				{"Facial", "Gold facial treatment", "Facial", 599, 30, false},
				{"Hair Spa", "Aromatherapy hair spa", "Spa", 899, 50, false},
				{"Hair Color", "Global hair color", "Hair Color", 1299, 60, false},
				{"Detan Face Pack", "Fruit detox face pack", "Facial", 349, 20, true},
			}},
		{ID: 7, ShopName: "Fresh Fade Barbers", VendorIdx: 2,
			Description: "Fade haircut specialists in the heart of Hyderabad. Walk-in friendly!",
			Address: "3-5-1109, Narayanguda", City: "Hyderabad", State: "Telangana", Pincode: "500029",
			Lat: 17.3964, Lng: 78.4919, Rating: 4.0, ReviewCount: 187, QueueLength: 5, AvgWaitTime: 18, ExperienceYears: 4,
			StartTime: "10:00", EndTime: "21:30", ClosedDays: "", HomeService: false,
			Services: []seedService{
				{"Fade Haircut", "Clean fade - any type", "Haircut", 349, 25, false},
				{"Beard & Fade Combo", "Beard trim + fade haircut combo", "Beard", 499, 35, false},
				{"Hair Wash", "Shampoo + conditioner + blow dry", "Haircut", 149, 10, true},
				{"Face Scrub", "Deep exfoliating face scrub", "Facial", 249, 15, true},
			}},
		{ID: 8, ShopName: "Nizam's Grooming Room", VendorIdx: 2,
			Description: "Traditional Hyderabadi grooming with a modern touch. Experience royal treatment.",
			Address: "16-2-752, Asmangadh, Malakpet", City: "Hyderabad", State: "Telangana", Pincode: "500036",
			Lat: 17.3714, Lng: 78.4907, Rating: 3.5, ReviewCount: 78, QueueLength: 3, AvgWaitTime: 10, ExperienceYears: 7,
			StartTime: "07:00", EndTime: "19:00", ClosedDays: "[\"wednesday\"]", HomeService: false,
			Services: []seedService{
				{"Traditional Haircut", "Classic haircut - any style", "Haircut", 199, 20, false},
				{"Royal Shave", "Traditional barber shave with hot towel", "Beard", 149, 20, false},
				{"Beard Trim", "Basic beard maintenance", "Beard", 99, 10, false},
				{"Head Massage", "Traditional head and shoulder massage", "Spa", 199, 20, false},
				{"Hair Color (Basic)", "Basic hair color application", "Hair Color", 599, 45, false},
			}},
		// ─── PUNE (3) ───
		{ID: 9, ShopName: "Pune Cuts & Curls", VendorIdx: 2,
			Description: "Unisex salon offering stylish cuts and creative coloring for everyone.",
			Address: "55, FC Road, Shivajinagar", City: "Pune", State: "Maharashtra", Pincode: "411004",
			Lat: 18.5290, Lng: 73.8468, Rating: 4.3, ReviewCount: 289, QueueLength: 6, AvgWaitTime: 18, ExperienceYears: 6,
			StartTime: "10:00", EndTime: "21:00", ClosedDays: "", HomeService: true,
			Services: []seedService{
				{"Unisex Haircut", "Suitable for all hair types", "Haircut", 449, 30, false},
				{"Beard Styling", "Complete beard styling", "Beard", 249, 20, false},
				{"Hair Color", "Professional hair color", "Hair Color", 899, 55, false},
				{"Facial", "Hydrating facial", "Facial", 399, 25, false},
				{"Spa Treatment", "Relaxing spa session", "Spa", 699, 40, false},
				{"Hair Wash & Blow Dry", "Wash + blow dry with product", "Haircut", 149, 15, true},
			}},
		{ID: 10, ShopName: "The Beard Bar", VendorIdx: 3,
			Description: "Pune's first beard-only salon. Specialist in beard grooming, shaping and care.",
			Address: "22, Lane 6, Koregaon Park", City: "Pune", State: "Maharashtra", Pincode: "411001",
			Lat: 18.5362, Lng: 73.8943, Rating: 4.7, ReviewCount: 168, QueueLength: 5, AvgWaitTime: 15, ExperienceYears: 5,
			StartTime: "10:00", EndTime: "22:00", ClosedDays: "", HomeService: false,
			Services: []seedService{
				{"Beard Trim & Shape", "Expert beard trimming and shaping", "Beard", 349, 25, false},
				{"Full Beard Grooming", "Complete beard wash, condition, trim, style", "Beard", 549, 35, false},
				{"Mustache Care", "Mustache trim, wax and style", "Beard", 199, 15, false},
				{"Hot Towel Beard Softening", "Luxurious hot towel treatment", "Beard", 299, 20, true},
				{"Beard Color", "Natural beard coloring", "Beard", 499, 30, false},
				{"Haircut", "Regular haircut", "Haircut", 399, 25, false},
			}},
		{ID: 11, ShopName: "Swag Salon & Spa", VendorIdx: 3,
			Description: "Budget unisex salon. Great for students and young professionals.",
			Address: "7, Market Yard Road, Bibwewadi", City: "Pune", State: "Maharashtra", Pincode: "411037",
			Lat: 18.4729, Lng: 73.8791, Rating: 3.0, ReviewCount: 34, QueueLength: 0, AvgWaitTime: 2, ExperienceYears: 2,
			StartTime: "09:00", EndTime: "20:00", ClosedDays: "[\"monday\"]", HomeService: true,
			Services: []seedService{
				{"Budget Haircut", "Quick haircut - any style", "Haircut", 99, 15, false},
				{"Beard Trim", "Basic beard trim", "Beard", 79, 10, false},
				{"Shave", "Simple shave", "Beard", 99, 10, false},
				{"Hair Wash", "Basic wash", "Haircut", 59, 5, true},
			}},
		// ─── DELHI (4) ───
		{ID: 12, ShopName: "Delhi Kings Barbers", VendorIdx: 3,
			Description: "Premium grooming for the modern Delhi gent. International standards, local warmth.",
			Address: "A-17, Connaught Place, Outer Circle", City: "Delhi", State: "Delhi", Pincode: "110001",
			Lat: 28.6304, Lng: 77.2177, Rating: 4.4, ReviewCount: 376, QueueLength: 9, AvgWaitTime: 28, ExperienceYears: 7,
			StartTime: "09:00", EndTime: "21:00", ClosedDays: "", HomeService: false,
			Services: []seedService{
				{"Executive Haircut", "Premium haircut with styling", "Haircut", 599, 30, false},
				{"Beard Sculpt", "Detailed beard sculpting", "Beard", 349, 25, false},
				{"Hair Color", "Premium color + styling", "Hair Color", 1299, 60, false},
				{"Facial", "Charcoal facial for deep cleanse", "Facial", 499, 25, false},
				{"Hair Spa", "Coconut hair spa treatment", "Spa", 749, 40, false},
				{"Head & Shoulder Massage", "Complete stress relief session", "Spa", 399, 25, true},
			}},
		{ID: 13, ShopName: "Metro Grooming Hub", VendorIdx: 4,
			Description: "Conveniently located near metro stations. Quick grooming for busy professionals.",
			Address: "F-32, Sector 18, Rohini", City: "Delhi", State: "Delhi", Pincode: "110085",
			Lat: 28.7320, Lng: 77.1008, Rating: 3.9, ReviewCount: 145, QueueLength: 4, AvgWaitTime: 12, ExperienceYears: 4,
			StartTime: "08:00", EndTime: "22:00", ClosedDays: "", HomeService: true,
			Services: []seedService{
				{"Express Haircut", "Quick 15-min haircut", "Haircut", 199, 15, false},
				{"Beard Trim", "Quick beard tidy up", "Beard", 129, 10, false},
				{"Hair Wash", "Express wash", "Haircut", 79, 5, true},
				{"Facial", "Quick glow facial", "Facial", 299, 20, false},
				{"Shave", "Straight razor shave", "Beard", 149, 15, false},
			}},
		{ID: 14, ShopName: "Royal Touch Salon", VendorIdx: 4,
			Description: "5-star grooming experience. VIP rooms, premium products, and master barbers.",
			Address: "28, Khan Market", City: "Delhi", State: "Delhi", Pincode: "110003",
			Lat: 28.6010, Lng: 77.2270, Rating: 4.9, ReviewCount: 680, QueueLength: 10, AvgWaitTime: 35, ExperienceYears: 15,
			StartTime: "10:00", EndTime: "20:00", ClosedDays: "[\"tuesday\"]", HomeService: true,
			Services: []seedService{
				{"VIP Haircut", "Master barber haircut with champagne", "Premium Grooming", 1499, 45, false},
				{"Luxury Beard Grooming", "Premium products + hot towel + oil massage", "Premium Grooming", 799, 35, false},
				{"Bridal Grooming", "Complete bridal package", "Premium Grooming", 3999, 120, false},
				{"Gold Facial", "24K gold facial treatment", "Premium Grooming", 1299, 40, false},
				{"Head Spa", "Luxury head spa with essential oils", "Premium Grooming", 999, 45, false},
				{"Hair Color Premium", "International brand hair color", "Premium Grooming", 2499, 75, false},
				{"Manicure", "Hand grooming and nail care", "Premium Grooming", 499, 25, true},
				{"Pedicure", "Foot grooming and nail care", "Premium Grooming", 599, 30, true},
			}},
		{ID: 15, ShopName: "Street Style Cuts", VendorIdx: 4,
			Description: "No-frills barbershop for quick, affordable cuts. Cash only.",
			Address: "44, Lajpat Nagar Market", City: "Delhi", State: "Delhi", Pincode: "110024",
			Lat: 28.5672, Lng: 77.2478, Rating: 2.8, ReviewCount: 23, QueueLength: 0, AvgWaitTime: 1, ExperienceYears: 1,
			StartTime: "08:00", EndTime: "19:00", ClosedDays: "", HomeService: false,
			Services: []seedService{
				{"Basic Haircut", "Simple haircut", "Haircut", 99, 15, false},
				{"Shave", "Quick shave", "Beard", 79, 10, false},
				{"Beard Trim", "Quick trim", "Beard", 59, 5, false},
			}},
	}
}

type seedProduct struct {
	Name           string
	Brand          string
	Description    string
	BasePrice      float64
	DiscountPrice  float64
	AvailableStock int64
	CategorySlug   string
	IsFeatured     bool
}

func getProductData() []seedProduct {
	return []seedProduct{
		{"Argan Oil Shampoo", "Beardo", "Sulfate-free argan oil shampoo for daily use", 349, 299, 200, "hair-care", true},
		{"Silk Conditioner", "Beardo", "Silk protein conditioner for smooth hair", 299, 249, 150, "hair-care", false},
		{"Hair Growth Serum", "Ustraa", "Clinically tested hair growth serum", 499, 449, 100, "hair-care", true},
		{"Hair Spray (Strong Hold)", "The Man Company", "Long-lasting strong hold hair spray", 399, 349, 120, "hair-care", false},
		{"Hair Wax (Matte)", "Ustraa", "Matte finish hair wax for men", 249, 199, 180, "hair-care", false},
		{"Beard Oil (Woody)", "Beardo", "Beard oil with sandalwood and cedar", 399, 349, 200, "beard-care", true},
		{"Beard Balm", "Ustraa", "Beard balm for styling and conditioning", 349, 299, 150, "beard-care", false},
		{"Beard Wash", "Mamaearth", "Natural beard cleanser with aloe vera", 299, 249, 120, "beard-care", false},
		{"Beard Brush (Boar)", "The Man Company", "Premium boar bristle beard brush", 449, 399, 80, "beard-care", true},
		{"Beard Growth Oil", "Beardo", "Essential oil blend for beard growth", 549, 499, 100, "beard-care", false},
		{"Face Wash (Charcoal)", "Mamaearth", "Charcoal-based deep cleansing face wash", 249, 199, 250, "skin-care", true},
		{"Moisturizer (Day)", "The Man Company", "Lightweight day moisturizer with SPF 20", 399, 349, 150, "skin-care", false},
		{"Under Eye Cream", "Mamaearth", "Vitamin C under eye cream", 299, 249, 100, "skin-care", false},
		{"Lip Balm (Men)", "Ustraa", "Moisturizing lip balm for men", 149, 99, 300, "skin-care", false},
		{"Razor Kit (5-Blade)", "L'Oréal", "Premium 5-blade razor with aloe strip", 599, 499, 100, "shaving", true},
		{"Shaving Cream", "Beardo", "Rich shaving cream with sandalwood", 199, 149, 200, "shaving", false},
		{"Aftershave Balm", "Ustraa", "Soothing aftershave balm with aloe", 249, 199, 150, "shaving", false},
		{"Shaving Brush", "The Man Company", "Badger hair shaving brush", 399, 349, 80, "shaving", true},
		{"Complete Grooming Kit", "Beardo", "Full kit - shampoo, beard oil, face wash, comb", 1499, 1299, 50, "grooming-kits", true},
		{"Travel Grooming Kit", "Ustraa", "Travel-friendly grooming essentials", 799, 699, 80, "grooming-kits", true},
		{"Beard Starter Kit", "Beardo", "Beard oil + balm + brush + comb", 999, 849, 60, "grooming-kits", false},
		{"Shaving Essentials Kit", "The Man Company", "Razor + cream + brush + aftershave", 1299, 1099, 40, "grooming-kits", true},
		{"Pocket Comb", "Ustraa", "Premium pocket comb in leather case", 199, 149, 500, "accessories", false},
		{"Hair Dryer (Pro)", "L'Oréal", "Professional 2000W hair dryer", 1999, 1799, 30, "accessories", true},
		{"Trimmer (Cordless)", "L'Oréal", "Cordless beard trimmer with 3 guards", 1499, 1299, 45, "accessories", true},
		{"Hair Clipper Set", "L'Oréal", "Professional clipper with 5 attachments", 2499, 2199, 25, "accessories", true},
		{"Grooming Mirror (LED)", "The Man Company", "LED-lit grooming mirror with 2x zoom", 899, 799, 35, "accessories", false},
		{"Travel Toiletry Bag", "Mamaearth", "Waterproof travel toiletry bag", 499, 399, 60, "accessories", false},
		{"Satin Pillowcase", "Mamaearth", "Silk pillowcase for hair care", 399, 349, 80, "accessories", false},
	}
}

type seedVendor struct {
	StoreName string
	StoreSlug string
	Email     string
	Phone     string
	Address   string
	City      string
	State     string
	Pincode   string
	Lat       float64
	Lng       float64
	Rating    float64
}

func getVendorData() []seedVendor {
	return []seedVendor{
		{"Beardo Official Store", "beardo-official", "vendor1@demo.com", "+919876543212",
			"101, Commercial Street", "Bangalore", "Karnataka", "560001", 12.9719, 77.6112, 4.5},
		{"Ustraa Grooming Store", "ustraa-grooming", "vendor2@demo.com", "+919876543213",
			"45, Jubilee Hills", "Hyderabad", "Telangana", "500033", 17.4320, 78.4110, 4.3},
		{"The Man Company Store", "the-man-company", "vendor3@demo.com", "+919876543214",
			"22, Koregaon Park", "Pune", "Maharashtra", "411001", 18.5365, 73.8940, 4.6},
		{"Mamaearth Store", "mamaearth-store", "vendor4@demo.com", "+919876543215",
			"F-15, Connaught Place", "Delhi", "Delhi", "110001", 28.6300, 77.2180, 4.1},
		{"L'Oréal Professional", "loreal-pro", "vendor5@demo.com", "+919876543216",
			"34, Khan Market", "Delhi", "Delhi", "110003", 28.6015, 77.2275, 4.7},
	}
}

// ──────────────────────────────────────────────
// MAIN SEEDER
// ──────────────────────────────────────────────

func seedAllData(db *gorm.DB) {
	log.Println("Seeding demo data...")

	hash, _ := bcrypt.GenerateFromPassword([]byte("Demo@123"), bcrypt.DefaultCost)

	var existingBarbers int64
	db.Model(&models.Barber{}).Count(&existingBarbers)
	if existingBarbers > 0 {
		log.Println("Demo data already exists, skipping. Use --reset to re-seed.")
		return
	}

	// 1. Demo Customer
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
	log.Println("  Created customer: customer@demo.com / Demo@123")

	// 2. Vendors
	vendorData := getVendorData()
	type vendorRecord struct {
		User models.User
		Vend models.Vendor
	}
	vendorRecords := make([]vendorRecord, len(vendorData))

	for i, vd := range vendorData {
		user := models.User{
			FullName:     vd.StoreName + " Admin",
			Email:        vd.Email,
			Phone:        vd.Phone,
			PasswordHash: string(hash),
			Role:         models.RoleVendor,
			Status:       models.UserStatusActive,
		}
		db.Create(&user)
		db.Create(&models.Wallet{UserID: &user.ID, Balance: 0})

		vendor := models.Vendor{
			UserID:           user.ID,
			StoreName:        vd.StoreName,
			StoreSlug:        vd.StoreSlug,
			StoreDescription: vd.StoreName + " - official store on Barbar App. Authentic products guaranteed.",
			StoreEmail:       vd.Email,
			StorePhone:       vd.Phone,
			Address:          vd.Address,
			City:             vd.City,
			State:            vd.State,
			Pincode:          vd.Pincode,
			Latitude:         vd.Lat,
			Longitude:        vd.Lng,
			Status:           models.VendorStatusApproved,
			IsVerified:       true,
			IsActive:         true,
			Rating:           vd.Rating,
		}
		db.Create(&vendor)
		vendorRecords[i] = vendorRecord{User: user, Vend: vendor}
		log.Printf("  Created vendor: %s (%s / Demo@123)", vd.StoreName, vd.Email)
	}

	// 3. Barber Shops
	shops := getShopData()

	for _, sd := range shops {
		user := models.User{
			FullName:     sd.ShopName + " Owner",
			Email:        strings.ToLower(strings.ReplaceAll(sd.ShopName, " ", ".")) + "@demo.com",
			Phone:        fmt.Sprintf("+9190000000%02d", sd.ID),
			PasswordHash: string(hash),
			Role:         models.RoleBarber,
			Status:       models.UserStatusActive,
		}
		db.Create(&user)
		db.Create(&models.Wallet{UserID: &user.ID, Balance: 0})

		// Business days
		closedMap := make(map[string]bool)
		if sd.ClosedDays != "" {
			trimmed := strings.Trim(sd.ClosedDays, "[]\"")
			for _, d := range strings.Split(trimmed, ",") {
				closedMap[strings.TrimSpace(d)] = true
			}
		}
		allDays := []string{"monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"}
		var openDays []string
		for _, d := range allDays {
			if !closedMap[d] {
				openDays = append(openDays, d)
			}
		}
		if len(openDays) == 0 {
			openDays = allDays
		}
		daysJSON := `["` + strings.Join(openDays, `","`) + `"]`

		// Gallery images
		views := shopViews[sd.ID]
		if len(views) == 0 {
			views = shopViews[1]
		}
		var gallery []string
		for _, v := range views {
			gallery = append(gallery, fmt.Sprintf("/static/demo/shop%d-%s.png", sd.ID, v))
		}
		galleryJSON := `["` + strings.Join(gallery, `","`) + `"]`

		// Tags
		tags := []string{"verified"}
		if sd.HomeService {
			tags = append(tags, "home-service")
		}
		if sd.Rating >= 4.5 {
			tags = append(tags, "premium")
		}
		tagsJSON := `["` + strings.Join(tags, `","`) + `"]`

		barber := models.Barber{
			UserID:             user.ID,
			ShopName:           sd.ShopName,
			ShopDescription:    sd.Description,
			Address:            sd.Address,
			City:               sd.City,
			State:              sd.State,
			Pincode:            sd.Pincode,
			Latitude:           sd.Lat,
			Longitude:          sd.Lng,
			ShopImages:         []byte(galleryJSON),
			Rating:             sd.Rating,
			ReviewCount:        sd.ReviewCount,
			CurrentQueueLength: sd.QueueLength,
			AverageWaitTime:    sd.AvgWaitTime,
			ExperienceYears:    sd.ExperienceYears,
			StartTime:          sd.StartTime,
			EndTime:            sd.EndTime,
			SlotDuration:       30,
			BufferBetweenSlots: 5,
			MaxQueueSize:       50,
			Status:             models.BarberStatusActive,
			VerificationStatus: models.BarberVerifApproved,
			IsVerified:         true,
			IsFeatured:         sd.Rating >= 4.5,
			IsAvailable:        true,
			BusinessDays:       []byte(daysJSON),
			Tags:               []byte(tagsJSON),
		}
		if err := db.Create(&barber).Error; err != nil {
			log.Fatalf("Failed to create barber %s: %v", sd.ShopName, err)
		}

		for _, svc := range sd.Services {
			service := models.BarberService{
				BarberID:    barber.ID,
				Name:        svc.Name,
				Description: svc.Description,
				Category:    svc.Category,
				Price:       svc.Price,
				DurationMin: svc.DurationMin,
				IsActive:    true,
				IsAddon:     svc.IsAddon,
			}
			if err := db.Create(&service).Error; err != nil {
				log.Fatalf("Failed to create service %s: %v", svc.Name, err)
			}
		}
		log.Printf("  Created barber: %s (rating %.1f, %d services)", sd.ShopName, sd.Rating, len(sd.Services))
	}

	// 4. Products
	products := getProductData()
	categories := map[string]uuid.UUID{}
	var allCats []models.Category
	db.Find(&allCats)
	for _, c := range allCats {
		categories[c.Slug] = c.ID
	}

	vendorMap := map[int]models.Vendor{}
	for i, vr := range vendorRecords {
		vendorMap[i] = vr.Vend
	}

	vendorCategoryMap := map[string]int{
		"hair-care": 0, "beard-care": 0, "skin-care": 3,
		"shaving": 1, "grooming-kits": 2, "accessories": 4,
	}

	for _, p := range products {
		catID, catOK := categories[p.CategorySlug]
		vIdx, vOK := vendorCategoryMap[p.CategorySlug]
		if !catOK || !vOK {
			continue
		}
		vendor := vendorMap[vIdx]

		product := models.Product{
			VendorID:         vendor.ID,
			CategoryID:       catID,
			Name:             p.Name,
			Slug:             strings.ToLower(strings.ReplaceAll(p.Name, " ", "-")),
			Description:      p.Description,
			ShortDescription: p.Description,
			Brand:            p.Brand,
			BasePrice:        p.BasePrice,
			DiscountPrice:    p.DiscountPrice,
			AvailableStock:   int(p.AvailableStock),
			TotalStock:       int(p.AvailableStock) + 50,
			IsActive:         true,
			IsApproved:       true,
			IsFeatured:       p.IsFeatured,
		}
		if err := db.Create(&product).Error; err != nil {
			log.Printf("  WARN: Failed to create product %s: %v", p.Name, err)
		}
	}
	log.Printf("  Created %d products", len(products))
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
