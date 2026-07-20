package product

import (
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// maxProductImages defines the upload limit per product
const maxProductImages = 10

// maxImageBytes defines the maximum raw file size accepted (8 MB)
const maxImageBytes = 8 * 1024 * 1024

var allowedProductMIMEs = map[string]string{
	"image/jpeg": ".jpg",
	"image/png":  ".png",
	"image/webp": ".webp",
}

// UploadProductImage handles multipart upload and persists ProductImage records.
// POST /vendor/products/:id/images
func (h *ProductHandler) UploadProductImages(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	// Verify ownership
	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.ForbiddenResponse(c, "Vendor profile not found")
		return
	}
	var product models.Product
	if err := h.db.Where("id = ? AND vendor_id = ?", productID, vendor.ID).First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found or unauthorized")
		return
	}

	// Count existing images
	var existingCount int64
	h.db.Model(&models.ProductImage{}).Where("product_id = ?", productID).Count(&existingCount)

	form, err := c.MultipartForm()
	if err != nil {
		utils.BadRequestResponse(c, "Invalid multipart form: "+err.Error())
		return
	}
	files := form.File["images"]
	if len(files) == 0 {
		utils.BadRequestResponse(c, "No images provided")
		return
	}
	if int(existingCount)+len(files) > maxProductImages {
		utils.BadRequestResponse(c, fmt.Sprintf("Cannot exceed %d images per product (currently have %d)", maxProductImages, existingCount))
		return
	}

	uploadDir := filepath.Join("uploads", "products", productID.String())
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		utils.InternalErrorResponse(c, "Failed to prepare upload directory")
		return
	}

	baseURL := c.MustGet("base_url").(string)
	uploaded := make([]models.ProductImage, 0, len(files))

	tx := h.db.Begin()
	for i, fh := range files {
		// Size check
		if fh.Size > maxImageBytes {
			tx.Rollback()
			utils.BadRequestResponse(c, fmt.Sprintf("Image '%s' exceeds 8 MB limit", fh.Filename))
			return
		}

		src, err := fh.Open()
		if err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to open image")
			return
		}

		// MIME detection
		buf := make([]byte, 512)
		src.Read(buf)
		src.Seek(0, io.SeekStart)
		mimeType := http.DetectContentType(buf)

		ext, ok := allowedProductMIMEs[mimeType]
		if !ok {
			// Fallback: accept by extension for webp which DetectContentType may misidentify
			origExt := strings.ToLower(filepath.Ext(fh.Filename))
			if origExt == ".webp" {
				ext = ".webp"
				mimeType = "image/webp"
			} else {
				src.Close()
				tx.Rollback()
				utils.BadRequestResponse(c, fmt.Sprintf("Image '%s': unsupported type '%s'. Use JPG, PNG or WebP.", fh.Filename, mimeType))
				return
			}
		}

		// Save original
		fileName := fmt.Sprintf("%s_%s%s", time.Now().Format("20060102150405"), uuid.New().String()[:8], ext)
		origPath := filepath.Join(uploadDir, fileName)
		dst, err := os.Create(origPath)
		if err != nil {
			src.Close()
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to save image")
			return
		}
		written, err := io.Copy(dst, src)
		dst.Close()
		src.Close()
		if err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to write image")
			return
		}

		// Generate thumbnail (simple resize by re-saving at smaller dimensions)
		thumbURL := ""
		thumbFileName := "thumb_" + fileName
		thumbPath := filepath.Join(uploadDir, thumbFileName)
		if genErr := generateThumbnail(origPath, thumbPath); genErr == nil {
			thumbURL = baseURL + "/" + filepath.ToSlash(thumbPath)
		}

		// Determine sort order
		sortOrder := int(existingCount) + i

		// First image becomes primary if none exist
		isPrimary := existingCount == 0 && i == 0

		img := models.ProductImage{
			ProductID:    productID,
			ImageURL:     baseURL + "/" + filepath.ToSlash(origPath),
			ThumbnailURL: thumbURL,
			IsPrimary:    isPrimary,
			SortOrder:    sortOrder,
			FileSize:     written,
			MimeType:     mimeType,
		}
		if err := tx.Create(&img).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to save image record")
			return
		}
		uploaded = append(uploaded, img)
	}
	tx.Commit()

	utils.CreatedResponse(c, gin.H{"images": uploaded, "count": len(uploaded)})
}

// ListProductImages returns all images for a product.
// GET /vendor/products/:id/images
func (h *ProductHandler) ListProductImages(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var images []models.ProductImage
	h.db.Where("product_id = ?", productID).Order("sort_order ASC, created_at ASC").Find(&images)
	utils.SuccessResponse(c, images)
}

// DeleteProductImage removes a product image by imageId.
// DELETE /vendor/products/images/:imageId
func (h *ProductHandler) DeleteProductImage(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	imageID, err := uuid.Parse(c.Param("imageId"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid image ID")
		return
	}

	// Verify vendor owns the product this image belongs to
	var img models.ProductImage
	if err := h.db.First(&img, imageID).Error; err != nil {
		utils.NotFoundResponse(c, "Image not found")
		return
	}
	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.ForbiddenResponse(c, "Vendor profile not found")
		return
	}
	var product models.Product
	if err := h.db.Where("id = ? AND vendor_id = ?", img.ProductID, vendor.ID).First(&product).Error; err != nil {
		utils.ForbiddenResponse(c, "Unauthorized")
		return
	}

	// Try to remove physical files (best-effort)
	tryDeleteFile(img.ImageURL)
	tryDeleteFile(img.ThumbnailURL)

	h.db.Delete(&img)

	// If we deleted the primary, promote next
	if img.IsPrimary {
		var next models.ProductImage
		if h.db.Where("product_id = ?", img.ProductID).Order("sort_order ASC").First(&next).Error == nil {
			h.db.Model(&next).Update("is_primary", true)
		}
	}

	utils.SuccessResponse(c, gin.H{"message": "Image deleted"})
}

// ReorderProductImages updates sort_order for a product's images.
// PUT /vendor/products/:id/images/reorder
func (h *ProductHandler) ReorderProductImages(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.ForbiddenResponse(c, "Vendor profile not found")
		return
	}
	var product models.Product
	if err := h.db.Where("id = ? AND vendor_id = ?", productID, vendor.ID).First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found or unauthorized")
		return
	}

	var req struct {
		ImageIDs []string `json:"image_ids" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	tx := h.db.Begin()
	for i, idStr := range req.ImageIDs {
		imgID, err := uuid.Parse(idStr)
		if err != nil {
			tx.Rollback()
			utils.BadRequestResponse(c, "Invalid image ID: "+idStr)
			return
		}
		if err := tx.Model(&models.ProductImage{}).
			Where("id = ? AND product_id = ?", imgID, productID).
			Update("sort_order", i).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to reorder images")
			return
		}
	}
	tx.Commit()
	utils.SuccessResponse(c, gin.H{"message": "Images reordered"})
}

// SetPrimaryProductImage marks a specific image as the primary one.
// PUT /vendor/products/:id/images/:imageId/primary
func (h *ProductHandler) SetPrimaryProductImage(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}
	imageID, err := uuid.Parse(c.Param("imageId"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid image ID")
		return
	}

	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.ForbiddenResponse(c, "Vendor profile not found")
		return
	}
	var product models.Product
	if err := h.db.Where("id = ? AND vendor_id = ?", productID, vendor.ID).First(&product).Error; err != nil {
		utils.NotFoundResponse(c, "Product not found or unauthorized")
		return
	}

	tx := h.db.Begin()
	// Unset all primaries
	tx.Model(&models.ProductImage{}).Where("product_id = ?", productID).Update("is_primary", false)
	// Set the chosen one
	result := tx.Model(&models.ProductImage{}).Where("id = ? AND product_id = ?", imageID, productID).Update("is_primary", true)
	if result.RowsAffected == 0 {
		tx.Rollback()
		utils.NotFoundResponse(c, "Image not found in this product")
		return
	}
	tx.Commit()
	utils.SuccessResponse(c, gin.H{"message": "Primary image set"})
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

func generateThumbnail(srcPath, dstPath string) error {
	f, err := os.Open(srcPath)
	if err != nil {
		return err
	}
	defer f.Close()

	cfg, _, err := image.DecodeConfig(f)
	if err != nil {
		return err
	}
	// Only generate a thumbnail if the image is larger than 400x400
	if cfg.Width <= 400 && cfg.Height <= 400 {
		return fmt.Errorf("image is small enough, no thumbnail needed")
	}

	// For now: copy as-is. In production, plug in golang.org/x/image/draw or
	// disintegration/imaging for actual resize. The URL is still stored so
	// swapping the implementation later is seamless.
	src2, err := os.Open(srcPath)
	if err != nil {
		return err
	}
	defer src2.Close()

	dst, err := os.Create(dstPath)
	if err != nil {
		return err
	}
	defer dst.Close()
	_, err = io.Copy(dst, src2)
	return err
}

func tryDeleteFile(rawURL string) {
	if rawURL == "" {
		return
	}
	// Best-effort file removal. Failures are silently ignored.
	_ = os.Remove(rawURL)
}
