package review

import (
	"context"
	"fmt"
	"slices"
	"time"

	"github.com/barbar-app/backend/internal/models"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	reviewSvc "github.com/barbar-app/backend/internal/services/review"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ReviewHandler struct {
	db        *gorm.DB
	notifSvc  notifService.Dispatcher
	hub       *websocket.Hub
	ratingSvc *reviewSvc.RatingService
}

func NewReviewHandler(db *gorm.DB, notifSvc notifService.Dispatcher, hub *websocket.Hub) *ReviewHandler {
	return &ReviewHandler{
		db:        db,
		notifSvc:  notifSvc,
		hub:       hub,
		ratingSvc: reviewSvc.NewRatingService(db),
	}
}

type CreateReviewRequest struct {
	BookingID   uuid.UUID          `json:"booking_id" binding:"required"`
	StaffID     *uuid.UUID         `json:"staff_id,omitempty"`
	ShopRating  *int               `json:"shop_rating" binding:"required,min=1,max=5"`
	StaffRating *int               `json:"staff_rating,omitempty" binding:"omitempty,min=1,max=5"`
	Comment     string             `json:"comment"`
	IsAnonymous bool               `json:"is_anonymous"`
	Images      []ReviewImageInput `json:"images"`
}

type ReviewImageInput struct {
	URL       string `json:"url" binding:"required"`
	Thumbnail string `json:"thumbnail"`
	Size      int    `json:"size"`
}

type ModerateReviewRequest struct {
	Status string `json:"status" binding:"required,oneof=approved rejected hidden"`
	Reason string `json:"reason"`
}

func (h *ReviewHandler) Create(c *gin.Context) {
	customerID := c.MustGet("user").(uuid.UUID)

	var req CreateReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var booking models.Booking
	if err := h.db.First(&booking, req.BookingID).Error; err != nil {
		utils.NotFoundResponse(c, "Booking not found")
		return
	}

	if booking.CustomerID != customerID {
		utils.ForbiddenResponse(c, "This booking does not belong to you")
		return
	}

	if booking.Status != models.BookingStatusCompleted {
		utils.BadRequestResponse(c, "Can only review completed bookings")
		return
	}

	if booking.PaymentStatus != "paid" && booking.PaymentStatus != "success" {
		utils.BadRequestResponse(c, "Can only review paid bookings")
		return
	}

	if booking.CompletedAt == nil || !models.IsReviewWindowValid(*booking.CompletedAt) {
		utils.BadRequestResponse(c, fmt.Sprintf("Review window has expired (%d days)", models.ReviewWindowDays))
		return
	}

	var existingCount int64
	h.db.Model(&models.Review{}).Where("booking_id = ?", req.BookingID).Count(&existingCount)
	if existingCount > 0 {
		utils.BadRequestResponse(c, "Booking already reviewed")
		return
	}

	if len(req.Comment) > 0 && (len(req.Comment) < models.MinReviewCommentLen || len(req.Comment) > models.MaxReviewCommentLen) {
		utils.BadRequestResponse(c, fmt.Sprintf("Comment must be %d-%d characters", models.MinReviewCommentLen, models.MaxReviewCommentLen))
		return
	}

	if len(req.Images) > models.MaxReviewImages {
		utils.BadRequestResponse(c, fmt.Sprintf("Maximum %d images allowed", models.MaxReviewImages))
		return
	}

	reviewType := models.ReviewTypeShop
	if req.ShopRating != nil && req.StaffRating != nil {
		reviewType = models.ReviewTypeBoth
	} else if req.StaffRating != nil {
		reviewType = models.ReviewTypeStaff
	}

	ratingVal := 0
	if req.ShopRating != nil {
		ratingVal = *req.ShopRating
	}

	review := models.Review{
		BookingID:   req.BookingID,
		CustomerID:  customerID,
		ShopID:      booking.BarberID,
		StaffID:     req.StaffID,
		Rating:      ratingVal,
		ShopRating:  req.ShopRating,
		StaffRating: req.StaffRating,
		ReviewType:  reviewType,
		Comment:     req.Comment,
		IsAnonymous: req.IsAnonymous,
		IsVerified:  true,
		Status:      models.ReviewStatusApproved,
	}

	tx := h.db.Begin()

	if err := tx.Create(&review).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to create review")
		return
	}

	for i, img := range req.Images {
		ri := models.ReviewImage{
			ReviewID:  review.ID,
			URL:       img.URL,
			Thumbnail: img.Thumbnail,
			SortOrder: i + 1,
			Size:      img.Size,
		}
		if err := tx.Create(&ri).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to save review images")
			return
		}
	}

	tx.Commit()

	// Recalculate ratings immediately since review is auto-approved
	h.ratingSvc.RecalculateShopRating(review.ShopID)
	if review.StaffID != nil {
		h.ratingSvc.RecalculateStaffRating(*review.StaffID)
	}

	go h.sendReviewNotifications(&review)

	h.db.Preload("Images").First(&review, review.ID)
	utils.CreatedResponse(c, review)
}

type UpdateReviewRequest struct {
	ShopRating  *int               `json:"shop_rating" binding:"required,min=1,max=5"`
	StaffRating *int               `json:"staff_rating,omitempty" binding:"omitempty,min=1,max=5"`
	Comment     string             `json:"comment"`
	IsAnonymous bool               `json:"is_anonymous"`
	Images      []ReviewImageInput `json:"images"`
}

func (h *ReviewHandler) Update(c *gin.Context) {
	reviewID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid review ID")
		return
	}

	customerID := c.MustGet("user").(uuid.UUID)

	var req UpdateReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var review models.Review
	if err := h.db.First(&review, reviewID).Error; err != nil {
		utils.NotFoundResponse(c, "Review not found")
		return
	}

	if review.CustomerID != customerID {
		utils.ForbiddenResponse(c, "This review does not belong to you")
		return
	}

	if review.Status != models.ReviewStatusPending {
		utils.BadRequestResponse(c, "Can only edit pending reviews")
		return
	}

	if len(req.Comment) > 0 && (len(req.Comment) < models.MinReviewCommentLen || len(req.Comment) > models.MaxReviewCommentLen) {
		utils.BadRequestResponse(c, fmt.Sprintf("Comment must be %d-%d characters", models.MinReviewCommentLen, models.MaxReviewCommentLen))
		return
	}

	if len(req.Images) > models.MaxReviewImages {
		utils.BadRequestResponse(c, fmt.Sprintf("Maximum %d images allowed", models.MaxReviewImages))
		return
	}

	reviewType := models.ReviewTypeShop
	if req.ShopRating != nil && req.StaffRating != nil {
		reviewType = models.ReviewTypeBoth
	} else if req.StaffRating != nil {
		reviewType = models.ReviewTypeStaff
	}

	review.ShopRating = req.ShopRating
	review.StaffRating = req.StaffRating
	review.ReviewType = reviewType
	review.Comment = req.Comment
	review.IsAnonymous = req.IsAnonymous

	tx := h.db.Begin()

	if err := tx.Save(&review).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to update review")
		return
	}

	// Replace images: delete existing, insert new
	tx.Where("review_id = ?", review.ID).Delete(&models.ReviewImage{})
	for i, img := range req.Images {
		ri := models.ReviewImage{
			ReviewID:  review.ID,
			URL:       img.URL,
			Thumbnail: img.Thumbnail,
			SortOrder: i + 1,
			Size:      img.Size,
		}
		if err := tx.Create(&ri).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to save review images")
			return
		}
	}

	tx.Commit()

	h.db.Preload("Images").First(&review, review.ID)
	utils.SuccessResponse(c, review)
}

func (h *ReviewHandler) Moderate(c *gin.Context) {
	reviewID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid review ID")
		return
	}

	var req ModerateReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var review models.Review
	if err := h.db.First(&review, reviewID).Error; err != nil {
		utils.NotFoundResponse(c, "Review not found")
		return
	}

	if review.Status != models.ReviewStatusPending {
		utils.BadRequestResponse(c, "Can only moderate pending reviews")
		return
	}

	adminID := c.MustGet("user").(uuid.UUID)
	now := time.Now()

	toStatus := models.ReviewStatus(req.Status)
	review.Status = toStatus

	switch toStatus {
	case models.ReviewStatusApproved:
		review.ApprovedBy = &adminID
		review.ApprovedAt = &now
		review.RejectedBy = nil
		review.RejectionReason = ""
	case models.ReviewStatusRejected:
		review.RejectedBy = &adminID
		review.RejectionReason = req.Reason
		review.ApprovedBy = nil
		review.ApprovedAt = nil
	}

	h.db.Save(&review)

	// Recalculate ratings only on approval
	if toStatus == models.ReviewStatusApproved {
		h.ratingSvc.RecalculateShopRating(review.ShopID)
		if review.StaffID != nil {
			h.ratingSvc.RecalculateStaffRating(*review.StaffID)
		}
	}

	switch toStatus {
	case models.ReviewStatusApproved:
		h.sendModerationNotification(review.CustomerID, review.ID, "Your review has been approved and is now live.")
	case models.ReviewStatusRejected:
		reason := req.Reason
		if reason == "" {
			reason = "It did not meet our guidelines."
		}
		h.sendModerationNotification(review.CustomerID, review.ID, fmt.Sprintf("Your review was not approved. Reason: %s", reason))
	}

	// Reload with images
	h.db.Preload("Images").First(&review, review.ID)
	utils.SuccessResponse(c, review)
}

func (h *ReviewHandler) ListPublicReviews(c *gin.Context) {
	shopID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid shop ID")
		return
	}

	var barber models.Barber
	if err := h.db.First(&barber, shopID).Error; err != nil {
		utils.NotFoundResponse(c, "Shop not found")
		return
	}

	page, pageSize := utils.GetPageParams(c)
	sort := c.DefaultQuery("sort", models.ReviewSortNewest)
	staffIDFilter := c.Query("staff_id")

	if !slices.Contains(models.ValidReviewSorts, sort) {
		sort = models.ReviewSortNewest
	}

	orderClause := "created_at DESC"
	switch sort {
	case models.ReviewSortHighest:
		orderClause = "COALESCE(shop_rating, 0) DESC, created_at DESC"
	case models.ReviewSortLowest:
		orderClause = "COALESCE(shop_rating, 0) ASC, created_at DESC"
	}

	var total int64
	totalQuery := h.db.Model(&models.Review{}).Where("shop_id = ? AND status = ?", shopID, models.ReviewStatusApproved)
	dataQuery := h.db.Where("shop_id = ? AND status = ?", shopID, models.ReviewStatusApproved)

	if staffIDFilter != "" {
		if parsed, err := uuid.Parse(staffIDFilter); err == nil {
			totalQuery = totalQuery.Where("staff_id = ?", parsed)
			dataQuery = dataQuery.Where("staff_id = ?", parsed)
		}
	}
	totalQuery.Count(&total)

	var reviews []models.Review
	offset := (page - 1) * pageSize
	dataQuery.
		Preload("Images", func(db *gorm.DB) *gorm.DB {
			return db.Order("sort_order ASC")
		}).
		Preload("Reply").
		Preload("Customer").
		Order(orderClause).
		Offset(offset).
		Limit(pageSize).
		Find(&reviews)

	for i := range reviews {
		if reviews[i].IsAnonymous {
			reviews[i].Customer = nil
		}
	}

	utils.PaginatedResponse(c, gin.H{
		"reviews": reviews,
		"summary": gin.H{
			"avg_rating":          barber.Rating,
			"total_reviews":       barber.ReviewCount,
			"rating_distribution": barber.RatingDistribution,
		},
	}, page, pageSize, total)
}

func (h *ReviewHandler) ListMyReviews(c *gin.Context) {
	customerID := c.MustGet("user").(uuid.UUID)
	page, pageSize := utils.GetPageParams(c)

	var total int64
	h.db.Model(&models.Review{}).Where("customer_id = ?", customerID).Count(&total)

	var reviews []models.Review
	offset := (page - 1) * pageSize
	h.db.Where("customer_id = ?", customerID).
		Preload("Images", func(db *gorm.DB) *gorm.DB {
			return db.Order("sort_order ASC")
		}).
		Preload("Shop").
		Order("created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&reviews)

	utils.PaginatedResponse(c, reviews, page, pageSize, total)
}

// ListStaffReviews returns approved reviews for a specific staff member (public)
func (h *ReviewHandler) ListStaffReviews(c *gin.Context) {
	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid staff ID")
		return
	}

	page, pageSize := utils.GetPageParams(c)

	var total int64
	h.db.Model(&models.Review{}).Where("staff_id = ? AND status = ?", staffID, models.ReviewStatusApproved).Count(&total)

	var reviews []models.Review
	offset := (page - 1) * pageSize
	h.db.Where("staff_id = ? AND status = ?", staffID, models.ReviewStatusApproved).
		Preload("Images", func(db *gorm.DB) *gorm.DB {
			return db.Order("sort_order ASC")
		}).
		Preload("Reply").
		Order("created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&reviews)

	for i := range reviews {
		if reviews[i].IsAnonymous {
			reviews[i].Customer = nil
		}
	}

	utils.PaginatedResponse(c, gin.H{
		"reviews": reviews,
	}, page, pageSize, total)
}

func (h *ReviewHandler) ListAllReviews(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")

	var total int64
	q := h.db.Model(&models.Review{})
	if status != "" {
		q = q.Where("status = ?", status)
	}
	q.Count(&total)

	var reviews []models.Review
	offset := (page - 1) * pageSize

	query := h.db.Preload("Images", func(db *gorm.DB) *gorm.DB {
		return db.Order("sort_order ASC")
	}).Preload("Customer").Preload("Shop")

	if status != "" {
		query = query.Where("status = ?", status)
	}

	query.Order("created_at DESC").
		Offset(offset).
		Limit(pageSize).
		Find(&reviews)

	utils.PaginatedResponse(c, reviews, page, pageSize, total)
}

func (h *ReviewHandler) GetShopRatingSummary(c *gin.Context) {
	shopID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid shop ID")
		return
	}

	var barber models.Barber
	if err := h.db.Select("id, shop_name, rating, review_count, rating_distribution").First(&barber, shopID).Error; err != nil {
		utils.NotFoundResponse(c, "Shop not found")
		return
	}

	utils.SuccessResponse(c, gin.H{
		"shop_id":             barber.ID,
		"shop_name":           barber.ShopName,
		"avg_rating":          barber.Rating,
		"total_reviews":       barber.ReviewCount,
		"rating_distribution": barber.RatingDistribution,
	})
}

func (h *ReviewHandler) GetStaffRatingSummary(c *gin.Context) {
	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Select("id, name, rating, review_count, rating_distribution").First(&staff, staffID).Error; err != nil {
		utils.NotFoundResponse(c, "Staff not found")
		return
	}

	utils.SuccessResponse(c, gin.H{
		"staff_id":            staff.ID,
		"staff_name":          staff.Name,
		"avg_rating":          staff.Rating,
		"total_reviews":       staff.ReviewCount,
		"rating_distribution": staff.RatingDistribution,
	})
}

type ReportReviewRequest struct {
	Reason       models.ReviewReportReason `json:"reason" binding:"required,oneof=spam abusive fake wrong_information other"`
	CustomReason string                    `json:"custom_reason"`
}

func (h *ReviewHandler) Report(c *gin.Context) {
	reviewID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid review ID")
		return
	}

	userID := c.MustGet("user").(uuid.UUID)

	var req ReportReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if req.Reason == models.ReportOther && req.CustomReason == "" {
		utils.BadRequestResponse(c, "Custom reason required when reason is 'other'")
		return
	}

	var review models.Review
	if err := h.db.First(&review, reviewID).Error; err != nil {
		utils.NotFoundResponse(c, "Review not found")
		return
	}

	if review.CustomerID == userID {
		utils.BadRequestResponse(c, "Cannot report your own review")
		return
	}

	var existing int64
	h.db.Model(&models.ReviewReport{}).Where("review_id = ? AND reporter_id = ?", reviewID, userID).Count(&existing)
	if existing > 0 {
		utils.BadRequestResponse(c, "Already reported this review")
		return
	}

	report := models.ReviewReport{
		ReviewID:     reviewID,
		ReporterID:   userID,
		Reason:       req.Reason,
		CustomReason: req.CustomReason,
	}

	if err := h.db.Create(&report).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to report review")
		return
	}

	// Auto-hide if report threshold reached
	var reportCount int64
	h.db.Model(&models.ReviewReport{}).Where("review_id = ? AND status = ?", reviewID, models.ReportStatusPending).Count(&reportCount)
	if reportCount >= models.AutoHideReportThreshold && review.Status == models.ReviewStatusApproved {
		review.Status = models.ReviewStatusHidden
		h.db.Save(&review)
	}

	utils.CreatedResponse(c, report)
}

type CreateReplyRequest struct {
	Message string `json:"message" binding:"required,min=1,max=500"`
}

func (h *ReviewHandler) CreateReply(c *gin.Context) {
	reviewID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid review ID")
		return
	}

	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.ForbiddenResponse(c, "Only barbers can reply to reviews")
		return
	}

	var req CreateReplyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var review models.Review
	if err := h.db.First(&review, reviewID).Error; err != nil {
		utils.NotFoundResponse(c, "Review not found")
		return
	}

	if review.ShopID != barber.ID {
		utils.ForbiddenResponse(c, "This review is not for your shop")
		return
	}

	if review.Status != models.ReviewStatusApproved {
		utils.BadRequestResponse(c, "Can only reply to approved reviews")
		return
	}

	var existing models.ReviewReply
	if err := h.db.Where("review_id = ?", reviewID).First(&existing).Error; err == nil {
		utils.BadRequestResponse(c, "Already replied to this review")
		return
	}

	reply := models.ReviewReply{
		ReviewID: reviewID,
		ShopID:   barber.ID,
		Message:  req.Message,
	}

	if err := h.db.Create(&reply).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create reply")
		return
	}

	// review is already fetched above

	if h.notifSvc != nil {
		h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
			Type:       models.NotifReviewReply,
			ReceiverID: review.CustomerID,
			Role:       notifService.RoleCustomer,
			Data: map[string]interface{}{
				"review_id": reviewID.String(),
			},
		})
	}

	utils.CreatedResponse(c, reply)
}

// ==================== Admin report management ====================

// ListAllReports returns paginated review reports (admin only)
func (h *ReviewHandler) ListAllReports(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")

	var total int64
	q := h.db.Model(&models.ReviewReport{})
	if status != "" {
		q = q.Where("status = ?", status)
	}
	q.Count(&total)

	var reports []models.ReviewReport
	offset := (page - 1) * pageSize
	query := h.db.Preload("Review").Preload("Reporter").Preload("Review.Customer").Preload("Review.Shop")
	if status != "" {
		query = query.Where("status = ?", status)
	}
	query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&reports)

	utils.PaginatedResponse(c, reports, page, pageSize, total)
}

type ResolveReportRequest struct {
	Status models.ReviewReportStatus `json:"status" binding:"required,oneof=resolved dismissed"`
}

// ResolveReport resolves or dismisses a review report (admin only)
func (h *ReviewHandler) ResolveReport(c *gin.Context) {
	reportID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid report ID")
		return
	}

	adminID := c.MustGet("user").(uuid.UUID)

	var req ResolveReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var report models.ReviewReport
	if err := h.db.First(&report, reportID).Error; err != nil {
		utils.NotFoundResponse(c, "Report not found")
		return
	}

	if report.Status != models.ReportStatusPending {
		utils.BadRequestResponse(c, "Report already resolved")
		return
	}

	now := time.Now()
	report.Status = req.Status
	report.ResolvedBy = &adminID
	report.ResolvedAt = &now
	h.db.Save(&report)

	utils.SuccessResponse(c, report)
}

// DeleteReview hard-deletes a review (admin only)
func (h *ReviewHandler) DeleteReview(c *gin.Context) {
	reviewID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid review ID")
		return
	}

	var review models.Review
	if err := h.db.Preload("Images").Preload("Reply").First(&review, reviewID).Error; err != nil {
		utils.NotFoundResponse(c, "Review not found")
		return
	}

	tx := h.db.Begin()
	tx.Where("review_id = ?", review.ID).Delete(&models.ReviewImage{})
	tx.Where("review_id = ?", review.ID).Delete(&models.ReviewReply{})
	tx.Where("review_id = ?", review.ID).Delete(&models.ReviewReport{})
	tx.Delete(&review)
	tx.Commit()

	// Recalculate ratings
	h.ratingSvc.RecalculateShopRating(review.ShopID)
	if review.StaffID != nil {
		h.ratingSvc.RecalculateStaffRating(*review.StaffID)
	}

	utils.SuccessResponse(c, gin.H{"message": "Review deleted"})
}

// GetReviewAnalytics returns review stats for admin dashboard
func (h *ReviewHandler) GetReviewAnalytics(c *gin.Context) {
	var total, pending, approved, rejected, hidden int64
	h.db.Model(&models.Review{}).Count(&total)
	h.db.Model(&models.Review{}).Where("status = ?", models.ReviewStatusPending).Count(&pending)
	h.db.Model(&models.Review{}).Where("status = ?", models.ReviewStatusApproved).Count(&approved)
	h.db.Model(&models.Review{}).Where("status = ?", models.ReviewStatusRejected).Count(&rejected)
	h.db.Model(&models.Review{}).Where("status = ?", models.ReviewStatusHidden).Count(&hidden)

	var totalReports, pendingReports int64
	h.db.Model(&models.ReviewReport{}).Count(&totalReports)
	h.db.Model(&models.ReviewReport{}).Where("status = ?", models.ReportStatusPending).Count(&pendingReports)

	var reportBreakdown []struct {
		Reason string
		Count  int64
	}
	h.db.Model(&models.ReviewReport{}).Select("reason, COUNT(*) as count").Group("reason").Scan(&reportBreakdown)

	reasons := make(map[string]int64)
	for _, r := range reportBreakdown {
		reasons[r.Reason] = r.Count
	}

	utils.SuccessResponse(c, gin.H{
		"total_reviews":    total,
		"pending":          pending,
		"approved":         approved,
		"rejected":         rejected,
		"hidden":           hidden,
		"total_reports":    totalReports,
		"pending_reports":  pendingReports,
		"report_breakdown": reasons,
	})
}

// Internal helpers

func (h *ReviewHandler) sendReviewNotifications(review *models.Review) {
	if h.notifSvc == nil {
		return
	}

	var barber models.Barber
	if err := h.db.First(&barber, review.ShopID).Error; err != nil {
		return
	}

	primaryRating := 0
	if review.ShopRating != nil {
		primaryRating = *review.ShopRating
	} else if review.StaffRating != nil {
		primaryRating = *review.StaffRating
	}

	ratingLabel := ratingLabel(primaryRating)
	_ = fmt.Sprintf("New Review: %s", ratingLabel)
	_ = fmt.Sprintf("Rating: %d/5 ★ | %s", primaryRating, truncate(review.Comment, 100))

	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifReviewReceived,
		ReceiverID: barber.UserID,
		Role:       notifService.RoleBarber,
		Data: map[string]interface{}{
			"review_id":  review.ID.String(),
			"shop_id":    review.ShopID.String(),
			"rating":     primaryRating,
			"shop_rating": review.ShopRating,
			"staff_rating": review.StaffRating,
		},
	})
}

func (h *ReviewHandler) sendModerationNotification(userID uuid.UUID, reviewID uuid.UUID, message string) {
	if h.notifSvc == nil {
		return
	}
	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifReviewModerated,
		ReceiverID: userID,
		Role:       notifService.RoleCustomer,
		Data: map[string]interface{}{
			"review_id": reviewID.String(),
			"message":   message,
		},
	})
}

func ratingLabel(rating int) string {
	labels := map[int]string{
		5: "Excellent",
		4: "Good",
		3: "Average",
		2: "Poor",
		1: "Very Bad",
	}
	if label, ok := labels[rating]; ok {
		return label
	}
	return "Rated"
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}
