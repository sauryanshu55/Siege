package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type GameHandler struct {
	db    *gorm.DB
	redis *redis.Client
}

// Create and return an instance of a new GameHandler to main.go
func NewGameHandler(db *gorm.DB, redisClient *redis.Client) *GameHandler {
	return &GameHandler{
		db:    db,
		redis: redisClient,
	}
}

// CreateGame, POST /api/v1/games
func (h *GameHandler) CreateGame(c *gin.Context) {
	// TODO: Implement game creation
	c.JSON(http.StatusOK, gin.H{
		"message": "Create game endpoint - TODO: implement",
		"status":  "success",
	})
}

// GetGame, GET /api/v1/games/:id
func (h *GameHandler) GetGame(c *gin.Context) {
	gameID := c.Param("id")

	// TODO: Implement get game
	c.JSON(http.StatusOK, gin.H{
		"message": "Get game endpoint - TODO: implement",
		"game_id": gameID,
		"status":  "success",
	})
}

// GetGameState, GET /api/v1/games/:id/state
func (h *GameHandler) GetGameState(c *gin.Context) {
	gameID := c.Param("id")

	// TODO: Implement get game state logic
	c.JSON(http.StatusOK, gin.H{
		"message": "Get game state endpoint - TODO: implement",
		"game_id": gameID,
		"status":  "success",
	})
}

// MakeMove , POST /api/v1/games/:gameId/moves
func (h *GameHandler) MakeMove(c *gin.Context) {
	gameID := c.Param("gameId")

	// TODO: Implement make move logic
	c.JSON(http.StatusOK, gin.H{
		"message": "Make move endpoint - TODO: implement",
		"game_id": gameID,
		"status":  "success",
	})
}
