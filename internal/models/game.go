package models

import (
	"time"

	"github.com/google/uuid"
)

type GameStatus string

const (
	GameStatusWaiting   GameStatus = "waiting"   // refers to games created, that have no players yet
	GameStatusActive    GameStatus = "active"    // have active players
	GameStatusCompleted GameStatus = "completed" // game is finished
)

type Game struct {
	ID             uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	GridState      string     `json:"grid_state" gorm:"not null;default:''"`
	Status         GameStatus `json:"status" gorm:"type:game_status;default:'waiting'"`
	Winner         *Team      `json:"winner" gorm:"type:team_type"`
	RedTeamCount   int        `json:"red_team_count" gorm:"default:0"`
	BlackTeamCount int        `json:"black_team_count" gorm:"default:0"`
	TotalMoves     int        `json:"total_moves" gorm:"default:0"`
	CreatedAt      time.Time  `json:"created_at"`
	StartedAt      *time.Time `json:"started_at"`
	CompletedAt    *time.Time `json:"completed_at"`
}

type GameState struct {
	Game    Game     `json:"game"`
	Grid    [][]Team `json:"grid"`
	Players []Player `json:"players"`
}

func NewGame(gridSize int) *Game {
	return &Game{
		GridState: initializeEmptyGrid(gridSize),
		Status:    GameStatusWaiting,
	}
}

func initializeEmptyGrid(size int) string {
	// Initialize empty grid as string representation
	// For now, empty string - will be implemented in game logic
	return ""
}
