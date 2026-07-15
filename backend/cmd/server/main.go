package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"syscall"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/firebase"
	"github.com/barbar-app/backend/internal/routes"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/barbar-app/backend/internal/websocket"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile | log.Lmicroseconds)
	log.Println("Starting Barbar App Backend Server v1.0.0...")
	log.Printf("Go Version: %s, CPUs: %d", runtime.Version(), runtime.NumCPU())

	// Load configuration
	cfg := config.Load()

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

	// Setup Router
	router := routes.SetupRouter(db, cfg, jwtManager, hub)

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
