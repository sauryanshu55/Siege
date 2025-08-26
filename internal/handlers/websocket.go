package handlers

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type WebSocketHandler struct {
	db       *gorm.DB
	redis    *redis.Client
	upgrader websocket.Upgrader
}

// Create and return an instance of a new websocket handler to main.go
func NewWebSocketHandler(db *gorm.DB, redisClient *redis.Client) *WebSocketHandler {
	return &WebSocketHandler{
		db:    db,
		redis: redisClient,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				// TODO: Implement proper origin checking for production
				return true // Allow all origins for development
			},
		},
	}
}

// HandleWebSocket handles GET /api/v1/ws
func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
	// Upgrade HTTP connection to WebSocket
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade to WebSocket: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Failed to upgrade to WebSocket",
		})
		return
	}
	defer conn.Close()

	log.Printf("New WebSocket connection established")

	// Send welcome message
	err = conn.WriteJSON(map[string]interface{}{
		"type":    "welcome",
		"message": "Connected to Siege Game WebSocket",
		"status":  "success",
	})
	if err != nil {
		log.Printf("Error sending welcome message: %v", err)
		return
	}

	// Simple message loop for testing
	for {
		// Read message from client
		var message map[string]interface{}
		err := conn.ReadJSON(&message)
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		log.Printf("Received WebSocket message: %+v", message)

		// Echo message back for testing
		response := map[string]interface{}{
			"type":             "echo",
			"original_message": message,
			"timestamp":        time.Now().Unix(),
			"status":           "success",
		}

		err = conn.WriteJSON(response)
		if err != nil {
			log.Printf("Error sending WebSocket message: %v", err)
			break
		}
	}

	log.Printf("WebSocket connection closed")
}
