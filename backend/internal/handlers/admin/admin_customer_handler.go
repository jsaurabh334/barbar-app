package admin

import (
	"strconv"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// AdminCustomerHandler handles admin endpoints for managing customers
type AdminCustomerHandler struct {
	db *gorm.DB
}

func NewAdminCustomerHandler(db *gorm.DB) *AdminCustomerHandler {
	return &AdminCustomerHandler{db: db}
}

// ListCustomers handles GET /admin/customers
func (h *AdminCustomerHandler) ListCustomers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	search := c.Query("search")
	status := c.Query("status") // active, blocked, deleted

	var users []models.User
	var total int64

	query := h.db.Model(&models.User{}).Where("role = ?", models.RoleCustomer)

	if search != "" {
		searchQuery := "%" + search + "%"
		query = query.Where(
			"name ILIKE ? OR email ILIKE ? OR phone ILIKE ? OR id::text ILIKE ?",
			searchQuery, searchQuery, searchQuery, searchQuery,
		)
	}

	if status != "" {
		if status == "deleted" {
			query = query.Unscoped().Where("deleted_at IS NOT NULL")
		} else {
			query = query.Where("status = ?", status)
		}
	} else {
		// By default exclude soft-deleted
		query = query.Where("deleted_at IS NULL")
	}

	query.Count(&total)

	offset := (page - 1) * limit
	if err := query.Order("created_at DESC").Offset(offset).Limit(limit).Find(&users).Error; err != nil {
		utils.ErrorResponse(c, 500, "Failed to fetch customers")
		return
	}

	utils.SuccessResponse(c, map[string]interface{}{
		"data":  users,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

// GetCustomerDetails handles GET /admin/customers/:id
func (h *AdminCustomerHandler) GetCustomerDetails(c *gin.Context) {
	customerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid customer ID")
		return
	}

	var customer models.User
	if err := h.db.Unscoped().Where("id = ? AND role = ?", customerID, models.RoleCustomer).First(&customer).Error; err != nil {
		utils.ErrorResponse(c, 404, "Customer not found")
		return
	}

	// Fetch Wallet
	var wallet models.Wallet
	if err := h.db.Where("user_id = ?", customerID).First(&wallet).Error; err != nil && err != gorm.ErrRecordNotFound {
		// Ignore not found, wallet may be empty
	}

	var transactions []models.WalletTransaction
	if wallet.ID != uuid.Nil {
		h.db.Where("wallet_id = ?", wallet.ID).Order("created_at DESC").Limit(10).Find(&transactions)
	}

	// Fetch Bookings
	var bookings []models.Booking
	h.db.Preload("Barber").Where("user_id = ?", customerID).Order("created_at DESC").Limit(10).Find(&bookings)

	// Fetch Reviews (mock for now if no model exists)
	var reviews []interface{}

	// Calculate Stats
	var totalBookings, completed, cancelled int64
	var spent float64

	h.db.Model(&models.Booking{}).Where("user_id = ?", customerID).Count(&totalBookings)
	h.db.Model(&models.Booking{}).Where("user_id = ? AND status = ?", customerID, models.BookingStatusCompleted).Count(&completed)
	h.db.Model(&models.Booking{}).Where("user_id = ? AND status = ?", customerID, models.BookingStatusCancelled).Count(&cancelled)
	
	// Assuming bookings have price or final_amount, using raw query to sum
	h.db.Model(&models.Booking{}).Where("user_id = ? AND status = ?", customerID, models.BookingStatusCompleted).Select("COALESCE(SUM(total_amount), 0)").Scan(&spent)

	stats := map[string]interface{}{
		"total_bookings": totalBookings,
		"completed":      completed,
		"cancelled":      cancelled,
		"spent":          spent,
		"rating":         0.0, // Future: avg rating given by customer
	}

	response := map[string]interface{}{
		"customer": customer,
		"wallet": map[string]interface{}{
			"balance":      wallet.Balance,
			"transactions": transactions,
		},
		"bookings": bookings,
		"reviews":  reviews,
		"stats":    stats,
	}

	utils.SuccessResponse(c, response)
}

// BlockCustomer handles PUT /admin/customers/:id/block
func (h *AdminCustomerHandler) BlockCustomer(c *gin.Context) {
	customerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid customer ID")
		return
	}
	if err := h.db.Model(&models.User{}).Where("id = ? AND role = ?", customerID, models.RoleCustomer).Update("status", "blocked").Error; err != nil {
		utils.ErrorResponse(c, 500, "Failed to block customer")
		return
	}
	utils.SuccessResponse(c, map[string]string{"message": "Customer blocked successfully"})
}

// UnblockCustomer handles PUT /admin/customers/:id/unblock
func (h *AdminCustomerHandler) UnblockCustomer(c *gin.Context) {
	customerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid customer ID")
		return
	}
	if err := h.db.Model(&models.User{}).Where("id = ? AND role = ?", customerID, models.RoleCustomer).Update("status", "active").Error; err != nil {
		utils.ErrorResponse(c, 500, "Failed to unblock customer")
		return
	}
	utils.SuccessResponse(c, map[string]string{"message": "Customer unblocked successfully"})
}

// DeleteCustomer handles PUT /admin/customers/:id/delete (Soft Delete)
func (h *AdminCustomerHandler) DeleteCustomer(c *gin.Context) {
	customerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid customer ID")
		return
	}
	// Using gorm's Delete method on a model with DeletedAt will automatically do a soft delete.
	if err := h.db.Where("id = ? AND role = ?", customerID, models.RoleCustomer).Delete(&models.User{}).Error; err != nil {
		utils.ErrorResponse(c, 500, "Failed to delete customer")
		return
	}
	utils.SuccessResponse(c, map[string]string{"message": "Customer deleted successfully"})
}
