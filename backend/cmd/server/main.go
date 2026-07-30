package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/firebase"
	"github.com/barbar-app/backend/internal/routes"
	"github.com/barbar-app/backend/internal/services/encryption"
	deliverySvc "github.com/barbar-app/backend/internal/services/delivery"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	orderService "github.com/barbar-app/backend/internal/services/order"
	queueService "github.com/barbar-app/backend/internal/services/queue"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
	"github.com/google/uuid"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile | log.Lmicroseconds)
	log.Println("Starting Barbar App Backend Server v1.0.0...")
	log.Printf("Go Version: %s, CPUs: %d", runtime.Version(), runtime.NumCPU())

	// Load configuration
	cfg := config.Load()
	if err := cfg.Validate(); err != nil {
		log.Fatalf("Config validation failed: %v", err)
	}

	// Initialize encryption
	if err := encryption.Init(); err != nil {
		log.Fatalf("Encryption init failed: %v", err)
	}

	// Initialize Firebase Admin SDK
	firebase.InitFirebase("firebase-service-account.json")

	// Initialize database
	db := database.InitPostgres(&cfg.Database)
	database.RunMigrations(db)
	database.SeedData(db, &cfg.App)

	// Initialize Redis
	rdb := database.InitRedis(&cfg.Redis)

	// Initialize cache service
	utils.NewCacheService(rdb)

	// Initialize worker pool for async jobs (notifications, emails, webhooks)
	utils.NewWorkerPool(runtime.NumCPU()*2, 1000)
	log.Printf("Worker pool initialized with %d workers", runtime.NumCPU()*2)

	// Setup cleanup
	defer utils.DefaultPool.Shutdown()

	// Initialize JWT Manager
	jwtManager := auth.NewJWTManager(&cfg.JWT)

	// Initialize WebSocket Hub
	hub := websocket.NewHub(cfg, jwtManager)
	go hub.Run()

	// Initialize notification and order services
	notifSvc := notifService.NewNotificationService(db, hub)
	tmplSvc := notifService.NewTemplateService(db)
	dispatcher := notifService.NewDispatcher(db, hub, tmplSvc)
	presenceSvc := deliverySvc.NewPresenceService(db, hub)
	orderSvc := orderService.NewOrderService(db, dispatcher, hub, presenceSvc)

	// Set WebSocket room authorization
	hub.AuthorizeRoom = func(userID uuid.UUID, role, room string) bool {
		if strings.HasPrefix(room, "barber:") {
			barberID := strings.TrimPrefix(room, "barber:")
			if role == "admin" || role == "super_admin" {
				return true
			}
			if role == "customer" {
				return true
			}
			return userID.String() == barberID
		}
		if strings.HasPrefix(room, "order:") {
			orderIDStr := strings.TrimPrefix(room, "order:")
			orderID, err := uuid.Parse(orderIDStr)
			if err != nil {
				return false
			}
			order, err := orderSvc.GetOrderByID(context.Background(), orderID)
			if err != nil || order == nil {
				return false
			}
			if role == "admin" || role == "super_admin" {
				return true
			}
			if userID == order.CustomerID {
				return true
			}
			if userID == order.VendorID {
				return true
			}
			if order.DeliveryPartnerID != nil && userID == *order.DeliveryPartnerID {
				return true
			}
			return false
		}
		if strings.HasPrefix(room, "user:") {
			roomUserID := strings.TrimPrefix(room, "user:")
			return userID.String() == roomUserID
		}
		return true
	}

	// Start order assignment expiry worker
	orderSvc.StartAssignmentWorker(context.Background())

	// Start stale presence cleanup
	presenceSvc.StartStalePresenceCleanup(context.Background())

	// Initialize and start BookingScheduler (queue assign + late + no-show)
	queueSvc := queueService.NewQueueService(db, hub, dispatcher)
	bookingScheduler := queueService.NewBookingScheduler(queueSvc, 30*time.Second, 15, 30)
	bookingScheduler.Start(context.Background())

	// Setup Router
	router := routes.SetupRouter(db, cfg, jwtManager, hub, notifSvc, dispatcher, orderSvc, presenceSvc)

	// Create HTTP Server with optimized settings
	srv := &http.Server{
		Addr:             ":" + cfg.Server.Port,
		Handler:          router,
		ReadTimeout:      10 * time.Second,
		ReadHeaderTimeout: 5 * time.Second,
		WriteTimeout:     30 * time.Second,
		IdleTimeout:      120 * time.Second,
		MaxHeaderBytes:   1 << 20,
	}

	// Graceful shutdown
	go func() {
		log.Printf("Server listening on :%s", cfg.Server.Port)
		log.Printf("API Base: http://localhost:%s/api/v1", cfg.Server.Port)
		log.Printf("WebSocket: ws://localhost:%s/ws", cfg.Server.Port)
		log.Printf("Health: http://localhost:%s/health", cfg.Server.Port)

		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)
	sig := <-quit

	log.Printf("Received signal: %v. Shutting down gracefully...", sig)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced shutdown: %v", err)
	}

	log.Println("Server exited gracefully")
}
