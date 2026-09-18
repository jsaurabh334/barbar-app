package main

import (
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func seedDemoCustomer(db *gorm.DB) {
	var user models.User
	err := db.Where("email = ? OR phone = ?", "customer@demo.com", "+919876543210").First(&user).Error

	hash, _ := bcrypt.GenerateFromPassword([]byte("Demo@123"), bcrypt.DefaultCost)
	if err == nil {
		db.Model(&user).Updates(map[string]interface{}{
			"email":         "customer@demo.com",
			"phone":         "+919876543210",
			"full_name":     "Demo Customer",
			"password_hash": string(hash),
			"role":          models.RoleCustomer,
			"status":        models.UserStatusActive,
		})
		log.Println("  Customer updated: customer@demo.com / Demo@123")
		return
	}

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
	hash, _ := bcrypt.GenerateFromPassword([]byte("Demo@123"), bcrypt.DefaultCost)

	// Vendors
	vendorData := getVendorData()
	type vendorRecord struct {
		User models.User
		Vend models.Vendor
	}
	vendorRecords := make([]vendorRecord, len(vendorData))

	for i, vd := range vendorData {
		var user models.User
		err := db.Where("email = ? OR phone = ?", vd.Email, vd.Phone).First(&user).Error
		if err == nil {
			db.Model(&user).Updates(map[string]interface{}{
				"email":         vd.Email,
				"phone":         vd.Phone,
				"full_name":     vd.BusinessName + " Admin",
				"password_hash": string(hash),
				"role":          models.RoleVendor,
				"status":        models.UserStatusActive,
			})
		} else {
			user = models.User{
				FullName:     vd.BusinessName + " Admin",
				Email:        vd.Email,
				Phone:        vd.Phone,
				PasswordHash: string(hash),
				Role:         models.RoleVendor,
				Status:       models.UserStatusActive,
			}
			db.Create(&user)
			db.Create(&models.Wallet{UserID: &user.ID, Balance: 0})
		}

		var vendor models.Vendor
		vErr := db.Where("user_id = ? OR business_slug = ?", user.ID, vd.BusinessSlug).First(&vendor).Error
		if vErr == nil {
			db.Model(&vendor).Updates(map[string]interface{}{
				"business_name":        vd.BusinessName,
				"business_description": vd.BusinessName + " - official seller on Barbar App. Authentic products guaranteed.",
				"business_email":       vd.Email,
				"business_phone":       vd.Phone,
				"address":              vd.Address,
				"city":                 vd.City,
				"state":                vd.State,
				"pincode":              vd.Pincode,
				"latitude":             vd.Lat,
				"longitude":            vd.Lng,
				"status":               models.VendorStatusApproved,
				"is_verified":          true,
				"is_active":            true,
				"rating":               vd.Rating,
			})
		} else {
			vendor = models.Vendor{
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
		}
		vendorRecords[i] = vendorRecord{User: user, Vend: vendor}
		log.Printf("  Vendor ready: %s (%s / Demo@123)", vd.BusinessName, vd.Email)
	}

	// Barber Shop real photos
	realShopPhotos := map[int][]string{
		1:  {"https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=800&q=80"},
		2:  {"https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=800&q=80"},
		3:  {"https://images.unsplash.com/photo-1599351431202-1e0f0137899a?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=800&q=80"},
		4:  {"https://images.unsplash.com/photo-1622286342621-4bd786c2447c?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1512690459411-b9245aed614b?auto=format&fit=crop&w=800&q=80"},
		5:  {"https://images.unsplash.com/photo-1512690459411-b9245aed614b?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1534778310344-933e4f3a7444?auto=format&fit=crop&w=800&q=80"},
		6:  {"https://images.unsplash.com/photo-1534778310344-933e4f3a7444?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1517832606299-7ae9b720a186?auto=format&fit=crop&w=800&q=80"},
		7:  {"https://images.unsplash.com/photo-1517832606299-7ae9b720a186?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1593702295094-ada75541005f?auto=format&fit=crop&w=800&q=80"},
		8:  {"https://images.unsplash.com/photo-1593702295094-ada75541005f?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=800&q=80"},
		9:  {"https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?auto=format&fit=crop&w=800&q=80"},
		10: {"https://images.unsplash.com/photo-1634449571010-02389ed0f9b0?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?auto=format&fit=crop&w=800&q=80"},
		11: {"https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=800&q=80"},
		12: {"https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80"},
		13: {"https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=80"},
		14: {"https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&w=800&q=80"},
		15: {"https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?auto=format&fit=crop&w=800&q=80", "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=800&q=80"},
	}

	// Barber Shops
	shops := getShopData()

	var svcCategories []models.Category
	db.Where("category_type = ?", models.CategoryTypeBarber).Find(&svcCategories)
	svcCatMap := make(map[string]uuid.UUID)
	for _, c := range svcCategories {
		svcCatMap[c.Name] = c.ID
		svcCatMap[strings.TrimSpace(c.Name)] = c.ID
		svcCatMap[c.Slug] = c.ID
	}

	for _, sd := range shops {
		barberEmail := strings.ToLower(strings.ReplaceAll(sd.ShopName, " ", ".")) + "@demo.com"
		barberPhone := fmt.Sprintf("+9190000000%02d", sd.ID)

		var user models.User
		uErr := db.Where("email = ? OR phone = ?", barberEmail, barberPhone).First(&user).Error
		if uErr == nil {
			db.Model(&user).Updates(map[string]interface{}{
				"email":         barberEmail,
				"phone":         barberPhone,
				"full_name":     sd.ShopName + " Owner",
				"password_hash": string(hash),
				"role":          models.RoleBarber,
				"status":        models.UserStatusActive,
			})
		} else {
			user = models.User{
				FullName:     sd.ShopName + " Owner",
				Email:        barberEmail,
				Phone:        barberPhone,
				PasswordHash: string(hash),
				Role:         models.RoleBarber,
				Status:       models.UserStatusActive,
			}
			db.Create(&user)
			db.Create(&models.Wallet{UserID: &user.ID, Balance: 0})
		}

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
		photos := realShopPhotos[sd.ID]
		if len(photos) == 0 {
			photos = realShopPhotos[1]
		}
		galleryJSON := `["` + strings.Join(photos, `","`) + `"]`

		// Tags
		tags := []string{"verified"}
		if sd.HomeService {
			tags = append(tags, "home-service")
		}
		if sd.Rating >= 4.5 {
			tags = append(tags, "premium")
		}
		tagsJSON := `["` + strings.Join(tags, `","`) + `"]`

		var barber models.Barber
		bErr := db.Where("user_id = ?", user.ID).First(&barber).Error
		if bErr == nil {
			db.Model(&barber).Updates(map[string]interface{}{
				"shop_name":                 sd.ShopName,
				"shop_description":          sd.Description,
				"shop_image":                photos[0],
				"shop_images":               []byte(galleryJSON),
				"phone":                     barberPhone,
				"email":                     barberEmail,
				"address":                   sd.Address,
				"city":                      sd.City,
				"state":                     sd.State,
				"pincode":                   sd.Pincode,
				"latitude":                  sd.Lat,
				"longitude":                 sd.Lng,
				"rating":                    sd.Rating,
				"review_count":              sd.ReviewCount,
				"current_queue_length":       sd.QueueLength,
				"average_wait_time":          sd.AvgWaitTime,
				"experience_years":          sd.ExperienceYears,
				"start_time":                sd.StartTime,
				"end_time":                  sd.EndTime,
				"slot_duration":             30,
				"buffer_between_slots":       5,
				"max_queue_size":            50,
				"status":                    models.BarberStatusActive,
				"verification_status":       models.BarberVerifApproved,
				"is_verified":               true,
				"is_featured":               sd.Rating >= 4.5,
				"is_available":              true,
				"business_days":             []byte(daysJSON),
				"tags":                      []byte(tagsJSON),
				"amenities":                 []byte(sd.Amenities),
				"is_home_service_available": sd.HomeService,
				"service_radius_km":         sd.ServiceRadiusKm,
				"travel_charge_per_km":      sd.TravelChargePerKm,
				"base_travel_charge":        sd.BaseTravelCharge,
			})
		} else {
			barber = models.Barber{
				UserID:                  user.ID,
				ShopName:                sd.ShopName,
				ShopDescription:         sd.Description,
				ShopImage:               photos[0],
				ShopImages:              []byte(galleryJSON),
				Phone:                   barberPhone,
				Email:                   barberEmail,
				Address:                 sd.Address,
				City:                    sd.City,
				State:                   sd.State,
				Pincode:                 sd.Pincode,
				Latitude:                sd.Lat,
				Longitude:               sd.Lng,
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
		}

		for _, svc := range sd.Services {
			catID, ok := svcCatMap[svc.Category]
			if !ok {
				catID = svcCatMap[strings.TrimSpace(svc.Category)]
			}
			var existingSvc models.BarberService
			sErr := db.Where("barber_id = ? AND name = ?", barber.ID, svc.Name).First(&existingSvc).Error
			if sErr == nil {
				db.Model(&existingSvc).Updates(map[string]interface{}{
					"description": svc.Description,
					"category_id": &catID,
					"price":       svc.Price,
					"duration_min": svc.DurationMin,
					"is_active":    true,
					"is_addon":     svc.IsAddon,
				})
			} else {
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
				db.Create(&service)
			}
		}

		// Auto-create staff record for the owner
		var staff models.BarberStaff
		stErr := db.Where("barber_id = ? AND user_id = ?", barber.ID, user.ID).First(&staff).Error
		if stErr == nil {
			db.Model(&staff).Updates(map[string]interface{}{
				"name":        sd.ShopName + " Master",
				"role":        models.RoleManager,
				"is_active":   true,
				"working_days": "0,1,2,3,4,5,6",
				"start_time":  sd.StartTime,
				"end_time":    sd.EndTime,
			})
		} else {
			staff = models.BarberStaff{
				BarberID:    barber.ID,
				UserID:      &user.ID,
				Name:        sd.ShopName + " Master",
				Role:        models.RoleManager,
				IsActive:    true,
				WorkingDays: "0,1,2,3,4,5,6",
				StartTime:   sd.StartTime,
				EndTime:     sd.EndTime,
			}
			db.Create(&staff)
		}

		// Assign all services to staff
		var createdServices []models.BarberService
		if err := db.Where("barber_id = ?", barber.ID).Find(&createdServices).Error; err == nil {
			for _, svc := range createdServices {
				var staffSvc models.StaffService
				if err := db.Where("staff_id = ? AND service_id = ?", staff.ID, svc.ID).First(&staffSvc).Error; err != nil {
					staffSvc = models.StaffService{
						StaffID:   staff.ID,
						ServiceID: svc.ID,
						IsActive:  true,
					}
					db.Create(&staffSvc)
				}
			}
		}
		log.Printf("  Barber ready: %s (rating %.1f, %d services) - %s / Demo@123", sd.ShopName, sd.Rating, len(sd.Services), barberEmail)
	}
}

func seedDemoActivity(db *gorm.DB) {
	var customer models.User
	if err := db.Where("email = ?", "customer@demo.com").First(&customer).Error; err != nil {
		return
	}

	// 1. Default address for customer
	var address models.Address
	if err := db.Where("user_id = ?", customer.ID).First(&address).Error; err != nil {
		address = models.Address{
			UserID:      customer.ID,
			Label:       "Home",
			FullName:    customer.FullName,
			Phone:       customer.Phone,
			Pincode:     "560038",
			Line1:       "Flat 402, Sunshine Heights, 100 Feet Road",
			Line2:       "Indiranagar",
			Landmark:    "Near Metro Station",
			City:        "Bangalore",
			State:       "Karnataka",
			Country:     "India",
			Latitude:    12.9716,
			Longitude:   77.5946,
			IsDefault:   true,
			AddressType: "home",
		}
		db.Create(&address)
		log.Println("  Demo customer address created")
	}

	// 2. Active booking at Barber 1
	var barber models.Barber
	if err := db.Where("shop_name = ?", "Classic Cuts Studio").First(&barber).Error; err == nil {
		var existingBooking models.Booking
		if err := db.Where("customer_id = ? AND barber_id = ? AND status IN ?", customer.ID, barber.ID, []models.BookingStatus{models.BookingStatusWaiting, models.BookingStatusConfirmed}).First(&existingBooking).Error; err != nil {
			now := time.Now()
			booking := models.Booking{
				BarberID:         barber.ID,
				CustomerID:       customer.ID,
				Status:           models.BookingStatusWaiting,
				ScheduledStart:   now.Add(30 * time.Minute),
				ScheduledEnd:     now.Add(75 * time.Minute),
				QueuePosition:    2,
				EstimatedWaitMin: 15,
				TotalDuration:    45,
				TotalPrice:       598,
				FinalPrice:       598,
				PaymentStatus:    "paid",
				PaymentMethod:    "wallet",
				Notes:            "Demo haircut booking",
			}
			if err := db.Create(&booking).Error; err == nil {
				var svcs []models.BarberService
				db.Where("barber_id = ?", barber.ID).Limit(2).Find(&svcs)
				for _, s := range svcs {
					bs := models.BookingService{
						BookingID:   booking.ID,
						ServiceID:   s.ID,
						ServiceName: s.Name,
						Quantity:    1,
						UnitPrice:   s.Price,
						TotalPrice:  s.Price,
						DurationMin: s.DurationMin,
					}
					db.Create(&bs)
				}
				log.Println("  Demo active booking created for customer @ Classic Cuts Studio")
			}
		}
	}

	// 3. Demo order assigned to delivery partner
	var vendor models.Vendor
	var deliveryUser models.User
	var product models.Product

	vErr := db.Where("business_slug = ?", "beardo-official").First(&vendor).Error
	dErr := db.Where("phone = ?", "+916666666666").First(&deliveryUser).Error
	pErr := db.Where("vendor_id = ?", vendor.ID).First(&product).Error

	if vErr == nil && dErr == nil && pErr == nil {
		var existingOrder models.Order
		if err := db.Where("customer_id = ? AND status = ?", customer.ID, models.OrderStatusOutForDelivery).First(&existingOrder).Error; err != nil {
			now := time.Now()
			orderNum := fmt.Sprintf("ORD-DEMO-%d", now.Unix()%100000)
			order := models.Order{
				CustomerID:        customer.ID,
				VendorID:          vendor.ID,
				BuyerType:         models.BuyerTypeCustomer,
				OrderNumber:       orderNum,
				Status:            models.OrderStatusOutForDelivery,
				ItemsTotal:        product.DiscountPrice,
				ShippingCharge:    40,
				TaxAmount:         0,
				DiscountAmount:    0,
				FinalAmount:       product.DiscountPrice + 40,
				PaymentStatus:     models.PaymentStatusSuccess,
				PaymentMethod:     "online",
				PaymentID:         "pay_demo_12345",
				ShippingAddressID: &address.ID,
				BillingAddressID:  &address.ID,
				DeliveryNotes:     "Please call before arriving",
				DeliveryPartnerID: &deliveryUser.ID,
				AssignedAt:        &now,
				PickedUpAt:        &now,
			}
			if err := db.Create(&order).Error; err == nil {
				item := models.OrderItem{
					OrderID:      order.ID,
					ProductID:    product.ID,
					ProductName:  product.Name,
					Quantity:     1,
					UnitPrice:    product.DiscountPrice,
					TotalPrice:   product.DiscountPrice,
					ProductImage: "https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80",
				}
				db.Create(&item)
				log.Println("  Demo live order created: " + orderNum + " (Out For Delivery)")
			}
		}
	}
}
