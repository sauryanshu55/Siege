package utils

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/sauryanshu55/Siege/internal/config"
)

func test() {
	fmt.Println("Testing Go Configuration file")
	fmt.Println("================================")

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	fmt.Println("Configuration loaded successfully!")
	fmt.Println()

	fmt.Println("  Server Configuration:")
	fmt.Printf("   Address: %s\n", cfg.Server.GetServerAddress())
	fmt.Printf("   Mode: %s\n", cfg.Server.Mode)
	fmt.Printf("   CORS Origins: %s\n", cfg.Server.CORSOrigins)
	fmt.Println()

	fmt.Println("  Database Configuration:")
	fmt.Printf("   Connection: %s\n", cfg.Database.GetDatabaseConnectionString())
	fmt.Printf("   Max Connections: %d\n", cfg.Database.MaxConnections)
	fmt.Printf("   Max Idle: %d\n", cfg.Database.MaxIdle)
	fmt.Println()

	fmt.Println("  Redis Configuration:")
	fmt.Printf("   Address: %s\n", cfg.Redis.GetRedisAddress())
	fmt.Printf("   Database: %d\n", cfg.Redis.DB)
	fmt.Printf("   Max Connections: %d\n", cfg.Redis.MaxConnections)
	fmt.Printf("   Password: %s\n", func() string {
		if cfg.Redis.Password == "" {
			return "(none)"
		}
		return "(set)"
	}())
	fmt.Println()

	fmt.Println("  Game Configuration:")
	fmt.Printf("   Grid Size: %dx%d\n", cfg.Game.GridSize, cfg.Game.GridSize)
	fmt.Printf("   Player Cooldown: %d seconds\n", cfg.Game.PlayerCooldownSeconds)
	fmt.Printf("   Max Players: %d\n", cfg.Game.MaxConcurrentPlayers)
	fmt.Println()

	fmt.Println("  WebSocket Configuration:")
	fmt.Printf("   Read Buffer: %d bytes\n", cfg.WebSocket.ReadBufferSize)
	fmt.Printf("   Write Buffer: %d bytes\n", cfg.WebSocket.WriteBufferSize)
	fmt.Printf("   Check Origin: %t\n", cfg.WebSocket.CheckOrigin)
	fmt.Println()

	fmt.Println("  Logging Configuration:")
	fmt.Printf("   Level: %s\n", cfg.Logging.Level)
	fmt.Printf("   Format: %s\n", cfg.Logging.Format)
	fmt.Println()

	// Test Environment
	fmt.Println("  Environment:")
	fmt.Printf("   Environment: %s\n", cfg.Environment)
	fmt.Printf("   Is Development: %t\n", cfg.IsDevelopment())
	fmt.Printf("   Is Production: %t\n", cfg.IsProduction())
	fmt.Println()

	fmt.Println("Complete Configuration (JSON):")
	jsonData, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		log.Printf("Error marshaling config to JSON: %v", err)
	} else {
		fmt.Println(string(jsonData))
	}

	fmt.Println()
	fmt.Println("All configuration tests completed")
}
