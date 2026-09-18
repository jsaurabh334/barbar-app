package main

import (
	"log"
	"strings"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func seedCategories(db *gorm.DB) {
	categoryImages := map[string]string{
		"hair-care":        "https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=600&q=80",
		"beard-care":       "https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=600&q=80",
		"skin-care":        "https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80",
		"shaving":          "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
		"grooming-kits":    "https://images.unsplash.com/photo-1585751119414-ef2636f8aede?auto=format&fit=crop&w=600&q=80",
		"accessories":      "https://images.unsplash.com/photo-1508296695146-257a814070b4?auto=format&fit=crop&w=600&q=80",
		"haircut":          "https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=600&q=80",
		"beard":            "https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=600&q=80",
		"spa":              "https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=600&q=80",
		"hair-color":       "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=600&q=80",
		"facial":           "https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=600&q=80",
		"premium-grooming": "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
	}

	categories := []models.Category{
		{Name: "Hair Care", Slug: "hair-care", Description: "Shampoos, conditioners, oils & styling products", IsActive: true, SortOrder: 1, CategoryType: "product", Image: categoryImages["hair-care"]},
		{Name: "Beard Care", Slug: "beard-care", Description: "Beard oils, balms, shampoos & brushes", IsActive: true, SortOrder: 2, CategoryType: "product", Image: categoryImages["beard-care"]},
		{Name: "Skin Care", Slug: "skin-care", Description: "Face washes, moisturizers & lotions", IsActive: true, SortOrder: 3, CategoryType: "product", Image: categoryImages["skin-care"]},
		{Name: "Shaving", Slug: "shaving", Description: "Razors, creams, aftershaves & brushes", IsActive: true, SortOrder: 4, CategoryType: "product", Image: categoryImages["shaving"]},
		{Name: "Grooming Kits", Slug: "grooming-kits", Description: "Complete grooming kits & sets", IsActive: true, SortOrder: 5, CategoryType: "product", Image: categoryImages["grooming-kits"]},
		{Name: "Accessories", Slug: "accessories", Description: "Combs, brushes, clippers & trimmers", IsActive: true, SortOrder: 6, CategoryType: "product", Image: categoryImages["accessories"]},
		// Barber service categories
		{Name: "Haircut", Slug: "haircut", Description: "Haircut and styling services", IsActive: true, SortOrder: 1, CategoryType: models.CategoryTypeBarber, Image: categoryImages["haircut"]},
		{Name: "Beard", Slug: "beard", Description: "Beard trimming and shaping services", IsActive: true, SortOrder: 2, CategoryType: models.CategoryTypeBarber, Image: categoryImages["beard"]},
		{Name: "Spa", Slug: "spa", Description: "Spa and relaxation services", IsActive: true, SortOrder: 3, CategoryType: models.CategoryTypeBarber, Image: categoryImages["spa"]},
		{Name: "Hair Color", Slug: "hair-color", Description: "Hair coloring and highlights", IsActive: true, SortOrder: 4, CategoryType: models.CategoryTypeBarber, Image: categoryImages["hair-color"]},
		{Name: "Facial", Slug: "facial", Description: "Facial treatments and cleanup", IsActive: true, SortOrder: 5, CategoryType: models.CategoryTypeBarber, Image: categoryImages["facial"]},
		{Name: "Premium Grooming", Slug: "premium-grooming", Description: "Premium grooming and styling", IsActive: true, SortOrder: 6, CategoryType: models.CategoryTypeBarber, Image: categoryImages["premium-grooming"]},
	}
	for _, cat := range categories {
		var existing models.Category
		err := db.Where("slug = ?", cat.Slug).First(&existing).Error
		if err == nil {
			db.Model(&existing).Updates(map[string]interface{}{
				"name":          cat.Name,
				"description":   cat.Description,
				"image":         cat.Image,
				"category_type": cat.CategoryType,
				"sort_order":    cat.SortOrder,
				"is_active":     true,
			})
		} else {
			db.Create(&cat)
			log.Printf("  Created category: %s", cat.Name)
		}
	}
}

func seedProducts(db *gorm.DB) {
	products := getProductData()

	productImageMap := map[string]string{
		"Argan Oil Shampoo":         "https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&w=600&q=80",
		"Silk Conditioner":          "https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=600&q=80",
		"Hair Growth Serum":         "https://images.unsplash.com/photo-1608248597359-5980a3c20c02?auto=format&fit=crop&w=600&q=80",
		"Hair Spray (Strong Hold)":  "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80",
		"Hair Wax (Matte)":          "https://images.unsplash.com/photo-1597854710119-a5a8fc7e3ef4?auto=format&fit=crop&w=600&q=80",
		"Beard Oil (Woody)":         "https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=600&q=80",
		"Beard Balm":                "https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80",
		"Beard Wash":                "https://images.unsplash.com/photo-1567928805192-d35d641494be?auto=format&fit=crop&w=600&q=80",
		"Beard Brush (Boar)":        "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
		"Beard Growth Oil":          "https://images.unsplash.com/photo-1608248597359-5980a3c20c02?auto=format&fit=crop&w=600&q=80",
		"Face Wash (Charcoal)":      "https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80",
		"Moisturizer (Day)":         "https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=600&q=80",
		"Under Eye Cream":           "https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80",
		"Lip Balm (Men)":            "https://images.unsplash.com/photo-1597854710119-a5a8fc7e3ef4?auto=format&fit=crop&w=600&q=80",
		"Razor Kit (5-Blade)":       "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
		"Shaving Cream":             "https://images.unsplash.com/photo-1585751119414-ef2636f8aede?auto=format&fit=crop&w=600&q=80",
		"Aftershave Balm":           "https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80",
		"Shaving Brush":             "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
		"Complete Grooming Kit":     "https://images.unsplash.com/photo-1585751119414-ef2636f8aede?auto=format&fit=crop&w=600&q=80",
		"Travel Grooming Kit":       "https://images.unsplash.com/photo-1585751119414-ef2636f8aede?auto=format&fit=crop&w=600&q=80",
		"Beard Starter Kit":         "https://images.unsplash.com/photo-1621607512214-68297480165e?auto=format&fit=crop&w=600&q=80",
		"Shaving Essentials Kit":    "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
		"Pocket Comb":               "https://images.unsplash.com/photo-1508296695146-257a814070b4?auto=format&fit=crop&w=600&q=80",
		"Hair Dryer (Pro)":          "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80",
		"Trimmer (Cordless)":        "https://images.unsplash.com/photo-1508296695146-257a814070b4?auto=format&fit=crop&w=600&q=80",
		"Hair Clipper Set":          "https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&w=600&q=80",
		"Grooming Mirror (LED)":     "https://images.unsplash.com/photo-1512690459411-b9245aed614b?auto=format&fit=crop&w=600&q=80",
		"Travel Toiletry Bag":       "https://images.unsplash.com/photo-1585751119414-ef2636f8aede?auto=format&fit=crop&w=600&q=80",
		"Satin Pillowcase":          "https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=600&q=80",
	}

	categories := map[string]uuid.UUID{}
	var allCats []models.Category
	db.Find(&allCats)
	for _, c := range allCats {
		categories[c.Slug] = c.ID
	}

	vendorSlugs := []string{"beardo-official", "ustraa-grooming", "the-man-company", "mamaearth-store", "loreal-pro"}
	var vendors []models.Vendor
	db.Where("business_slug IN ?", vendorSlugs).Find(&vendors)
	vendorMap := map[int]models.Vendor{}
	for i, slug := range vendorSlugs {
		for _, v := range vendors {
			if v.BusinessSlug == slug {
				vendorMap[i] = v
				break
			}
		}
	}

	vendorCategoryMap := map[string]int{
		"hair-care": 0, "beard-care": 0, "skin-care": 3,
		"shaving": 1, "grooming-kits": 2, "accessories": 4,
	}

	count := 0
	for _, p := range products {
		catID, catOK := categories[p.CategorySlug]
		vIdx, vOK := vendorCategoryMap[p.CategorySlug]
		if !catOK || !vOK {
			continue
		}
		vendor, vOK := vendorMap[vIdx]
		if !vOK {
			continue
		}

		slug := strings.ToLower(strings.ReplaceAll(p.Name, " ", "-"))
		var product models.Product
		pErr := db.Where("vendor_id = ? AND (slug = ? OR name = ?)", vendor.ID, slug, p.Name).First(&product).Error

		if pErr == nil {
			db.Model(&product).Updates(map[string]interface{}{
				"category_id":       catID,
				"name":              p.Name,
				"description":       p.Description,
				"short_description": p.Description,
				"brand_name":        p.Brand,
				"base_price":        p.BasePrice,
				"discount_price":    p.DiscountPrice,
				"available_stock":   int(p.AvailableStock),
				"total_stock":       int(p.AvailableStock) + 50,
				"is_active":         true,
				"is_approved":       true,
				"is_featured":       p.IsFeatured,
			})
		} else {
			product = models.Product{
				VendorID:         vendor.ID,
				CategoryID:       catID,
				Name:             p.Name,
				Slug:             slug,
				Description:      p.Description,
				ShortDescription: p.Description,
				BrandName:        p.Brand,
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
				continue
			}
		}

		// Ensure ProductImage exists
		imgURL := productImageMap[p.Name]
		if imgURL == "" {
			imgURL = "https://images.unsplash.com/photo-1585751119414-ef2636f8aede?auto=format&fit=crop&w=600&q=80"
		}
		var existingImg models.ProductImage
		if err := db.Where("product_id = ?", product.ID).First(&existingImg).Error; err != nil {
			prodImg := models.ProductImage{
				ProductID: product.ID,
				ImageURL:  imgURL,
				AltText:   p.Name,
				IsPrimary: true,
			}
			db.Create(&prodImg)
		} else {
			db.Model(&existingImg).Updates(map[string]interface{}{
				"image_url":  imgURL,
				"is_primary": true,
			})
		}
		count++
	}
	log.Printf("  Products ready: %d products with active stock and photos", count)
}
