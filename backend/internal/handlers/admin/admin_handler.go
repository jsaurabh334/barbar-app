package admin

import (
	"encoding/json"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminHandler struct {
	db *gorm.DB
}

func NewAdminHandler(db *gorm.DB) *AdminHandler {
	return &AdminHandler{db: db}
}

// ================ Dashboard ================
func (h *AdminHandler) GetDashboard(c *gin.Context) {
	var stats struct {
		TotalUsers      int64 `json:"total_users"`
		TotalBarbers    int64 `json:"total_barbers"`
		TotalVendors    int64 `json:"total_vendors"`
		TotalCustomers  int64 `json:"total_customers"`
		TotalBookings   int64 `json:"total_bookings"`
		TotalOrders     int64 `json:"total_orders"`
		TotalProducts   int64 `json:"total_products"`
		TotalRevenue    float64 `json:"total_revenue"`
		PendingVendors  int64 `json:"pending_vendors"`
		PendingBarbers  int64 `json:"pending_barbers"`
		PendingRefunds  int64 `json:"pending_refunds"`
		PendingWithdrawals int64 `json:"pending_withdrawals"`
		TodayBookings   int64 `json:"today_bookings"`
		TodayRevenue    float64 `json:"today_revenue"`
		ActiveUsers     int64 `json:"active_users"`
	}

	today := time.Now().Truncate(24 * time.Hour)

	h.db.Model(&models.User{}).Count(&stats.TotalUsers)
	h.db.Model(&models.User{}).Where("role = ?", models.RoleBarber).Count(&stats.TotalBarbers)
	h.db.Model(&models.User{}).Where("role = ?", models.RoleVendor).Count(&stats.TotalVendors)
	h.db.Model(&models.User{}).Where("role = ?", models.RoleCustomer).Count(&stats.TotalCustomers)
	h.db.Model(&models.Booking{}).Count(&stats.TotalBookings)
	h.db.Model(&models.Order{}).Count(&stats.TotalOrders)
	h.db.Model(&models.Product{}).Count(&stats.TotalProducts)
	h.db.Model(&models.Order{}).Where("status = ?", models.OrderStatusDelivered).Select("COALESCE(SUM(final_amount), 0)").Scan(&stats.TotalRevenue)
	h.db.Model(&models.Vendor{}).Where("status = ?", models.VendorStatusPending).Count(&stats.PendingVendors)
	h.db.Model(&models.Barber{}).Where("verification_status = ?", models.BarberVerifPending).Count(&stats.PendingBarbers)
	h.db.Model(&models.RefundRequest{}).Where("status = ?", "pending").Count(&stats.PendingRefunds)
	h.db.Model(&models.WithdrawalRequest{}).Where("status = ?", models.WithdrawPending).Count(&stats.PendingWithdrawals)
	h.db.Model(&models.Booking{}).Where("created_at >= ?", today).Count(&stats.TodayBookings)
	h.db.Model(&models.Order{}).Where("created_at >= ? AND status = ?", today, models.OrderStatusDelivered).Select("COALESCE(SUM(final_amount), 0)").Scan(&stats.TodayRevenue)
	h.db.Model(&models.User{}).Where("last_active_at >= ?", time.Now().Add(-24*time.Hour)).Count(&stats.ActiveUsers)

	utils.SuccessResponse(c, stats)
}

func (h *AdminHandler) GetRevenueAnalytics(c *gin.Context) {
	period := c.DefaultQuery("period", "month")

	now := time.Now()
	var since time.Time
	switch period {
	case "week":
		since = now.AddDate(0, 0, -7)
	case "month":
		since = now.AddDate(0, -1, 0)
	case "year":
		since = now.AddDate(-1, 0, 0)
	default:
		since = now.AddDate(0, -1, 0)
	}

	type RevenueRecord struct {
		Date          string  `json:"date"`
		BookingRevenue float64 `json:"booking_revenue"`
		OrderRevenue  float64 `json:"order_revenue"`
		Commission    float64 `json:"commission"`
		TotalRevenue  float64 `json:"total_revenue"`
	}

	var records []RevenueRecord

	h.db.Raw(`
		SELECT 
			DATE(dates) as date,
			COALESCE(SUM(CASE WHEN entity = 'booking' THEN amount END), 0) as booking_revenue,
			COALESCE(SUM(CASE WHEN entity = 'order' THEN amount END), 0) as order_revenue,
			COALESCE(SUM(CASE WHEN entity = 'commission' THEN amount END), 0) as commission,
			COALESCE(SUM(amount), 0) as total_revenue
		FROM (
			SELECT DATE(created_at) as dates, 'booking' as entity, final_price as amount FROM bookings WHERE status = 'completed' AND created_at >= ?
			UNION ALL
			SELECT DATE(created_at) as dates, 'order' as entity, final_amount as amount FROM orders WHERE status = 'delivered' AND created_at >= ?
			UNION ALL
			SELECT DATE(created_at) as dates, 'commission' as entity, commission_amount as amount FROM commission_transactions WHERE created_at >= ?
		) combined
		GROUP BY DATE(dates)
		ORDER BY date ASC
	`, since, since, since).Scan(&records)

	var totals struct {
		TotalRevenue  float64 `json:"total_revenue"`
		TotalCommission float64 `json:"total_commission"`
		TotalOrders   int64   `json:"total_orders"`
		TotalBookings int64   `json:"total_bookings"`
		AvgOrderValue float64 `json:"avg_order_value"`
	}

	h.db.Raw(`
		SELECT 
			COALESCE(SUM(final_amount), 0) as total_revenue,
			COALESCE(SUM(commission_amount), 0) as total_commission,
			COUNT(*) as total_orders,
			COALESCE(AVG(final_amount), 0) as avg_order_value
		FROM orders WHERE status IN ('delivered','refunded') AND created_at >= ?
	`, since).Scan(&totals)

	h.db.Model(&models.Booking{}).Where("status = ? AND created_at >= ?", models.BookingStatusCompleted, since).Count(&totals.TotalBookings)

	utils.SuccessResponse(c, gin.H{
		"period":  period,
		"records": records,
		"totals":  totals,
	})
}

// ================ Barber Management ================
func (h *AdminHandler) ListBarbers(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var barbers []models.Barber
	var total int64

	query := h.db.Model(&models.Barber{}).Preload("User")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if verification := c.Query("verification_status"); verification != "" {
		query = query.Where("verification_status = ?", verification)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("shop_name ILIKE ?", "%"+search+"%")
	}
	if city := c.Query("city"); city != "" {
		query = query.Where("LOWER(city) = LOWER(?)", city)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&barbers)

	utils.PaginatedResponse(c, barbers, page, pageSize, total)
}

func (h *AdminHandler) ApproveBarber(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid barber ID")
		return
	}

	var barber models.Barber
	if err := h.db.First(&barber, id).Error; err != nil {
		utils.NotFoundResponse(c, "Barber not found")
		return
	}

	var req struct {
		Status string `json:"status" binding:"required,oneof=approved rejected"`
		Remarks string `json:"remarks"`
	}
	c.ShouldBindJSON(&req)

	updates := map[string]interface{}{
		"verification_status": models.BarberVerificationStatus(req.Status),
	}
	if req.Status == "approved" {
		updates["is_verified"] = true
	}

	h.db.Model(&barber).Updates(updates)

	if req.Status == "approved" {
		h.db.Model(&models.User{}).Where("id = ?", barber.UserID).Update("role", models.RoleBarber)
	}

	utils.SuccessResponse(c, gin.H{"message": "Barber " + req.Status})
}

// ================ Vendor Management ================
func (h *AdminHandler) ListVendors(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var vendors []models.Vendor
	var total int64

	query := h.db.Model(&models.Vendor{}).Preload("User")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if kyc := c.Query("kyc_status"); kyc != "" {
		query = query.Where("kyc_status = ?", kyc)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("store_name ILIKE ?", "%"+search+"%")
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&vendors)

	utils.PaginatedResponse(c, vendors, page, pageSize, total)
}

func (h *AdminHandler) ApproveVendor(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid vendor ID")
		return
	}

	var vendor models.Vendor
	if err := h.db.First(&vendor, id).Error; err != nil {
		utils.NotFoundResponse(c, "Vendor not found")
		return
	}

	var req struct {
		Status          string  `json:"status" binding:"required,oneof=approved rejected suspended"`
		CommissionRate  float64 `json:"commission_rate"`
		Remarks         string  `json:"remarks"`
	}
	c.ShouldBindJSON(&req)

	updates := map[string]interface{}{
		"status": models.VendorStatus(req.Status),
	}
	if req.CommissionRate > 0 {
		updates["commission_rate"] = req.CommissionRate
	}

	h.db.Model(&vendor).Updates(updates)

	if req.Status == "approved" {
		h.db.Model(&models.User{}).Where("id = ?", vendor.UserID).Update("role", models.RoleVendor)
	}

	utils.SuccessResponse(c, gin.H{"message": "Vendor " + req.Status})
}

// ================ Product Moderation ================
func (h *AdminHandler) ListProducts(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var products []models.Product
	var total int64

	query := h.db.Model(&models.Product{}).Preload("Vendor").Preload("Category")
	if approved := c.Query("is_approved"); approved != "" {
		query = query.Where("is_approved = ?", approved == "true")
	}
	if active := c.Query("is_active"); active != "" {
		query = query.Where("is_active = ?", active == "true")
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("name ILIKE ?", "%"+search+"%")
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&products)

	utils.PaginatedResponse(c, products, page, pageSize, total)
}

func (h *AdminHandler) ApproveProduct(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid product ID")
		return
	}

	var req struct {
		IsApproved bool `json:"is_approved"`
		IsActive   bool `json:"is_active"`
	}
	c.ShouldBindJSON(&req)

	h.db.Model(&models.Product{}).Where("id = ?", id).Updates(map[string]interface{}{
		"is_approved": req.IsApproved,
		"is_active":   req.IsActive,
	})

	utils.SuccessResponse(c, gin.H{"message": "Product updated"})
}

// ================ Withdrawal Management ================
func (h *AdminHandler) ListWithdrawals(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var withdrawals []models.WithdrawalRequest
	var total int64

	query := h.db.Model(&models.WithdrawalRequest{}).Preload("Vendor")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&withdrawals)

	utils.PaginatedResponse(c, withdrawals, page, pageSize, total)
}

func (h *AdminHandler) ProcessWithdrawal(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid withdrawal ID")
		return
	}

	var req struct {
		Status    string `json:"status" binding:"required,oneof=approved rejected processed"`
		AdminNotes string `json:"admin_notes"`
		UTRNumber  string `json:"utr_number"`
	}
	c.ShouldBindJSON(&req)

	var withdrawal models.WithdrawalRequest
	if err := h.db.First(&withdrawal, id).Error; err != nil {
		utils.NotFoundResponse(c, "Withdrawal not found")
		return
	}

	updates := map[string]interface{}{
		"status":    models.WithdrawalRequestStatus(req.Status),
		"admin_id":  adminID,
		"admin_notes": req.AdminNotes,
	}

	if req.Status == "processed" {
		updates["processed_at"] = time.Now()
		updates["utr_number"] = req.UTRNumber

		// Release locked balance
		h.db.Model(&models.Wallet{}).Where("vendor_id = ?", withdrawal.VendorID).
			Update("locked_balance", gorm.Expr("locked_balance - ?", withdrawal.Amount))

		// Create payout record
		now := time.Now()
		h.db.Create(&models.VendorPayout{
			VendorID:     withdrawal.VendorID,
			WithdrawalID: withdrawal.ID,
			Amount:       withdrawal.Amount,
			FeeAmount:    withdrawal.FeeAmount,
			NetAmount:    withdrawal.NetAmount,
			Status:       "completed",
			UTRNumber:    req.UTRNumber,
			ProcessedAt:  &now,
		})
	} else if req.Status == "rejected" {
		// Release locked balance back to available
		h.db.Model(&models.Wallet{}).Where("vendor_id = ?", withdrawal.VendorID).Updates(map[string]interface{}{
			"balance":        gorm.Expr("balance + ?", withdrawal.Amount),
			"locked_balance": gorm.Expr("locked_balance - ?", withdrawal.Amount),
		})
	}

	h.db.Model(&withdrawal).Updates(updates)
	utils.SuccessResponse(c, gin.H{"message": "Withdrawal " + req.Status})
}

// ================ Refund Management ================
func (h *AdminHandler) ListRefunds(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var refunds []models.RefundRequest
	var total int64

	query := h.db.Model(&models.RefundRequest{}).Preload("Customer").Preload("Vendor")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&refunds)

	utils.PaginatedResponse(c, refunds, page, pageSize, total)
}

func (h *AdminHandler) ProcessRefund(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid refund ID")
		return
	}

	var req struct {
		Status   string  `json:"status" binding:"required,oneof=approved rejected processed"`
		Amount   float64 `json:"amount"`
		Notes    string  `json:"notes"`
	}
	c.ShouldBindJSON(&req)

	var refund models.RefundRequest
	if err := h.db.First(&refund, id).Error; err != nil {
		utils.NotFoundResponse(c, "Refund not found")
		return
	}

	updates := map[string]interface{}{
		"status":     req.Status,
		"admin_id":   adminID,
		"admin_notes": req.Notes,
	}

	if req.Status == "processed" {
		updates["processed_at"] = time.Now()
		updates["refund_amount"] = req.Amount
		// Process payment gateway refund
	}

	h.db.Model(&refund).Updates(updates)
	h.db.Model(&models.Order{}).Where("id = ?", refund.OrderID).Update("status", models.OrderStatusRefunded)

	utils.SuccessResponse(c, gin.H{"message": "Refund " + req.Status})
}

// ================ Dispute Management ================
func (h *AdminHandler) ListDisputes(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var disputes []models.Dispute
	var total int64

	query := h.db.Model(&models.Dispute{})
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if priority := c.Query("priority"); priority != "" {
		query = query.Where("priority = ?", priority)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&disputes)

	utils.PaginatedResponse(c, disputes, page, pageSize, total)
}

func (h *AdminHandler) ResolveDispute(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid dispute ID")
		return
	}

	var req struct {
		Status     string `json:"status" binding:"required,oneof=resolved closed escalated"`
		Resolution string `json:"resolution"`
	}
	c.ShouldBindJSON(&req)

	h.db.Model(&models.Dispute{}).Where("id = ?", id).Updates(map[string]interface{}{
		"status":     models.DisputeStatus(req.Status),
		"resolution": req.Resolution,
		"resolved_at": time.Now(),
	})

	utils.SuccessResponse(c, gin.H{"message": "Dispute updated"})
}

// ================ Platform Settings ================
func (h *AdminHandler) GetSettings(c *gin.Context) {
	var settings []models.PlatformSetting
	h.db.Find(&settings)

	settingMap := make(map[string]string)
	for _, s := range settings {
		settingMap[s.Key] = s.Value
	}

	utils.SuccessResponse(c, settingMap)
}

func (h *AdminHandler) UpdateSettings(c *gin.Context) {
	var req map[string]string
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	for key, value := range req {
		h.db.Model(&models.PlatformSetting{}).Where("key = ?", key).Update("value", value)
	}

	utils.SuccessResponse(c, gin.H{"message": "Settings updated"})
}

// ================ Commission Management ================
func (h *AdminHandler) UpdateCommission(c *gin.Context) {
	var req struct {
		VendorID uuid.UUID `json:"vendor_id" binding:"required"`
		Rate     float64   `json:"rate" binding:"required,gte=0,lte=100"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	h.db.Model(&models.Vendor{}).Where("id = ?", req.VendorID).Update("commission_rate", req.Rate)
	utils.SuccessResponse(c, gin.H{"message": "Commission rate updated"})
}

// ================ Bookings Management ================
func (h *AdminHandler) ListAllBookings(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var bookings []models.Booking
	var total int64

	query := h.db.Model(&models.Booking{}).Preload("Barber").Preload("Customer").Preload("Services")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if date := c.Query("date"); date != "" {
		query = query.Where("DATE(scheduled_start) = DATE(?)", date)
	}
	if barberID := c.Query("barber_id"); barberID != "" {
		query = query.Where("barber_id = ?", barberID)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("scheduled_start DESC").Find(&bookings)

	utils.PaginatedResponse(c, bookings, page, pageSize, total)
}

// ================ Category Management ================
func (h *AdminHandler) CreateCategory(c *gin.Context) {
	var req struct {
		Name         string  `json:"name" binding:"required"`
		Description  string  `json:"description"`
		Image        string  `json:"image"`
		Icon         string  `json:"icon"`
		ParentID     *uuid.UUID `json:"parent_id"`
		CategoryType string  `json:"category_type" binding:"required,oneof=product barber_service"`
		SortOrder    int     `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	category := models.Category{
		Name:         req.Name,
		Slug:         utils.GenerateSlug(req.Name),
		Description:  req.Description,
		Image:        req.Image,
		Icon:         req.Icon,
		ParentID:     req.ParentID,
		CategoryType: models.CategoryType(req.CategoryType),
		SortOrder:    req.SortOrder,
		IsActive:     true,
	}
	h.db.Create(&category)
	utils.CreatedResponse(c, category)
}

func (h *AdminHandler) UpdateCategory(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid category ID")
		return
	}

	var updates map[string]interface{}
	c.ShouldBindJSON(&updates)

	allowed := []string{"name", "description", "image", "icon", "sort_order", "is_active", "is_featured"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	h.db.Model(&models.Category{}).Where("id = ?", id).Updates(filtered)
	utils.SuccessResponse(c, gin.H{"message": "Category updated"})
}

// ================ Feature Management ================
func (h *AdminHandler) ToggleFeature(c *gin.Context) {
	var req struct {
		ProductID *uuid.UUID `json:"product_id"`
		BarberID  *uuid.UUID `json:"barber_id"`
		VendorID  *uuid.UUID `json:"vendor_id"`
		IsFeatured bool      `json:"is_featured"`
	}
	c.ShouldBindJSON(&req)

	if req.ProductID != nil {
		h.db.Model(&models.Product{}).Where("id = ?", *req.ProductID).Update("is_featured", req.IsFeatured)
	}
	if req.BarberID != nil {
		h.db.Model(&models.Barber{}).Where("id = ?", *req.BarberID).Update("is_featured", req.IsFeatured)
	}
	if req.VendorID != nil {
		h.db.Model(&models.Vendor{}).Where("id = ?", *req.VendorID).Update("is_featured", req.IsFeatured)
	}

	utils.SuccessResponse(c, gin.H{"message": "Feature status updated"})
}

// ================ System Health ================
func (h *AdminHandler) GetSystemHealth(c *gin.Context) {
	utils.SuccessResponse(c, gin.H{
		"status":    "healthy",
		"timestamp": time.Now(),
		"version":   "1.0.0",
	})
}

func (h *AdminHandler) GetAuditLogs(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var logs []models.AuditLog
	var total int64

	query := h.db.Model(&models.AuditLog{})
	if action := c.Query("action"); action != "" {
		query = query.Where("action = ?", action)
	}
	if entity := c.Query("entity_type"); entity != "" {
		query = query.Where("entity_type = ?", entity)
	}
	if userID := c.Query("user_id"); userID != "" {
		query = query.Where("user_id = ?", userID)
	}

	query.Count(&total)
	query.Offset((page-1)*pageSize).Limit(pageSize).Order("created_at DESC").Find(&logs)

	utils.PaginatedResponse(c, logs, page, pageSize, total)
}

// ================ SubCategory Management ================
func (h *AdminHandler) CreateSubCategory(c *gin.Context) {
	var req struct {
		CategoryID  uuid.UUID `json:"category_id" binding:"required"`
		Name        string    `json:"name" binding:"required"`
		Description string    `json:"description"`
		Image       string    `json:"image"`
		SortOrder   int       `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	sub := models.SubCategory{
		CategoryID:  req.CategoryID,
		Name:        req.Name,
		Slug:        utils.GenerateSlug(req.Name),
		Description: req.Description,
		Image:       req.Image,
		SortOrder:   req.SortOrder,
		IsActive:    true,
	}
	h.db.Create(&sub)
	utils.CreatedResponse(c, sub)
}

func (h *AdminHandler) UpdateSubCategory(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid sub-category ID")
		return
	}

	var sub models.SubCategory
	if err := h.db.First(&sub, id).Error; err != nil {
		utils.NotFoundResponse(c, "SubCategory not found")
		return
	}

	var updates map[string]interface{}
	c.ShouldBindJSON(&updates)

	allowed := []string{"name", "description", "image", "sort_order", "is_active", "category_id"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	h.db.Model(&sub).Updates(filtered)
	h.db.First(&sub, id)
	utils.SuccessResponse(c, sub)
}

func (h *AdminHandler) DeleteSubCategory(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid sub-category ID")
		return
	}

	result := h.db.Delete(&models.SubCategory{}, id)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "SubCategory not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "SubCategory deleted"})
}

func (h *AdminHandler) ListSubCategories(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var subs []models.SubCategory
	var total int64

	query := h.db.Model(&models.SubCategory{})
	if catID := c.Query("category_id"); catID != "" {
		query = query.Where("category_id = ?", catID)
	}
	if active := c.Query("is_active"); active != "" {
		query = query.Where("is_active = ?", active == "true")
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("sort_order ASC, name ASC").Find(&subs)

	utils.PaginatedResponse(c, subs, page, pageSize, total)
}

// ================ Tax Settings ================
func (h *AdminHandler) ListTaxSettings(c *gin.Context) {
	var taxes []models.TaxSetting
	query := h.db.Model(&models.TaxSetting{})
	if active := c.Query("is_active"); active != "" {
		query = query.Where("is_active = ?", active == "true")
	}
	if typ := c.Query("type"); typ != "" {
		query = query.Where("type = ?", typ)
	}
	query.Order("sort_order ASC, name ASC").Find(&taxes)
	utils.SuccessResponse(c, taxes)
}

func (h *AdminHandler) CreateTaxSetting(c *gin.Context) {
	var req struct {
		Name         string  `json:"name" binding:"required"`
		Rate         float64 `json:"rate" binding:"required"`
		Type         string  `json:"type"`
		Description  string  `json:"description"`
		ApplicableTo string  `json:"applicable_to"`
		HSNCode      string  `json:"hsn_code"`
		SACCode      string  `json:"sac_code"`
		CGSTRate     float64 `json:"cgst_rate"`
		SGSTRate     float64 `json:"sgst_rate"`
		IGSTRate     float64 `json:"igst_rate"`
		CessRate     float64 `json:"cess_rate"`
		SortOrder    int     `json:"sort_order"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	tax := models.TaxSetting{
		Name:         req.Name,
		Rate:         req.Rate,
		Type:         req.Type,
		Description:  req.Description,
		IsActive:     true,
		ApplicableTo: req.ApplicableTo,
		HSNCode:      req.HSNCode,
		SACCode:      req.SACCode,
		CGSTRate:     req.CGSTRate,
		SGSTRate:     req.SGSTRate,
		IGSTRate:     req.IGSTRate,
		CessRate:     req.CessRate,
		SortOrder:    req.SortOrder,
	}
	h.db.Create(&tax)
	utils.CreatedResponse(c, tax)
}

func (h *AdminHandler) UpdateTaxSetting(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid tax setting ID")
		return
	}

	var tax models.TaxSetting
	if err := h.db.First(&tax, id).Error; err != nil {
		utils.NotFoundResponse(c, "Tax setting not found")
		return
	}

	var updates map[string]interface{}
	c.ShouldBindJSON(&updates)

	allowed := []string{"name", "rate", "type", "description", "is_active", "applicable_to",
		"hsn_code", "sac_code", "cgst_rate", "sgst_rate", "igst_rate", "cess_rate", "sort_order"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	h.db.Model(&tax).Updates(filtered)
	h.db.First(&tax, id)
	utils.SuccessResponse(c, tax)
}

func (h *AdminHandler) DeleteTaxSetting(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid tax setting ID")
		return
	}

	result := h.db.Delete(&models.TaxSetting{}, id)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Tax setting not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "Tax setting deleted"})
}

// ================ Featured Listings ================
func (h *AdminHandler) ListFeaturedListings(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var listings []models.FeaturedListing
	var total int64

	query := h.db.Model(&models.FeaturedListing{}).Preload("Product").Preload("Barber").Preload("Vendor")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("created_at DESC").Find(&listings)

	utils.PaginatedResponse(c, listings, page, pageSize, total)
}

func (h *AdminHandler) CreateFeaturedListing(c *gin.Context) {
	var req struct {
		ProductID *string `json:"product_id"`
		BarberID  *string `json:"barber_id"`
		VendorID  *string `json:"vendor_id"`
		StartDate string  `json:"start_date" binding:"required"`
		EndDate   string  `json:"end_date" binding:"required"`
		Fee       float64 `json:"fee"`
		Priority  int     `json:"priority"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	startDate, _ := time.Parse("2006-01-02", req.StartDate)
	endDate, _ := time.Parse("2006-01-02", req.EndDate)

	listing := models.FeaturedListing{
		StartDate: startDate,
		EndDate:   endDate,
		Fee:       req.Fee,
		Status:    "active",
		Priority:  req.Priority,
	}

	if req.ProductID != nil {
		pid, _ := uuid.Parse(*req.ProductID)
		listing.ProductID = &pid
	}
	if req.BarberID != nil {
		bid, _ := uuid.Parse(*req.BarberID)
		listing.BarberID = &bid
	}
	if req.VendorID != nil {
		vid, _ := uuid.Parse(*req.VendorID)
		listing.VendorID = &vid
	}

	h.db.Create(&listing)
	utils.CreatedResponse(c, listing)
}

func (h *AdminHandler) DeleteFeaturedListing(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid featured listing ID")
		return
	}

	result := h.db.Delete(&models.FeaturedListing{}, id)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Featured listing not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "Featured listing deleted"})
}

// ================ Notification Templates ================
func (h *AdminHandler) ListNotificationTemplates(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var templates []models.NotificationTemplate
	var total int64

	query := h.db.Model(&models.NotificationTemplate{})
	if typ := c.Query("type"); typ != "" {
		query = query.Where("type = ?", typ)
	}
	if channel := c.Query("channel"); channel != "" {
		query = query.Where("channel = ?", channel)
	}
	if active := c.Query("is_active"); active != "" {
		query = query.Where("is_active = ?", active == "true")
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("name ASC").Find(&templates)

	utils.PaginatedResponse(c, templates, page, pageSize, total)
}

func (h *AdminHandler) GetNotificationTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid template ID")
		return
	}

	var tpl models.NotificationTemplate
	if err := h.db.First(&tpl, id).Error; err != nil {
		utils.NotFoundResponse(c, "Notification template not found")
		return
	}
	utils.SuccessResponse(c, tpl)
}

func (h *AdminHandler) CreateNotificationTemplate(c *gin.Context) {
	var req struct {
		Name      string      `json:"name" binding:"required"`
		Title     string      `json:"title" binding:"required"`
		Body      string      `json:"body" binding:"required"`
		Type      string      `json:"type" binding:"required"`
		Variables interface{} `json:"variables"`
		Channel   string      `json:"channel"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	variablesBytes, err := json.Marshal(req.Variables)
	if err != nil {
		utils.InternalErrorResponse(c, "Invalid variables format")
		return
	}

	tpl := models.NotificationTemplate{
		Name:      req.Name,
		Title:     req.Title,
		Body:      req.Body,
		Type:      models.NotificationType(req.Type),
		Variables: models.JSONB(variablesBytes),
		IsActive:  true,
		Channel:   req.Channel,
	}

	h.db.Create(&tpl)
	utils.CreatedResponse(c, tpl)
}

func (h *AdminHandler) UpdateNotificationTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid template ID")
		return
	}

	var tpl models.NotificationTemplate
	if err := h.db.First(&tpl, id).Error; err != nil {
		utils.NotFoundResponse(c, "Notification template not found")
		return
	}

	var req struct {
		Name     *string     `json:"name"`
		Title    *string     `json:"title"`
		Body     *string     `json:"body"`
		Type     *string     `json:"type"`
		IsActive *bool       `json:"is_active"`
		Channel  *string     `json:"channel"`
	}
	c.ShouldBindJSON(&req)

	updates := map[string]interface{}{}
	if req.Name != nil { updates["name"] = *req.Name }
	if req.Title != nil { updates["title"] = *req.Title }
	if req.Body != nil { updates["body"] = *req.Body }
	if req.Type != nil { updates["type"] = *req.Type }
	if req.IsActive != nil { updates["is_active"] = *req.IsActive }
	if req.Channel != nil { updates["channel"] = *req.Channel }

	h.db.Model(&tpl).Updates(updates)
	utils.SuccessResponse(c, tpl)
}

func (h *AdminHandler) DeleteNotificationTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid template ID")
		return
	}

	result := h.db.Delete(&models.NotificationTemplate{}, id)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Notification template not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "Notification template deleted"})
}

// ================ KYC Verification (Admin) ================
func (h *AdminHandler) ListKYCDocuments(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var docs []models.KYCDocument
	var total int64

	query := h.db.Model(&models.KYCDocument{}).Preload("User")
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if docType := c.Query("doc_type"); docType != "" {
		query = query.Where("doc_type = ?", docType)
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("created_at DESC").Find(&docs)

	utils.PaginatedResponse(c, docs, page, pageSize, total)
}

func (h *AdminHandler) VerifyKYCDocument(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid KYC document ID")
		return
	}

	var req struct {
		Status       string `json:"status" binding:"required,oneof=approved rejected"`
		RejectReason string `json:"reject_reason"`
	}
	c.ShouldBindJSON(&req)

	var doc models.KYCDocument
	if err := h.db.First(&doc, id).Error; err != nil {
		utils.NotFoundResponse(c, "KYC document not found")
		return
	}

	now := time.Now()
	updates := map[string]interface{}{
		"status":     req.Status,
		"verified_by": adminID,
		"verified_at": &now,
	}
	if req.Status == "rejected" {
		updates["reject_reason"] = req.RejectReason
	}

	h.db.Model(&doc).Updates(updates)
	utils.SuccessResponse(c, gin.H{"message": "KYC document " + req.Status})
}

// ================ Document Verification (Admin: Barber & Vendor docs) ================
func (h *AdminHandler) ListBarberDocuments(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var docs []models.BarberDocument
	var total int64

	query := h.db.Model(&models.BarberDocument{})
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if barberID := c.Query("barber_id"); barberID != "" {
		query = query.Where("barber_id = ?", barberID)
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("created_at DESC").Find(&docs)

	utils.PaginatedResponse(c, docs, page, pageSize, total)
}

func (h *AdminHandler) VerifyBarberDocument(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid document ID")
		return
	}

	var req struct {
		Status  string `json:"status" binding:"required,oneof=approved rejected"`
		Remarks string `json:"remarks"`
	}
	c.ShouldBindJSON(&req)

	var doc models.BarberDocument
	if err := h.db.First(&doc, id).Error; err != nil {
		utils.NotFoundResponse(c, "Document not found")
		return
	}

	now := time.Now()
	h.db.Model(&doc).Updates(map[string]interface{}{
		"status":      req.Status,
		"verified_by": adminID,
		"verified_at": &now,
		"remarks":     req.Remarks,
	})
	utils.SuccessResponse(c, gin.H{"message": "Document " + req.Status})
}

func (h *AdminHandler) ListVendorDocuments(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)

	var docs []models.VendorDocument
	var total int64

	query := h.db.Model(&models.VendorDocument{})
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if vendorID := c.Query("vendor_id"); vendorID != "" {
		query = query.Where("vendor_id = ?", vendorID)
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("created_at DESC").Find(&docs)

	utils.PaginatedResponse(c, docs, page, pageSize, total)
}

func (h *AdminHandler) VerifyVendorDocument(c *gin.Context) {
	adminID := c.MustGet("user").(uuid.UUID)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid document ID")
		return
	}

	var req struct {
		Status  string `json:"status" binding:"required,oneof=approved rejected"`
		Remarks string `json:"remarks"`
	}
	c.ShouldBindJSON(&req)

	var doc models.VendorDocument
	if err := h.db.First(&doc, id).Error; err != nil {
		utils.NotFoundResponse(c, "Document not found")
		return
	}

	now := time.Now()
	h.db.Model(&doc).Updates(map[string]interface{}{
		"status":      req.Status,
		"verified_by": adminID,
		"verified_at": &now,
		"remarks":     req.Remarks,
	})
	utils.SuccessResponse(c, gin.H{"message": "Document " + req.Status})
}


