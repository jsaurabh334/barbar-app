package routes

import (
	"net/http"
	"time"

	"os"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/middleware"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	deliveryPartnerHandler "github.com/barbar-app/backend/internal/handlers/delivery_partner"
	"gorm.io/gorm"

	addressHandler "github.com/barbar-app/backend/internal/handlers/address"
	adminHandler "github.com/barbar-app/backend/internal/handlers/admin"

	authHandler "github.com/barbar-app/backend/internal/handlers/auth"
	barberHandler "github.com/barbar-app/backend/internal/handlers/barber"
	bookingHandler "github.com/barbar-app/backend/internal/handlers/booking"
	cartHandler "github.com/barbar-app/backend/internal/handlers/cart"
	couponHandler "github.com/barbar-app/backend/internal/handlers/coupon"
	invoiceHandler "github.com/barbar-app/backend/internal/handlers/invoice"
	kycHandler "github.com/barbar-app/backend/internal/handlers/kyc"
	orderHandler "github.com/barbar-app/backend/internal/handlers/order"
	paymentHandler "github.com/barbar-app/backend/internal/handlers/payment"
	productHandler "github.com/barbar-app/backend/internal/handlers/product"
	searchHandler "github.com/barbar-app/backend/internal/handlers/search"
	uploadHandler "github.com/barbar-app/backend/internal/handlers/upload"
	vendorHandler "github.com/barbar-app/backend/internal/handlers/vendor"
	walletHandler "github.com/barbar-app/backend/internal/handlers/wallet"
	webhookHandler "github.com/barbar-app/backend/internal/handlers/webhook"
	wishlistHandler "github.com/barbar-app/backend/internal/handlers/wishlist"
	reviewHandler "github.com/barbar-app/backend/internal/handlers/review"
	analyticsSvc "github.com/barbar-app/backend/internal/services/analytics"
	invoiceSvc "github.com/barbar-app/backend/internal/services/invoice"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	queueService "github.com/barbar-app/backend/internal/services/queue"
	searchSvc "github.com/barbar-app/backend/internal/services/search"
	uploadService "github.com/barbar-app/backend/internal/services/upload"
	webhookSvc "github.com/barbar-app/backend/internal/services/webhook"
)

func SetupRouter(db *gorm.DB, cfg *config.Config, jwtManager *auth.JWTManager, hub *websocket.Hub) *gin.Engine {
	router := gin.New()

	// Global middleware
	router.Use(middleware.Recovery())
	router.Use(middleware.RequestLogger())
	router.Use(middleware.RequestID())
	router.Use(middleware.SecurityHeaders())
	router.Use(middleware.CORSMiddleware(cfg.Server.AllowOrigins))
	router.Use(gin.Logger())

	// Serve demo static files
	router.Static("/static/demo", "./static/demo")

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "version": cfg.App.Version, "timestamp": time.Now()})
	})

	// WebSocket endpoint
	router.GET("/ws", gin.WrapH(http.HandlerFunc(hub.HandleWebSocket)))

	// Static file serving for uploads
	router.Static("/uploads", cfg.App.Upload.Dir)

	// Initialize notification services for auth handler
	authHandler.InitNotificationServices(cfg)

	// Initialize handlers
	authH := authHandler.NewAuthHandler(db, jwtManager)
	barberH := barberHandler.NewBarberHandler(db)
	notifSvc := notifService.NewNotificationService(db, hub)
	bookingH := bookingHandler.NewBookingHandler(db, notifSvc, hub)
	vendorH := vendorHandler.NewVendorHandler(db)
	deliveryPartnerH := deliveryPartnerHandler.NewDeliveryPartnerHandler(db)
	productH := productHandler.NewProductHandler(db)
	orderH := orderHandler.NewOrderHandler(db)
	paymentH := paymentHandler.NewPaymentHandler(db, cfg)
	walletH := walletHandler.NewWalletHandler(db)
	cartH := cartHandler.NewCartHandler(db)
	wishlistH := wishlistHandler.NewWishlistHandler(db)
	couponH := couponHandler.NewCouponHandler(db)
	adminH := adminHandler.NewAdminHandler(db)
	adminCustomerH := adminHandler.NewAdminCustomerHandler(db)
	addressH := addressHandler.NewAddressHandler(db)
	kycH := kycHandler.NewKYCHandler(db)

	uploadSvc := uploadService.NewUploadService(
		uploadService.WithBasePath(cfg.App.Upload.Dir),
		uploadService.WithMaxSize(cfg.App.Upload.MaxSize),
	)
	uploadH := uploadHandler.NewUploadHandler(uploadSvc, cfg.App.BaseURL)

	searchService := searchSvc.NewSearchService(db)
	analyticsService := analyticsSvc.NewAnalyticsService(db)
	searchH := searchHandler.NewSearchHandler(searchService, analyticsService)

	webhookSvcInstance := webhookSvc.NewWebhookService(db)
	webhookH := webhookHandler.NewWebhookHandler(db, webhookSvcInstance)
	webhookSvcInstance.StartRetryScheduler(5 * time.Minute)

	invoiceService := invoiceSvc.NewInvoiceService(db, cfg.App.BaseURL)
	invoiceH := invoiceHandler.NewInvoiceHandler(invoiceService)
	reviewH := reviewHandler.NewReviewHandler(db, notifSvc, hub)

	// Initialize queue service and start no-show scheduler
	queueSvc := queueService.NewQueueService(db, hub)
	queueSvc.StartNoShowScheduler(5*time.Minute, 15)

	// Middleware
	authMW := middleware.NewAuthMiddleware(jwtManager)
	rateLimiter := middleware.NewRateLimiter(database.RedisClient)

	// API v1
	v1 := router.Group("/api/v1")
	v1.Use(middleware.InvalidateCacheOnWrite())
	{
		// ==================== Public routes ====================
		public := v1.Group("/public")
		{
			// Barbers
			public.GET("/barbers", middleware.CacheMiddleware(300*time.Second), barberH.ListNearby)
			public.GET("/barbers/:id", barberH.GetProfile)
			public.GET("/barbers/:id/services", barberH.ListServices)
			public.GET("/barbers/:id/available-slots", barberH.ListAvailableSlots)

			// Products
			public.GET("/products", middleware.CacheMiddleware(300*time.Second), productH.List)
			public.GET("/products/featured", middleware.CacheMiddleware(300*time.Second), productH.ListFeatured)
			public.GET("/products/:id", productH.Get)
			public.GET("/products/:id/reviews", productH.ListReviews)

			// Vendors
			public.GET("/vendors", middleware.CacheMiddleware(300*time.Second), vendorH.ListVendors)
			public.GET("/vendors/:id", vendorH.GetProfile)

			// Categories
			public.GET("/categories", middleware.CacheMiddleware(600*time.Second), productH.ListCategories)

			// Reviews
			public.GET("/barbers/:id/reviews", reviewH.ListPublicReviews)
			public.GET("/barbers/:id/rating-summary", reviewH.GetShopRatingSummary)

			// Search
			public.GET("/search", searchH.Search)
		}

		// ==================== Upload routes ====================
		uploadRoutes := v1.Group("/upload")
		uploadRoutes.Use(authMW.Authenticate(), middleware.MaxBodySize(32<<20)) // 32MB max
		{
			uploadRoutes.POST("/image", uploadH.UploadImage)
			uploadRoutes.POST("/images", uploadH.UploadMultipleImages)
			uploadRoutes.POST("/doc", uploadH.UploadDoc)
			uploadRoutes.DELETE("/file", uploadH.DeleteUploadedFile)
		}

		// ==================== Auth routes ====================
		auth := v1.Group("/auth")
		{
			auth.POST("/register", rateLimiter.RateLimit(30, time.Minute, middleware.RateLimitByIP), authH.Register)
			auth.POST("/login", rateLimiter.RateLimit(30, time.Minute, middleware.RateLimitByIP), authH.Login)
			auth.POST("/otp/send", rateLimiter.RateLimit(10, time.Minute, middleware.RateLimitByIP), authH.SendOTP)
			auth.POST("/otp/verify", rateLimiter.RateLimit(10, time.Minute, middleware.RateLimitByIP), authH.VerifyOTP)
			// Debug endpoint - only registered when not in production mode or DEV_OTP_DEBUG=true
			if cfg.Server.Mode != "release" || os.Getenv("DEV_OTP_DEBUG") == "true" {
				auth.GET("/otp/debug/:phone", authH.GetOTPDebug)
			}
			auth.POST("/refresh", rateLimiter.RateLimit(30, time.Minute, middleware.RateLimitByIP), authH.RefreshToken)
			auth.POST("/forgot-password", rateLimiter.RateLimit(10, time.Minute, middleware.RateLimitByIP), authH.ForgotPassword)
			auth.POST("/reset-password", rateLimiter.RateLimit(10, time.Minute, middleware.RateLimitByIP), authH.ResetPassword)

			// Protected auth routes
			auth.GET("/profile", authMW.Authenticate(), authH.GetProfile)
			auth.PUT("/profile", authMW.Authenticate(), authH.UpdateProfile)
			auth.PUT("/password", authMW.Authenticate(), authH.ChangePassword)
			auth.POST("/logout", authMW.Authenticate(), authH.Logout)
			auth.DELETE("/account", authMW.Authenticate(), authH.DeleteAccount)
		}

		// ==================== Address routes ====================
		addressRoutes := v1.Group("/addresses")
		addressRoutes.Use(authMW.Authenticate())
		{
			addressRoutes.GET("", addressH.List)
			addressRoutes.POST("", addressH.Create)
			addressRoutes.PUT("/:id", addressH.Update)
			addressRoutes.DELETE("/:id", addressH.Delete)
			addressRoutes.PUT("/:id/default", addressH.SetDefault)
		}

		// ==================== Customer routes ====================
		bookingRoutes := v1.Group("/bookings")
		bookingRoutes.Use(authMW.Authenticate())
		{
			bookingRoutes.POST("", bookingH.Create)
			bookingRoutes.GET("", bookingH.ListCustomerBookings)
			bookingRoutes.GET("/:id", bookingH.Get)
			bookingRoutes.POST("/:id/cancel", bookingH.Cancel)
			bookingRoutes.GET("/:id/receipt", invoiceH.GetBookingReceipt)
			bookingRoutes.GET("/:id/invoice", invoiceH.GetBookingInvoiceJSON)
			bookingRoutes.POST("/:id/payment", bookingH.PayBooking)
		}

		// ==================== Review routes ====================
		reviewRoutes := v1.Group("/reviews")
		reviewRoutes.Use(authMW.Authenticate())
		{
			reviewRoutes.POST("", reviewH.Create)
			reviewRoutes.GET("/mine", reviewH.ListMyReviews)
			reviewRoutes.PUT("/:id", reviewH.Update)
			reviewRoutes.POST("/:id/report", reviewH.Report)
		}

		// ==================== Barber routes ====================
		barberRoutes := v1.Group("/barber")
		barberRoutes.Use(authMW.Authenticate())
		{
			barberRoutes.POST("/register", barberH.Register)
			barberRoutes.GET("/dashboard", barberH.GetDashboard)
			barberRoutes.PUT("/profile", barberH.UpdateProfile)
			barberRoutes.PUT("/availability", barberH.UpdateAvailability)
			barberRoutes.GET("/earnings", barberH.GetEarnings)
			barberRoutes.GET("/bookings", bookingH.ListBarberBookings)
			barberRoutes.PUT("/bookings/:id/status", bookingH.UpdateStatus)
			barberRoutes.PUT("/bookings/:id/services", bookingH.ModifyServices)
			barberRoutes.GET("/queue", bookingH.GetQueue)
			barberRoutes.GET("/queue/:booking_id", bookingH.GetMyQueuePosition)
			barberRoutes.PUT("/queue/reorder", bookingH.ReorderQueue)

			barberRoutes.POST("/reviews/:id/reply", reviewH.CreateReply)

			// Home service management
			barberRoutes.GET("/home-service-requests", bookingH.ListHomeServiceRequests)
			barberRoutes.POST("/home-service-requests/:id/accept", bookingH.AcceptHomeService)
			barberRoutes.POST("/home-service-requests/:id/reject", bookingH.RejectHomeService)

			// Services management
			barberRoutes.GET("/services", barberH.ListServices)
			barberRoutes.POST("/services", barberH.AddService)
			barberRoutes.PUT("/services/:service_id", barberH.UpdateService)
			barberRoutes.DELETE("/services/:service_id", barberH.DeleteService)

			// Holidays
			barberRoutes.POST("/holidays", barberH.AddHoliday)
			barberRoutes.GET("/holidays", barberH.ListHolidays)

			// Weekly schedule
			barberRoutes.POST("/availability/weekly", barberH.SetWeeklySchedule)
			barberRoutes.GET("/availability/weekly", barberH.GetWeeklySchedule)

			// Documents
			barberRoutes.POST("/documents", barberH.UploadDocument)
			barberRoutes.GET("/documents", barberH.ListDocuments)
			barberRoutes.DELETE("/documents/:id", barberH.DeleteDocument)
		}
	// ==================== Delivery Partner routes ====================
	dpRoutes := v1.Group("/delivery-partners")
	// Public endpoint
	dpRoutes.GET("/nearby", deliveryPartnerH.ListNearby)
	// Protected routes
	dpRoutesAuth := dpRoutes.Group("")
	dpRoutesAuth.Use(authMW.Authenticate())
	{
		dpRoutesAuth.POST("/register", deliveryPartnerH.Register)
		dpRoutesAuth.GET("/profile", deliveryPartnerH.GetProfile)
		dpRoutesAuth.PUT("/location", deliveryPartnerH.UpdateLocation)
		dpRoutesAuth.PUT("/availability", deliveryPartnerH.UpdateAvailability)
	}

		// ==================== Vendor routes ====================
		vendorRoutes := v1.Group("/vendor")
		vendorRoutes.Use(authMW.Authenticate())
		{
			vendorRoutes.POST("/register", vendorH.Register)
			vendorRoutes.GET("/dashboard", vendorH.GetDashboard)
			vendorRoutes.PUT("/profile", vendorH.UpdateProfile)
			vendorRoutes.GET("/orders", orderH.ListVendorOrders)
			vendorRoutes.PUT("/orders/:id/status", orderH.UpdateStatus)
			vendorRoutes.GET("/products", productH.ListByVendor)
			vendorRoutes.GET("/sales-report", vendorH.GetSalesReport)

			// Bank accounts
			vendorRoutes.POST("/bank-accounts", vendorH.AddBankAccount)
			vendorRoutes.GET("/bank-accounts", vendorH.ListBankAccounts)
			vendorRoutes.PUT("/bank-accounts/:account_id", vendorH.UpdateBankAccount)

			// Documents
			vendorRoutes.POST("/documents", vendorH.UploadDocument)
			vendorRoutes.GET("/documents", vendorH.ListDocuments)
			vendorRoutes.DELETE("/documents/:id", vendorH.DeleteDocument)
		}

		// ==================== Product routes ====================
		productRoutes := v1.Group("/products")
		productRoutes.Use(authMW.Authenticate())
		{
			productRoutes.POST("/", productH.Create)
			productRoutes.PUT("/:id", productH.Update)
			productRoutes.DELETE("/:id", productH.Delete)
			productRoutes.POST("/:id/reviews", productH.AddReview)
		}

		// ==================== Order routes ====================
		orderRoutes := v1.Group("/orders")
		orderRoutes.Use(authMW.Authenticate())
		{
			orderRoutes.POST("/", orderH.PlaceOrder)
			orderRoutes.GET("/", orderH.ListMyOrders)
			orderRoutes.GET("/:id", orderH.Get)
			orderRoutes.POST("/:id/cancel", orderH.CancelOrder)
			orderRoutes.GET("/:id/track", orderH.TrackOrder)
			orderRoutes.POST("/:id/return", orderH.SubmitReturnRequest)
			orderRoutes.GET("/:id/invoice", invoiceH.GetOrderInvoice)
		}

		// ==================== Cart routes ====================
		cartRoutes := v1.Group("/cart")
		cartRoutes.Use(authMW.Authenticate())
		{
			cartRoutes.GET("/", cartH.GetCart)
			cartRoutes.POST("/items", cartH.AddItem)
			cartRoutes.PUT("/items/:item_id", cartH.UpdateQuantity)
			cartRoutes.DELETE("/items/:item_id", cartH.RemoveItem)
			cartRoutes.DELETE("/", cartH.ClearCart)
		}

		// ==================== Wishlist routes ====================
		wishlistRoutes := v1.Group("/wishlist")
		wishlistRoutes.Use(authMW.Authenticate())
		{
			wishlistRoutes.GET("/", wishlistH.GetAll)
			wishlistRoutes.POST("/", wishlistH.Add)
			wishlistRoutes.DELETE("/:product_id", wishlistH.Remove)
			wishlistRoutes.GET("/:product_id/check", wishlistH.Check)
		}

		// ==================== Payment routes ====================
		paymentRoutes := v1.Group("/payments")
		paymentRoutes.Use(authMW.Authenticate())
		{
			paymentRoutes.POST("/initiate", rateLimiter.RateLimit(10, time.Minute, middleware.RateLimitByUser), paymentH.InitiatePayment)
			paymentRoutes.POST("/verify", paymentH.VerifyPayment)
			paymentRoutes.GET("/:order_id/status", paymentH.GetPaymentStatus)
		}
		v1.POST("/payments/webhook/:gateway", paymentH.PaymentWebhook)

		// ==================== Wallet routes ====================
		walletRoutes := v1.Group("/wallet")
		walletRoutes.Use(authMW.Authenticate())
		{
			walletRoutes.GET("/", walletH.GetBalance)
			walletRoutes.GET("/transactions", walletH.GetTransactions)
			walletRoutes.POST("/withdrawals", walletH.RequestWithdrawal)
			walletRoutes.GET("/withdrawals", walletH.ListWithdrawals)
		}

		// ==================== Coupon routes ====================
		couponRoutes := v1.Group("/coupons")
		couponRoutes.Use(authMW.Authenticate())
		{
			couponRoutes.POST("/validate", couponH.Validate)
		}

		// ==================== KYC routes ====================
		kycRoutes := v1.Group("/kyc")
		kycRoutes.Use(authMW.Authenticate())
		{
			kycRoutes.POST("/", kycH.SubmitKYC)
			kycRoutes.GET("/", kycH.GetMyKYC)
		}

		// ==================== Notification routes ====================
		notifRoutes := v1.Group("")
		notifRoutes.Use(authMW.Authenticate())
		{
			notifRoutes.GET("/notifications", notifSvc.GetUserNotifications)
			notifRoutes.PUT("/notifications/:id/read", notifSvc.MarkAsRead)
			notifRoutes.PUT("/notifications/read-all", notifSvc.MarkAllAsRead)
			notifRoutes.POST("/devices", notifSvc.RegisterDeviceToken)
			notifRoutes.DELETE("/devices/:token", notifSvc.UnregisterDeviceToken)
		}

		// ==================== Admin routes ====================
		adminRoutes := v1.Group("/admin")
		adminRoutes.Use(authMW.Authenticate())
		adminRoutes.Use(authMW.RequireRole(string(models.RoleAdmin), string(models.RoleSuperAdmin)))
		adminRoutes.Use(rateLimiter.RateLimit(60, time.Minute, middleware.RateLimitByUser))
		{
			// Dashboard
			adminRoutes.GET("/dashboard", adminH.GetDashboard)
			adminRoutes.GET("/analytics/revenue", adminH.GetRevenueAnalytics)
			adminRoutes.GET("/system/health", adminH.GetSystemHealth)
			adminRoutes.GET("/audit-logs", adminH.GetAuditLogs)

			// User management (Legacy, keep if used elsewhere)
			adminRoutes.GET("/users", authH.ListUsers)
			adminRoutes.GET("/users/:id", authH.GetUser)
			adminRoutes.PUT("/users/:id/status", authH.UpdateUserStatus)

			// Customer management
			adminRoutes.GET("/customers", adminCustomerH.ListCustomers)
			adminRoutes.GET("/customers/:id", adminCustomerH.GetCustomerDetails)
			adminRoutes.PUT("/customers/:id/block", adminCustomerH.BlockCustomer)
			adminRoutes.PUT("/customers/:id/unblock", adminCustomerH.UnblockCustomer)
			adminRoutes.PUT("/customers/:id/delete", adminCustomerH.DeleteCustomer)

			// Barber management
			adminRoutes.GET("/barbers", adminH.ListBarbers)
			adminRoutes.GET("/barbers/:id", adminH.GetBarberDetails)
			adminRoutes.GET("/barbers/:id/status", adminH.GetBarberStatus)
			adminRoutes.PUT("/barbers/:id/approve", adminH.ApproveBarber)
			adminRoutes.PUT("/barbers/:id/reject", adminH.RejectBarber)
			adminRoutes.PUT("/barbers/:id/suspend", adminH.SuspendBarber)
			adminRoutes.PUT("/barbers/:id/activate", adminH.ActivateBarber)

			// Vendor management
			adminRoutes.GET("/vendors", adminH.ListVendors)
			adminRoutes.PUT("/vendors/:id/approve", adminH.ApproveVendor)

			// Product moderation
			adminRoutes.GET("/products", adminH.ListProducts)
			adminRoutes.PUT("/products/:id/approve", adminH.ApproveProduct)

			// Bookings
			adminRoutes.GET("/bookings", adminH.ListAllBookings)

			// Withdrawals
			adminRoutes.GET("/withdrawals", adminH.ListWithdrawals)
			adminRoutes.PUT("/withdrawals/:id/process", adminH.ProcessWithdrawal)

			// Refunds
			adminRoutes.GET("/refunds", adminH.ListRefunds)
			adminRoutes.PUT("/refunds/:id/process", adminH.ProcessRefund)

			// Disputes
			adminRoutes.GET("/disputes", adminH.ListDisputes)
			adminRoutes.PUT("/disputes/:id/resolve", adminH.ResolveDispute)

			// Categories
			adminRoutes.POST("/categories", adminH.CreateCategory)
			adminRoutes.PUT("/categories/:id", adminH.UpdateCategory)

			// Coupons
			adminRoutes.GET("/coupons", couponH.List)
			adminRoutes.POST("/coupons", couponH.Create)
			adminRoutes.PUT("/coupons/:id", couponH.Update)
			adminRoutes.DELETE("/coupons/:id", couponH.Delete)

			// Reviews
			adminRoutes.GET("/reviews", reviewH.ListAllReviews)
			adminRoutes.PUT("/reviews/:id/moderate", reviewH.Moderate)

			// Settings
			adminRoutes.GET("/settings", adminH.GetSettings)
			adminRoutes.PUT("/settings", adminH.UpdateSettings)
			adminRoutes.PUT("/commission", adminH.UpdateCommission)

			// Features
			adminRoutes.PUT("/features/toggle", adminH.ToggleFeature)

			// SubCategories
			adminRoutes.GET("/sub-categories", adminH.ListSubCategories)
			adminRoutes.POST("/sub-categories", adminH.CreateSubCategory)
			adminRoutes.PUT("/sub-categories/:id", adminH.UpdateSubCategory)
			adminRoutes.DELETE("/sub-categories/:id", adminH.DeleteSubCategory)

			// Tax Settings
			adminRoutes.GET("/tax-settings", adminH.ListTaxSettings)
			adminRoutes.POST("/tax-settings", adminH.CreateTaxSetting)
			adminRoutes.PUT("/tax-settings/:id", adminH.UpdateTaxSetting)
			adminRoutes.DELETE("/tax-settings/:id", adminH.DeleteTaxSetting)

			// Featured Listings
			adminRoutes.GET("/featured-listings", adminH.ListFeaturedListings)
			adminRoutes.POST("/featured-listings", adminH.CreateFeaturedListing)
			adminRoutes.DELETE("/featured-listings/:id", adminH.DeleteFeaturedListing)

			// Notification Templates
			adminRoutes.GET("/notification-templates", adminH.ListNotificationTemplates)
			adminRoutes.GET("/notification-templates/:id", adminH.GetNotificationTemplate)
			adminRoutes.POST("/notification-templates", adminH.CreateNotificationTemplate)
			adminRoutes.PUT("/notification-templates/:id", adminH.UpdateNotificationTemplate)
			adminRoutes.DELETE("/notification-templates/:id", adminH.DeleteNotificationTemplate)

			// KYC Document Verification
			adminRoutes.GET("/kyc-documents", adminH.ListKYCDocuments)
			adminRoutes.PUT("/kyc-documents/:id/verify", adminH.VerifyKYCDocument)

			// Barber Document Verification
			adminRoutes.GET("/barber-documents", adminH.ListBarberDocuments)
			adminRoutes.PUT("/barber-documents/:id/verify", adminH.VerifyBarberDocument)

			// Vendor Document Verification
			adminRoutes.GET("/vendor-documents", adminH.ListVendorDocuments)
			adminRoutes.PUT("/vendor-documents/:id/verify", adminH.VerifyVendorDocument)

			// Webhook Endpoints
			adminRoutes.GET("/webhooks", webhookH.List)
			adminRoutes.GET("/webhooks/:id", webhookH.Get)
			adminRoutes.POST("/webhooks", webhookH.Create)
			adminRoutes.PUT("/webhooks/:id", webhookH.Update)
			adminRoutes.DELETE("/webhooks/:id", webhookH.Delete)
			adminRoutes.GET("/webhooks/:id/logs", webhookH.GetLogs)

			// Analytics CSV Export
			adminRoutes.GET("/analytics/revenue/csv", searchH.ExportRevenueCSV)
			adminRoutes.GET("/analytics/users/csv", searchH.ExportUserGrowthCSV)
			adminRoutes.GET("/analytics/barbers/csv", searchH.ExportTopBarbersCSV)
		}
	}

	return router
}
