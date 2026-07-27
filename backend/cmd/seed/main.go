package main

import (
	"flag"
	"fmt"
	"log"

	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	"gorm.io/gorm"
)

func main() {
	flagAdmin := flag.Bool("admin", false, "Seed admin account only")
	flagCatalog := flag.Bool("catalog", false, "Seed categories and products only")
	flagDemoVendor := flag.Bool("demo-vendor", false, "Seed demo vendors and barber shops only")
	flagDemoDelivery := flag.Bool("demo-delivery", false, "Seed demo delivery partner only")
	flagLookup := flag.Bool("lookup", false, "Seed lookup/master data (platform settings)")
	flagNotifications := flag.Bool("notifications", false, "Seed notification templates only")
	flagSettings := flag.Bool("settings", false, "Seed platform settings (alias for --lookup)")
	flagReset := flag.Bool("reset", false, "Delete existing demo data and re-seed")
	flagAll := flag.Bool("all", false, "Seed all data (default)")
	flagHelp := flag.Bool("help", false, "Show available flags and usage")
	flag.Parse()

	if *flagHelp {
		printHelp()
		return
	}

	log.Println("Barbar App - Data Seeder")
	log.Println("=========================")

	cfg := config.Load()
	db := database.InitPostgres(&cfg.Database)
	database.RunMigrations(db)

	if *flagReset {
		log.Println("--reset flag detected, clearing existing demo data...")
		resetDemoData(db)
		log.Println("Existing demo data cleared.")
	}

	specificFlags := *flagAdmin || *flagCatalog || *flagDemoVendor || *flagDemoDelivery || *flagLookup || *flagNotifications || *flagSettings
	seedAll := *flagAll || !specificFlags

	if seedAll {
		seedAdmin(db)
		seedCategories(db)
		seedNotificationTemplates(db)
		seedPlatformSettings(db)
		seedAllData(db)
	} else {
		if *flagAdmin {
			seedAdmin(db)
		}
		if *flagLookup || *flagSettings {
			seedPlatformSettings(db)
		}
		if *flagNotifications {
			seedNotificationTemplates(db)
		}
		if *flagCatalog {
			seedCategories(db)
			seedProducts(db)
		}
		if *flagDemoVendor {
			seedVendorsAndShops(db)
		}
		if *flagDemoDelivery {
			seedDemoDelivery(db)
		}
	}

	if seedAll || *flagDemoVendor {
		log.Println("Generating demo placeholder images...")
		shopNames := getShopNames()
		generateDemoImages("static/demo", shopNames)
	}

	log.Println("=========================")
	if seedAll {
		log.Println("Seeding complete!")
		log.Printf("  Vendors:   5")
		log.Printf("  Shops:     15")
		log.Printf("  Services:  90")
		log.Printf("  Products:  30")
		log.Printf("  Categories: 6")
		log.Printf("  Demo images: ~75")
	} else {
		log.Println("Seeding complete!")
	}
}

func seedAllData(db *gorm.DB) {
	log.Println("Seeding demo data...")

	var existingBarbers int64
	db.Model(&models.Barber{}).Count(&existingBarbers)
	if existingBarbers > 0 {
		log.Println("Demo data already exists, skipping. Use --reset to re-seed.")
		return
	}

	seedDemoCustomer(db)
	seedDemoDelivery(db)
	seedVendorsAndShops(db)
	seedProducts(db)
}

func printHelp() {
	fmt.Print(`Barbar App - Data Seeder

Usage:
  go run ./cmd/seed/ [flags]

Flags:
  --admin           Seed admin account only
  --catalog         Seed categories and products only
  --demo-vendor     Seed demo vendors and barber shops only
  --demo-delivery   Seed demo delivery partner only
  --lookup          Seed lookup/master data (platform settings)
  --notifications   Seed notification templates only
  --settings        Seed platform settings (alias for --lookup)
  --reset           Delete existing demo data and re-seed
  --all             Seed all data (default when no flags specified)
  --help            Show this help message

Examples:
  go run ./cmd/seed/                    Seed all data
  go run ./cmd/seed/ --admin            Seed admin only
  go run ./cmd/seed/ --admin --lookup   Seed admin + platform settings
  go run ./cmd/seed/ --reset            Clear + seed all
  go run ./cmd/seed/ --catalog --reset  Clear + seed catalog only
  go run ./cmd/seed/ --help             Show this help message
`)
}
