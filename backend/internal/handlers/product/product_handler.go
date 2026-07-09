package product

import (
	"encoding/json"
	"math"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ProductHandler struct {
	db *gorm.DB
}

func NewProductHandler(db *gorm.DB) *ProductHandler {
	return &ProductHandler{db: db}
}

type CreateProductRequest struct {
	CategoryID       uuid.UUID                `json:"category_id" binding:"required"`
	SubCategoryID    *uuid.UUID               `json:"sub_category_id"`
	Name             string                   `json:"name" binding:"required,min=2,max=255"`
	Description      string                   `json:"description"`
	ShortDescription string                   `json:"short_description"`
	Brand            string                   `json:"brand"`
	BasePrice        float64                  `json:"base_price" binding:"required,gt=0"`
	DiscountPrice    float64                  `json:"discount_price"`
	TaxPercent       float64                  `json:"tax_percent"`
	TotalStock       int                      `json:"total_stock" binding:"required,gte=0"`
	LowStockThreshold int                     `json:"low_stock_threshold"`
	HasVariants      bool                     `json:"has_variants"`
	Images           []ProductImageInput      `json:"images"`
	Variants         []ProductVariantInput    `json:"variants,omitempty"`
	Tags             []string                 `json:"tags"`
}

type ProductImageInput struct {
	ImageURL  string `json:"image_url" binding:"required"`
	AltText   string `json:"alt_text"`
	IsPrimary bool   `json:"is_primary"`
}

type ProductVariantInput struct {
	Name         string  `json:"name" binding:"required"`
	Value        string  `json:"value" binding:"required"`
	Price        float64 `json:"price" binding:"required"`
	DiscountPrice float64 `json:"discount_price"`
	Stock        int     `json:"stock" binding:"required"`
	SKU          string  `json:"sku"`
}

func (h *ProductHandler) Create(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var vendor models.Vendor
	if err := h.db.Where("user_id = ? AND status = ?", userID, models.VendorStatusApproved).First(&vendor).Error; err != nil {
		utils.ForbiddenResponse(c, "Only approved vendors can create products")
		return
	}

	var req CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	discountPercent := 0.0
	if req.DiscountPrice > 0 && req.DiscountPrice < req.BasePrice {
		discountPercent = ((req.BasePrice - req.DiscountPrice) / req.BasePrice) * 100
	}

	availableStock := req.TotalStock
	if req.HasVariants {
		availableStock = 0
		for _, v := range req.Variants {
			availableStock += v.Stock
		}
	}

	tx := h.db.Begin()

	product := models.Product{
		VendorID:         vendor.ID,
		CategoryID:       req.CategoryID,
		SubCategoryID:    req.SubCategoryID,
		Name:             req.Name,
		Slug:             utils.GenerateSlug(req.Name),
		Description:      req.Description,
		ShortDescription: req.ShortDescription,
		Brand:            req.Brand,
		BasePrice:        req.BasePrice,
		DiscountPrice:    req.DiscountPrice,
		DiscountPercent:  math.Round(discountPercent*100) / 100,
		TaxPercent:       req.TaxPercent,
		TotalStock:       req.TotalStock,
		AvailableStock:   availableStock,
		ReservedStock:    0,
		LowStockThreshold: req.LowStockThreshold,
		HasVariants:      req.HasVariants,
		IsActive:         false,
		IsApproved:       false,
	}

	if err := tx.Create(&product).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to create product")
		return
	}

	// Create images
	for i, img := range req.Images {
		pimg := models.ProductImage{
			ProductID: product.ID,
			ImageURL:  img.ImageURL,
			AltText:   img.AltText,
			IsPrimary: img.IsPrimary || i == 0,
			SortOrder: i,
		}
		tx.Create(&pimg)
	}

	// Create variants
	if req.HasVariants {
		for _, v := range req.Variants {
			sku := v.SKU
			if sku == "" {
				sku = generateSKU(vendor.ID, product.ID)
			}
			variant := models.ProductVariant{
				ProductID:     product.ID,
				SKU:           sku,
				Name:          v.Name,
				Value:         v.Value,
				Price:         v.Price,
				DiscountPrice: v.DiscountPrice,
				Stock:         v.Stock,
			}
			tx.Create(&variant)
		}
	}

	// Add tags
	if len(req.Tags) > 0 {
		tagsJSON, _ := json.Marshal(req.Tags)
		json.Unmarshal(tagsJSON, &product.Tags)
		tx.Save(&product)
	}

	tx.Model(&models.Vendor{}).Where("id = ?", vendor.ID).Update("total_products", gorm.Expr("total_products + 1"))

	tx.Commit()

	h.db.Preload("Images").Preload("Variants").First(&product, product.ID)
	utils.CreatedResponse(c, product)
}

func (h *ProductHandler) Update(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var vendor models.Vendor
	h.db.Where("user_id = ?", userID).First(&vendor)

	var product models.Product
	if err := h.db.Where("id = ? AND vendor_id = ?", productID, vendor.ID).First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found or unauthorized")
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	allowed := []string{"name", "description", "short_description", "brand", "base_price",
		"discount_price", "tax_percent", "total_stock", "available_stock", "low_stock_threshold",
		"is_active", "category_id", "sub_category_id", "tags", "attributes"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	// Recalculate discount percent if prices changed
	if base, ok := filtered["base_price"]; ok {
		if disc, ok := filtered["discount_price"]; ok {
			b := base.(float64)
			d := disc.(float64)
			if d > 0 && d < b {
				filtered["discount_percent"] = math.Round(((b-d)/b)*100*100) / 100
			}
		}
	}

	h.db.Model(&product).Updates(filtered)
	h.db.Preload("Images").Preload("Variants").First(&product, product.ID)
	utils.SuccessResponse(c, product)
}

func (h *ProductHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var product models.Product
	if err := h.db.Preload("Images").Preload("Variants").Preload("Category").Preload("Vendor").First(&product, id).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found")
		return
	}

	utils.SuccessResponse(c, product)
}

func (h *ProductHandler) Delete(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var vendor models.Vendor
	h.db.Where("user_id = ?", userID).First(&vendor)

	result := h.db.Where("id = ? AND vendor_id = ?", productID, vendor.ID).Delete(&models.Product{})
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Product not found or unauthorized")
		return
	}

	h.db.Model(&models.Vendor{}).Where("id = ?", vendor.ID).Update("total_products", gorm.Expr("GREATEST(total_products - 1, 0)"))
	utils.SuccessResponse(c, gin.H{"message": "Product deleted"})
}

func (h *ProductHandler) List(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var products []models.Product
	var total int64

	query := h.db.Model(&models.Product{}).Where("is_active = ? AND is_approved = ?", true, true)

	if catID := c.Query("category_id"); catID != "" {
		query = query.Where("category_id = ?", catID)
	}
	if vendorID := c.Query("vendor_id"); vendorID != "" {
		query = query.Where("vendor_id = ?", vendorID)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("name ILIKE ? OR brand ILIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if minPrice := c.Query("min_price"); minPrice != "" {
		query = query.Where("(discount_price > 0 AND discount_price >= ?) OR (discount_price = 0 AND base_price >= ?)", minPrice, minPrice)
	}
	if maxPrice := c.Query("max_price"); maxPrice != "" {
		query = query.Where("(discount_price > 0 AND discount_price <= ?) OR (discount_price = 0 AND base_price <= ?)", maxPrice, maxPrice)
	}
	if isFeatured := c.Query("is_featured"); isFeatured == "true" {
		query = query.Where("is_featured = ?", true)
	}
	if rating := c.Query("min_rating"); rating != "" {
		query = query.Where("rating >= ?", rating)
	}

	sortBy := c.DefaultQuery("sort_by", "created_at")
	sortOrder := c.DefaultQuery("sort_order", "desc")
	orderClause := sortBy + " " + sortOrder

	query.Count(&total)
	query.Preload("Images").Preload("Variants").Preload("Category").
		Offset((page-1)*pageSize).Limit(pageSize).Order(orderClause).Find(&products)

	utils.PaginatedResponse(c, products, page, pageSize, total)
}

func (h *ProductHandler) ListByVendor(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.NotFoundResponse(c, "Vendor profile not found")
		return
	}

	page, pageSize := utils.GetPageParams(c)

	var products []models.Product
	var total int64

	query := h.db.Model(&models.Product{}).Where("vendor_id = ?", vendor.ID)
	if status := c.Query("status"); status == "active" {
		query = query.Where("is_active = ?", true)
	} else if status == "inactive" {
		query = query.Where("is_active = ?", false)
	}

	query.Count(&total)
	query.Preload("Images").Preload("Variants").
		Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&products)

	utils.PaginatedResponse(c, products, page, pageSize, total)
}

func (h *ProductHandler) AddReview(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var req struct {
		Rating int    `json:"rating" binding:"required,min=1,max=5"`
		Title  string `json:"title"`
		Review string `json:"review"`
		Images []string `json:"images"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	// Check if user purchased this product
	var orderItem models.OrderItem
	if err := h.db.Joins("JOIN orders ON orders.id = order_items.order_id").
		Where("order_items.product_id = ? AND orders.customer_id = ? AND orders.status = ?",
			productID, userID, models.OrderStatusDelivered).First(&orderItem).Error; err != nil {
		utils.BadRequestResponse(c, "You can only review products you've purchased")
		return
	}

	review := models.ProductReview{
		ProductID: productID,
		UserID:    userID,
		OrderID:   &orderItem.OrderID,
		Rating:    req.Rating,
		Title:     req.Title,
		Review:    req.Review,
		IsVerified: true,
	}
	if len(req.Images) > 0 {
		imgBytes, _ := json.Marshal(req.Images)
		json.Unmarshal(imgBytes, &review.Images)
	}

	if err := h.db.Create(&review).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to add review")
		return
	}

	// Update product rating
	var avgRating struct{ Avg float64; Count int }
	h.db.Model(&models.ProductReview{}).
		Select("AVG(rating) as avg, COUNT(*) as count").
		Where("product_id = ? AND is_active = ?", productID, true).
		Scan(&avgRating)
	h.db.Model(&models.Product{}).Where("id = ?", productID).Updates(map[string]interface{}{
		"rating":       math.Round(avgRating.Avg*10) / 10,
		"review_count": avgRating.Count,
	})

	utils.CreatedResponse(c, review)
}

func (h *ProductHandler) ListReviews(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var reviews []models.ProductReview
	h.db.Where("product_id = ? AND is_active = ?", productID, true).
		Preload("User").
		Order("created_at DESC").Find(&reviews)

	utils.SuccessResponse(c, reviews)
}

func (h *ProductHandler) ListCategories(c *gin.Context) {
	categoryType := c.DefaultQuery("type", string(models.CategoryTypeProduct))

	if categoryType == string(models.CategoryTypeBarber) {
		var result []models.Category
		h.db.Where("category_type = ? AND is_active = ?", models.CategoryTypeBarber, true).
			Order("sort_order ASC").Find(&result)
		utils.SuccessResponse(c, result)
		return
	}

	var categories []models.Category
	query := h.db.Where("category_type = ? AND is_active = ?", models.CategoryTypeProduct, true).Order("sort_order ASC")
	if parentID := c.Query("parent_id"); parentID != "" {
		query = query.Where("parent_id = ?", parentID)
	}
	query.Find(&categories)
	utils.SuccessResponse(c, categories)
}

func (h *ProductHandler) ListFeatured(c *gin.Context) {
	var products []models.Product
	h.db.Where("is_active = ? AND is_approved = ? AND is_featured = ?", true, true, true).
		Preload("Images").Preload("Category").Preload("Vendor").
		Order("sold_count DESC").Limit(20).Find(&products)

	utils.SuccessResponse(c, products)
}

func generateSKU(vendorID, productID uuid.UUID) string {
	return vendorID.String()[:8] + "-" + productID.String()[:8]
}
