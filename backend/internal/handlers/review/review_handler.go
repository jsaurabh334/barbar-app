package review

import (
	"context"
	"fmt"
	"slices"

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
	Rating      int                `json:"rating" binding:"required,min=1,max=5"`
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

	review := models.Review{
		BookingID:   req.BookingID,
		CustomerID:  customerID,
		ShopID:      booking.BarberID,
		StaffID:     req.StaffID,
		Rating:      req.Rating,
		Comment:     req.Comment,
		IsAnonymous: req.IsAnonymous,
		IsVerified:  true,
		Status:      models.ReviewStatusPending,
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

	go h.sendReviewNotifications(&review)

	h.db.Preload("Images").First(&review, review.ID)
	utils.CreatedResponse(c, review)
}

type UpdateReviewRequest struct {
	Rating      int                `json:"rating" binding:"required,min=1,max=5"`
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

	review.Rating = req.Rating
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

	toStatus := models.ReviewStatus(req.Status)
	review.Status = toStatus
	h.db.Save(&review)

	h.ratingSvc.RecalculateShopRating(review.ShopID)

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

	if !slices.Contains(models.ValidReviewSorts, sort) {
		sort = models.ReviewSortNewest
	}

	orderClause := "created_at DESC"
	switch sort {
	case models.ReviewSortHighest:
		orderClause = "rating DESC, created_at DESC"
	case models.ReviewSortLowest:
		orderClause = "rating ASC, created_at DESC"
	}

	var total int64
	h.db.Model(&models.Review{}).Where("shop_id = ? AND status = ?", shopID, models.ReviewStatusApproved).Count(&total)

	var reviews []models.Review
	offset := (page - 1) * pageSize
	h.db.Where("shop_id = ? AND status = ?", shopID, models.ReviewStatusApproved).
		Preload("Images", func(db *gorm.DB) *gorm.DB {
			return db.Order("sort_order ASC")
		}).
		Preload("Reply").
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

type ReportReviewRequest struct {
	Reason string `json:"reason" binding:"required,min=10,max=500"`
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
		ReviewID:   reviewID,
		ReporterID: userID,
		Reason:     req.Reason,
	}

	if err := h.db.Create(&report).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to report review")
		return
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

// Internal helpers

func (h *ReviewHandler) sendReviewNotifications(review *models.Review) {
	if h.notifSvc == nil {
		return
	}

	var barber models.Barber
	if err := h.db.First(&barber, review.ShopID).Error; err != nil {
		return
	}

	ratingLabel := ratingLabel(review.Rating)
	_ = fmt.Sprintf("New Review: %s", ratingLabel)
	_ = fmt.Sprintf("Rating: %d/5 ★ | %s", review.Rating, truncate(review.Comment, 100))

	h.notifSvc.Dispatch(context.Background(), notifService.NotificationEvent{
		Type:       models.NotifReviewReceived,
		ReceiverID: barber.UserID,
		Role:       notifService.RoleBarber,
		Data: map[string]interface{}{
			"review_id": review.ID.String(),
			"shop_id":   review.ShopID.String(),
			"rating":    review.Rating,
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
