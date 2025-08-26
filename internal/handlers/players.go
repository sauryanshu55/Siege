package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type PlayerHandler struct {
	db    *gorm.DB
	redis *redis.Client
}

// Create and return an instance of a new player handler to main.go
func NewPlayerHandler(db *gorm.DB, redisClient *redis.Client) *PlayerHandler {
	return &PlayerHandler{
		db:    db,
		redis: redisClient,
	}
}

// CreatePlayer , POST /api/v1/players
func (h *PlayerHandler) CreatePlayer(c *gin.Context) {
	// TODO: Implement player creation logic
	c.JSON(http.StatusOK, gin.H{
		"message": "Create player endpoint - TODO: implement",
		"status":  "success",
	})
}

// GetPlayer , GET /api/v1/players/:id
func (h *PlayerHandler) GetPlayer(c *gin.Context) {
	playerID := c.Param("id")

	// TODO: Implement logic
	c.JSON(http.StatusOK, gin.H{
		"message":   "Get player endpoint - TODO: implement",
		"player_id": playerID,
		"status":    "success",
	})
}

// JoinGame , POST /api/v1/players/:id/join/:gameId
func (h *PlayerHandler) JoinGame(c *gin.Context) {
	playerID := c.Param("id")
	gameID := c.Param("gameId")

	// TODO: Implement join game logic
	c.JSON(http.StatusOK, gin.H{
		"message":   "Join game endpoint - TODO: implement",
		"player_id": playerID,
		"game_id":   gameID,
		"status":    "success",
	})
}
