package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	"github.com/sauryanshu55/Siege/internal/config"
	"github.com/sauryanshu55/Siege/internal/handlers"
	"github.com/sauryanshu55/Siege/internal/middleware"
	"github.com/sauryanshu55/Siege/pkg/database"
)

func main() {

	// Load configuration from config/config.go
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Set Gin mode
	gin.SetMode(cfg.Server.Mode)

	// Initialize database connections
	db, err := database.InitPostgres(cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.ClosePostgres() // Close Postgres connection once main function exits

	redisClient, err := database.InitRedis(cfg.Redis)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer database.CloseRedis() // Close Redis connection once main function exits

	// Initialize HTTP router
	router := setupRouter(cfg, db, redisClient)

	// Create HTTP server
	server := &http.Server{
		Addr:    fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port),
		Handler: router,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Server starting on %s:%s", cfg.Server.Host, cfg.Server.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit // block main goroutine until signal recieved
	log.Println("Shutting down server...")

	// graceful shutdown after 10s
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second) //pass 10s for shutdown
	defer cancel()                                                           //call cancel() and unblock if shutdown completes before timeout

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

// Setup HTTP router
func setupRouter(cfg *config.Config, db *gorm.DB, redisClient *redis.Client) *gin.Engine {
	router := gin.New()

	// Add middleware
	router.Use(middleware.Logger())
	router.Use(middleware.Recovery())
	router.Use(middleware.CORS(cfg.Server.CORSOrigins))

	// Server Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"timestamp": time.Now().Unix(),
		})
	})

	// API routes
	v1 := router.Group("/api/v1")
	{
		// Initialize handlers
		gameHandler := handlers.NewGameHandler(db, redisClient)
		playerHandler := handlers.NewPlayerHandler(db, redisClient)
		wsHandler := handlers.NewWebSocketHandler(db, redisClient)

		// Game routes
		v1.POST("/games", gameHandler.CreateGame)
		v1.GET("/games/:id", gameHandler.GetGame)
		v1.GET("/games/:id/state", gameHandler.GetGameState)

		// Player routes
		v1.POST("/players", playerHandler.CreatePlayer)
		v1.GET("/players/:id", playerHandler.GetPlayer)
		v1.POST("/players/:id/join/:gameId", playerHandler.JoinGame)

		// Move routes
		v1.POST("/games/:gameId/moves", gameHandler.MakeMove)

		// WebSocket endpoint
		v1.GET("/ws", wsHandler.HandleWebSocket)
	}

	return router
}
