-- Ensure the database exists 
SELECT 'CREATE DATABASE siege_game' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'siege_game');

-- Connect to database
\c siege_game;

-- Create extensions, if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE IF team_type AS ENUM ('red', 'black');
CREATE TYPE game_status AS ENUM ('waiting', 'active', 'completed');

-- Create players table
CREATE TABLE IF NOT EXISTS players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    team team_type,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_move_time TIMESTAMP WITH TIME ZONE,
    total_moves INTEGER DEFAULT 0,
);

-- Create games table
CREATE TABLE IF NOT EXISTS games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grid_state TEXT NOT NULL DEFAULT '',
    status game_status DEFAULT 'waiting',
    winner team_type,
    red_team_count INTEGER DEFAULT 0,
    black_team_count INTEGER DEFAULT 0,
    total_moves INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Create moves table
CREATE TABLE IF NOT EXISTS moves (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    x_coordinate INTEGER NOT NULL CHECK (x_coordinate >= 0 AND x_coordinate < 100),
    y_coordinate INTEGER NOT NULL CHECK (y_coordinate >= 0 AND y_coordinate < 100),
    team team_type NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_players_username ON players(username);
CREATE INDEX IF NOT EXISTS idx_players_team ON players(team);
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_games_created_at ON games(created_at);
CREATE INDEX IF NOT EXISTS idx_moves_game_id ON moves(game_id);
CREATE INDEX IF NOT EXISTS idx_moves_player_id ON moves(player_id);
CREATE INDEX IF NOT EXISTS idx_moves_timestamp ON moves(timestamp);
CREATE INDEX IF NOT EXISTS idx_moves_coordinates ON moves(x_coordinate, y_coordinate);

-- Create unique constraint to prevent duplicate moves on same cell in same game
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_game_coordinates 
    ON moves(game_id, x_coordinate, y_coordinate);

-- Insert a default game for testing
INSERT INTO games (grid_state, status) 
VALUES ('', 'waiting') 
ON CONFLICT DO NOTHING;

-- Create a function to get the current active game (or create one if none exists)
CREATE OR REPLACE FUNCTION get_or_create_active_game()
RETURNS UUID AS $$
DECLARE
    active_game_id UUID;
BEGIN
    -- Try to find an active game
    SELECT id INTO active_game_id 
    FROM games 
    WHERE status IN ('waiting', 'active') 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    -- If no active game exists, create one
    IF active_game_id IS NULL THEN
        INSERT INTO games (grid_state, status) 
        VALUES ('', 'waiting') 
        RETURNING id INTO active_game_id;
    END IF;
    
    RETURN active_game_id;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO siege_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO siege_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO siege_user;