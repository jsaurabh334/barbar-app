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
	BrandID          *uuid.UUID               `json:"brand_id"`
	Name             string                   `json:"name" binding:"required,min=2,max=255"`
	Description      string                   `json:"description"`
	ShortDescription string                   `json:"short_description"`
	BrandName        string                   `json:"brand_name"`
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
	Barcode      string  `json:"barcode"`
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
		VendorID:          vendor.ID,
		BrandID:           req.BrandID,
		CategoryID:        req.CategoryID,
		SubCategoryID:     req.SubCategoryID,
		Name:              req.Name,
		Slug:              utils.GenerateSlug(req.Name),
		Description:       req.Description,
		ShortDescription:  req.ShortDescription,
		BrandName:         req.BrandName,
		BasePrice:         req.BasePrice,
		DiscountPrice:     req.DiscountPrice,
		DiscountPercent:   math.Round(discountPercent*100) / 100,
		TaxPercent:        req.TaxPercent,
		TotalStock:        req.TotalStock,
		AvailableStock:    availableStock,
		ReservedStock:     0,
		LowStockThreshold: req.LowStockThreshold,
		HasVariants:       req.HasVariants,
	}

	if req.Tags != nil {
		tagJSON, _ := json.Marshal(req.Tags)
		product.Tags = tagJSON
	}

	if err := tx.Create(&product).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to create product")
		return
	}

	// Process variants
	for _, v := range req.Variants {
		variant := models.ProductVariant{
			ProductID:     product.ID,
			Name:          v.Name,
			Value:         v.Value,
			Price:         v.Price,
			DiscountPrice: v.DiscountPrice,
			Stock:         v.Stock,
			SKU:           v.SKU,
			Barcode:       v.Barcode,
		}
		if err := tx.Create(&variant).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to create variant")
			return
		}
	}

	tx.Commit()

	h.db.Preload("Images").Preload("Variants").First(&product, product.ID)
	utils.CreatedResponse(c, product)
}

// ==================== Variant CRUD ====================

type VariantInput struct {
	Name         string  `json:"name" binding:"required"`
	Value        string  `json:"value" binding:"required"`
	Price        float64 `json:"price" binding:"required"`
	DiscountPrice float64 `json:"discount_price"`
	Stock        int     `json:"stock" binding:"required"`
	SKU          string  `json:"sku"`
	Barcode      string  `json:"barcode"`
	Weight       float64 `json:"weight"`
	Image        string  `json:"image"`
	IsActive     bool    `json:"is_active"`
}

func (h *ProductHandler) CreateVariant(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var product models.Product
	if err := h.db.First(&product, productID).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found")
		return
	}

	var req VariantInput
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	variant := models.ProductVariant{
		ProductID:     productID,
		Name:          req.Name,
		Value:         req.Value,
		Price:         req.Price,
		DiscountPrice: req.DiscountPrice,
		Stock:         req.Stock,
		SKU:           req.SKU,
		Barcode:       req.Barcode,
		Weight:        req.Weight,
		Image:         req.Image,
		IsActive:      req.IsActive,
	}

	if err := h.db.Create(&variant).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create variant")
		return
	}

	utils.CreatedResponse(c, variant)
}

func (h *ProductHandler) ListVariants(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var variants []models.ProductVariant
	h.db.Where("product_id = ?", productID).Order("sort_order ASC").Find(&variants)
	utils.SuccessResponse(c, variants)
}

func (h *ProductHandler) UpdateVariant(c *gin.Context) {
	variantID, err := uuid.Parse(c.Param("variantId"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid variant ID")
		return
	}

	var variant models.ProductVariant
	if err := h.db.First(&variant, variantID).Error; err != nil {
		utils.NotFoundResponse(c, "Variant not found")
		return
	}

	var req VariantInput
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	updates := map[string]interface{}{
		"name":          req.Name,
		"value":         req.Value,
		"price":         req.Price,
		"discount_price": req.DiscountPrice,
		"stock":         req.Stock,
		"sku":           req.SKU,
		"barcode":       req.Barcode,
		"weight":        req.Weight,
		"image":         req.Image,
		"is_active":     req.IsActive,
	}

	if err := h.db.Model(&variant).Updates(updates).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update variant")
		return
	}

	h.db.First(&variant, variant.ID)
	utils.SuccessResponse(c, variant)
}

func (h *ProductHandler) DeleteVariant(c *gin.Context) {
	variantID, err := uuid.Parse(c.Param("variantId"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid variant ID")
		return
	}

	result := h.db.Delete(&models.ProductVariant{}, variantID)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Variant not found")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Variant deleted"})
}

// ==================== Existing handlers (kept as-is) ====================

func (h *ProductHandler) Update(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	userID := c.MustGet("user").(uuid.UUID)

	var product models.Product
	if err := h.db.Where("id = ?", productID).Preload("Vendor").First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found")
		return
	}

	if product.Vendor.UserID != userID {
		utils.ForbiddenResponse(c, "You don't own this product")
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	allowed := []string{"name", "description", "short_description", "brand_id", "brand_name",
		"category_id", "sub_category_id", "base_price", "discount_price",
		"tax_percent", "total_stock", "low_stock_threshold",
		"has_variants", "is_active", "tags", "attributes",
		"weight", "length", "width", "height", "unit",
		"min_order_qty", "max_order_qty", "condition"}

	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			if key == "tags" || key == "attributes" {
				if bytes, err := json.Marshal(val); err == nil {
					filtered[key] = string(bytes)
				}
			} else {
				filtered[key] = val
			}
		}
	}

	if err := h.db.Model(&product).Updates(filtered).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update product")
		return
	}

	h.db.Preload("Images").Preload("Variants").First(&product, product.ID)
	utils.SuccessResponse(c, product)
}

func (h *ProductHandler) Delete(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	userID := c.MustGet("user").(uuid.UUID)

	var product models.Product
	if err := h.db.Where("id = ?", productID).Preload("Vendor").First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found")
		return
	}

	if product.Vendor.UserID != userID {
		utils.ForbiddenResponse(c, "You don't own this product")
		return
	}

	if err := h.db.Delete(&product).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to delete product")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Product deleted"})
}

func (h *ProductHandler) ListByVendor(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.NotFoundResponse(c, "Vendor not found")
		return
	}

	var products []models.Product
	query := h.db.Where("vendor_id = ?", vendor.ID)

	if status := c.Query("status"); status == "active" {
		query = query.Where("is_active = ?", true)
	} else if status == "inactive" {
		query = query.Where("is_active = ?", false)
	}

	if approved := c.Query("approved"); approved == "true" {
		query = query.Where("is_approved = ?", true)
	} else if approved == "false" {
		query = query.Where("is_approved = ?", false)
	}

	query.Preload("Images").Preload("Variants").Order("created_at DESC").Find(&products)
	utils.SuccessResponse(c, products)
}

func (h *ProductHandler) AddReview(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		Rating int    `json:"rating" binding:"required,min=1,max=5"`
		Title  string `json:"title"`
		Review string `json:"review"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	review := models.ProductReview{
		ProductID: productID,
		UserID:    userID,
		Rating:    req.Rating,
		Title:     req.Title,
		Review:    req.Review,
		IsActive:  true,
	}

	if err := h.db.Create(&review).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to add review")
		return
	}

	var stats struct {
		AvgRating float64
		Count     int
	}
	h.db.Model(&models.ProductReview{}).
		Select("COALESCE(AVG(rating), 0) as avg_rating, COUNT(*) as count").
		Where("product_id = ? AND is_active = ?", productID, true).
		Scan(&stats)

	h.db.Model(&models.Product{}).Where("id = ?", productID).
		Updates(map[string]interface{}{
			"rating":       math.Round(stats.AvgRating*10) / 10,
			"review_count": stats.Count,
		})

	utils.CreatedResponse(c, review)
}

// ==================== Public endpoints ====================

func (h *ProductHandler) List(c *gin.Context) {
	var products []models.Product
	query := h.db.Where("is_active = ? AND is_approved = ?", true, true)

	if vendorID := c.Query("vendor_id"); vendorID != "" {
		query = query.Where("vendor_id = ?", vendorID)
	}
	if categoryID := c.Query("category_id"); categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}
	if subCategoryID := c.Query("sub_category_id"); subCategoryID != "" {
		query = query.Where("sub_category_id = ?", subCategoryID)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("name ILIKE ? OR description ILIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if minPrice := c.Query("min_price"); minPrice != "" {
		query = query.Where("base_price >= ?", minPrice)
	}
	if maxPrice := c.Query("max_price"); maxPrice != "" {
		query = query.Where("base_price <= ?", maxPrice)
	}

	sortBy := c.DefaultQuery("sort_by", "created_at")
	sortOrder := c.DefaultQuery("sort_order", "desc")
	query = query.Order(sortBy + " " + sortOrder)

	query.Preload("Images").Preload("Variants").Find(&products)
	utils.SuccessResponse(c, products)
}

func (h *ProductHandler) ListFeatured(c *gin.Context) {
	var products []models.Product
	h.db.Where("is_active = ? AND is_approved = ? AND is_featured = ?", true, true, true).
		Preload("Images").Preload("Variants").Order("created_at DESC").Limit(20).Find(&products)
	utils.SuccessResponse(c, products)
}

func (h *ProductHandler) Get(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var product models.Product
	if err := h.db.Where("id = ? AND is_active = ? AND is_approved = ?", productID, true, true).
		Preload("Images").Preload("Variants").First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found")
		return
	}

	utils.SuccessResponse(c, product)
}

func (h *ProductHandler) ListReviews(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var reviews []models.ProductReview
	h.db.Where("product_id = ? AND is_active = ?", productID, true).Order("created_at DESC").Find(&reviews)
	utils.SuccessResponse(c, reviews)
}

func (h *ProductHandler) ListCategories(c *gin.Context) {
	parentID := c.Query("parent_id")

	var categories []models.Category
	query := h.db.Where("is_active = ?", true)
	if parentID == "" {
		query = query.Where("parent_id IS NULL")
	} else {
		query = query.Where("parent_id = ?", parentID)
	}
	query.Order("sort_order ASC, name ASC").Find(&categories)
	utils.SuccessResponse(c, categories)
}
