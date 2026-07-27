package main

import (
	"log"
	"strings"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

func seedCategories(db *gorm.DB) {
	categories := []models.Category{
		{Name: "Hair Care", Slug: "hair-care", Description: "Shampoos, conditioners, oils & styling products", IsActive: true, SortOrder: 1, CategoryType: "product"},
		{Name: "Beard Care", Slug: "beard-care", Description: "Beard oils, balms, shampoos & brushes", IsActive: true, SortOrder: 2, CategoryType: "product"},
		{Name: "Skin Care", Slug: "skin-care", Description: "Face washes, moisturizers & lotions", IsActive: true, SortOrder: 3, CategoryType: "product"},
		{Name: "Shaving", Slug: "shaving", Description: "Razors, creams, aftershaves & brushes", IsActive: true, SortOrder: 4, CategoryType: "product"},
		{Name: "Grooming Kits", Slug: "grooming-kits", Description: "Complete grooming kits & sets", IsActive: true, SortOrder: 5, CategoryType: "product"},
		{Name: "Accessories", Slug: "accessories", Description: "Combs, brushes, clippers & trimmers", IsActive: true, SortOrder: 6, CategoryType: "product"},
		// Barber service categories
		{Name: "Haircut", Slug: "haircut", Description: "Haircut and styling services", IsActive: true, SortOrder: 1, CategoryType: models.CategoryTypeBarber},
		{Name: "Beard", Slug: "beard", Description: "Beard trimming and shaping services", IsActive: true, SortOrder: 2, CategoryType: models.CategoryTypeBarber},
		{Name: "Spa", Slug: "spa", Description: "Spa and relaxation services", IsActive: true, SortOrder: 3, CategoryType: models.CategoryTypeBarber},
		{Name: "Hair Color", Slug: "hair-color", Description: "Hair coloring and highlights", IsActive: true, SortOrder: 4, CategoryType: models.CategoryTypeBarber},
		{Name: "Facial", Slug: "facial", Description: "Facial treatments and cleanup", IsActive: true, SortOrder: 5, CategoryType: models.CategoryTypeBarber},
		{Name: "Premium Grooming", Slug: "premium-grooming", Description: "Premium grooming and styling", IsActive: true, SortOrder: 6, CategoryType: models.CategoryTypeBarber},
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

func seedProducts(db *gorm.DB) {
	products := getProductData()

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

		product := models.Product{
			VendorID:         vendor.ID,
			CategoryID:       catID,
			Name:             p.Name,
			Slug:             strings.ToLower(strings.ReplaceAll(p.Name, " ", "-")),
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
		}
		count++
	}
	log.Printf("  Created %d products", count)
}
