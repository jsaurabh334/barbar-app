package main

import (
	"fmt"
	"log"
	"strings"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func seedDemoCustomer(db *gorm.DB) {
	var count int64
	db.Model(&models.User{}).Where("email = ?", "customer@demo.com").Count(&count)
	if count > 0 {
		log.Println("Demo customer already exists, skipping...")
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
	log.Println("  Created customer: customer@demo.com / Demo@123")
}

func seedVendorsAndShops(db *gorm.DB) {
	var existingBarbers int64
	db.Model(&models.Barber{}).Count(&existingBarbers)
	if existingBarbers > 0 {
		log.Println("Demo vendors/shops already exist, skipping...")
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte("Demo@123"), bcrypt.DefaultCost)

	// Vendors
	vendorData := getVendorData()
	type vendorRecord struct {
		User models.User
		Vend models.Vendor
	}
	vendorRecords := make([]vendorRecord, len(vendorData))

	for i, vd := range vendorData {
		user := models.User{
			FullName:     vd.BusinessName + " Admin",
			Email:        vd.Email,
			Phone:        vd.Phone,
			PasswordHash: string(hash),
			Role:         models.RoleVendor,
			Status:       models.UserStatusActive,
		}
		db.Create(&user)
		db.Create(&models.Wallet{UserID: &user.ID, Balance: 0})

		vendor := models.Vendor{
			UserID:              user.ID,
			BusinessName:        vd.BusinessName,
			BusinessSlug:        vd.BusinessSlug,
			BusinessDescription: vd.BusinessName + " - official seller on Barbar App. Authentic products guaranteed.",
			BusinessEmail:       vd.Email,
			BusinessPhone:       vd.Phone,
			Address:             vd.Address,
			City:                vd.City,
			State:               vd.State,
			Pincode:             vd.Pincode,
			Latitude:            vd.Lat,
			Longitude:           vd.Lng,
			Status:              models.VendorStatusApproved,
			IsVerified:          true,
			IsActive:            true,
			Rating:              vd.Rating,
		}
		db.Create(&vendor)
		vendorRecords[i] = vendorRecord{User: user, Vend: vendor}
		log.Printf("  Created vendor: %s (%s / Demo@123)", vd.BusinessName, vd.Email)
	}

	// Barber Shops
	shops := getShopData()

	var svcCategories []models.Category
	db.Where("category_type = ?", models.CategoryTypeBarber).Find(&svcCategories)
	svcCatMap := make(map[string]uuid.UUID)
	for _, c := range svcCategories {
		svcCatMap[c.Name] = c.ID
	}

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
			UserID:                  user.ID,
			ShopName:                sd.ShopName,
			ShopDescription:         sd.Description,
			Address:                 sd.Address,
			City:                    sd.City,
			State:                   sd.State,
			Pincode:                 sd.Pincode,
			Latitude:                sd.Lat,
			Longitude:               sd.Lng,
			ShopImages:              []byte(galleryJSON),
			Rating:                  sd.Rating,
			ReviewCount:             sd.ReviewCount,
			CurrentQueueLength:      sd.QueueLength,
			AverageWaitTime:         sd.AvgWaitTime,
			ExperienceYears:         sd.ExperienceYears,
			StartTime:               sd.StartTime,
			EndTime:                 sd.EndTime,
			SlotDuration:            30,
			BufferBetweenSlots:      5,
			MaxQueueSize:            50,
			Status:                  models.BarberStatusActive,
			VerificationStatus:      models.BarberVerifApproved,
			IsVerified:              true,
			IsFeatured:              sd.Rating >= 4.5,
			IsAvailable:             true,
			BusinessDays:            []byte(daysJSON),
			Tags:                    []byte(tagsJSON),
			Amenities:               []byte(sd.Amenities),
			IsHomeServiceAvailable:  sd.HomeService,
			ServiceRadiusKm:         sd.ServiceRadiusKm,
			TravelChargePerKm:       sd.TravelChargePerKm,
			BaseTravelCharge:        sd.BaseTravelCharge,
		}
		if err := db.Create(&barber).Error; err != nil {
			log.Fatalf("Failed to create barber %s: %v", sd.ShopName, err)
		}

		for _, svc := range sd.Services {
			catID := svcCatMap[svc.Category]
			service := models.BarberService{
				BarberID:    barber.ID,
				Name:        svc.Name,
				Description: svc.Description,
				CategoryID:  &catID,
				Price:       svc.Price,
				DurationMin: svc.DurationMin,
				IsActive:    true,
				IsAddon:     svc.IsAddon,
			}
			if err := db.Create(&service).Error; err != nil {
				log.Fatalf("Failed to create service %s: %v", svc.Name, err)
			}
		}
		// Auto-create staff record for the owner
		staff := models.BarberStaff{
			BarberID:    barber.ID,
			UserID:      &user.ID,
			Name:        sd.ShopName + " Staff",
			Role:        models.RoleManager,
			IsActive:    true,
			WorkingDays: "0,1,2,3,4,5,6",
			StartTime:   sd.StartTime,
			EndTime:     sd.EndTime,
		}
		if err := db.Create(&staff).Error; err != nil {
			log.Fatalf("Failed to create staff for %s: %v", sd.ShopName, err)
		}
		// Assign all services to the default staff
		var createdServices []models.BarberService
		if err := db.Where("barber_id = ?", barber.ID).Find(&createdServices).Error; err == nil {
			for _, svc := range createdServices {
				staffSvc := models.StaffService{
					StaffID:   staff.ID,
					ServiceID: svc.ID,
					IsActive:  true,
				}
				if err := db.Create(&staffSvc).Error; err != nil {
					log.Fatalf("Failed to assign service to staff: %v", err)
				}
			}
		}
		log.Printf("  Created barber: %s (rating %.1f, %d services, staff created)", sd.ShopName, sd.Rating, len(sd.Services))
	}
}
