package models

import (
	"time"

	"github.com/google/uuid"
)

type Move struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	GameID      uuid.UUID `json:"game_id" gorm:"not null;index"`
	PlayerID    uuid.UUID `json:"player_id" gorm:"not null;index"`
	XCoordinate int       `json:"x" gorm:"not null;check:x_coordinate >= 0 AND x_coordinate < 100"`
	YCoordinate int       `json:"y" gorm:"not null;check:y_coordinate >= 0 AND y_coordinate < 100"`
	Team        Team      `json:"team" gorm:"type:team_type;not null"`
	Timestamp   time.Time `json:"timestamp"`

	// Relations
	Game   Game   `json:"game" gorm:"foreignKey:GameID"`
	Player Player `json:"player" gorm:"foreignKey:PlayerID"`
}

type MoveRequest struct {
	X int `json:"x" validate:"required,min=0,max=99"`
	Y int `json:"y" validate:"required,min=0,max=99"`
}

func (m *Move) IsValid(gridSize int) bool {
	return m.XCoordinate >= 0 && m.XCoordinate < gridSize &&
		m.YCoordinate >= 0 && m.YCoordinate < gridSize
}
