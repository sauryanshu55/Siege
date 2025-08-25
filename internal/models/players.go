package models

import (
	"time"

	"github.com/google/uuid"
)

type Team string

const (
	TeamRed   Team = "red"
	TeamBlack Team = "black"
)

type Player struct {
	ID           uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Username     string     `json:"username" gorm:"unique;not null" validate:"required,min=3,max=50"`
	Team         *Team      `json:"team" gorm:"type:team_type"`
	CreatedAt    time.Time  `json:"created_at"`
	LastMoveTime *time.Time `json:"last_move_time"`
	TotalMoves   int        `json:"total_moves" gorm:"default:0"`
}

func (p *Player) CanMakeMove(cooldownSeconds int) bool {
	if p.LastMoveTime == nil {
		return true
	}
	return time.Since(*p.LastMoveTime) >= time.Duration(cooldownSeconds)*time.Second
}

func (p *Player) IsOnTeam() bool {
	return p.Team != nil
}
