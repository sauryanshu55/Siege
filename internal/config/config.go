package config

import (
	"fmt"
	"log"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

type Config struct {
	Server      ServerConfig    `mapstructure:"server"`
	Database    DatabaseConfig  `mapstructure:"database"`
	Redis       RedisConfig     `mapstructure:"redis"`
	Game        GameConfig      `mapstructure:"game"`
	WebSocket   WebSocketConfig `mapstructure:"websocket"`
	Logging     LoggingConfig   `mapstructure:"logging"`
	Environment string          `mapstructure:"environment"`
}

type ServerConfig struct {
	Port        string `mapstructure:"port"`
	Host        string `mapstructure:"host"`
	Mode        string `mapstructure:"mode"`
	CORSOrigins string `mapstructure:"cors_origins"`
}

type DatabaseConfig struct {
	Host           string `mapstructure:"host"`
	Port           string `mapstructure:"port"`
	Name           string `mapstructure:"name"`
	User           string `mapstructure:"user"`
	Password       string `mapstructure:"password"`
	SSLMode        string `mapstructure:"ssl_mode"`
	MaxConnections int    `mapstructure:"max_connections"`
	MaxIdle        int    `mapstructure:"max_idle_connections"`
}

type RedisConfig struct {
	Host           string `mapstructure:"host"`
	Port           string `mapstructure:"port"`
	Password       string `mapstructure:"password"`
	DB             int    `mapstructure:"db"`
	MaxConnections int    `mapstructure:"max_connections"`
}

type GameConfig struct {
	GridSize              int `mapstructure:"grid_size"`
	PlayerCooldownSeconds int `mapstructure:"player_cooldown_seconds"`
	MaxConcurrentPlayers  int `mapstructure:"max_concurrent_players"`
}

type WebSocketConfig struct {
	ReadBufferSize  int  `mapstructure:"read_buffer_size"`
	WriteBufferSize int  `mapstructure:"write_buffer_size"`
	CheckOrigin     bool `mapstructure:"check_origin"`
}

type LoggingConfig struct {
	Level  string `mapstructure:"level"`
	Format string `mapstructure:"format"`
}

func Load() (*Config, error) {
	// load .env.development
	if err := godotenv.Load(".env.development"); err != nil {
		if err := godotenv.Load(".env"); err != nil {
			log.Println("No .env file found, using system environment variables")
		}
	}
	viper.AutomaticEnv()

	// database mappings from .env.development
	viper.BindEnv("database.host", "DB_HOST")
	viper.BindEnv("database.port", "DB_PORT")
	viper.BindEnv("database.name", "DB_NAME")
	viper.BindEnv("database.user", "DB_USER")
	viper.BindEnv("database.password", "DB_PASSWORD")
	viper.BindEnv("database.ssl_mode", "DB_SSL_MODE")
	viper.BindEnv("database.max_connections", "DB_MAX_CONNECTIONS")
	viper.BindEnv("database.max_idle_connections", "DB_MAX_IDLE_CONNECTIONS")

	// Redis mappings
	viper.BindEnv("redis.host", "REDIS_HOST")
	viper.BindEnv("redis.port", "REDIS_PORT")
	viper.BindEnv("redis.password", "REDIS_PASSWORD")
	viper.BindEnv("redis.db", "REDIS_DB")
	viper.BindEnv("redis.max_connections", "REDIS_MAX_CONNECTIONS")

	// Server mappings
	viper.BindEnv("server.port", "SERVER_PORT")
	viper.BindEnv("server.host", "SERVER_HOST")
	viper.BindEnv("server.mode", "SERVER_MODE")
	viper.BindEnv("server.cors_origins", "CORS_ORIGINS")

	// WebSocket mappings
	viper.BindEnv("websocket.read_buffer_size", "WS_READ_BUFFER_SIZE")
	viper.BindEnv("websocket.write_buffer_size", "WS_WRITE_BUFFER_SIZE")
	viper.BindEnv("websocket.check_origin", "WS_CHECK_ORIGIN")

	// Game mappings
	viper.BindEnv("game.grid_size", "GRID_SIZE")
	viper.BindEnv("game.player_cooldown_seconds", "PLAYER_COOLDOWN_SECONDS")
	viper.BindEnv("game.max_concurrent_players", "MAX_CONCURRENT_PLAYERS")

	// Logging mappings
	viper.BindEnv("logging.level", "LOG_LEVEL")
	viper.BindEnv("logging.format", "LOG_FORMAT")

	// Environment mapping
	viper.BindEnv("environment", "ENVIRONMENT")

	// set defaults
	setDefaults()

	// unmarshal into config struct
	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &config, nil
}

func setDefaults() {
	// Server defaults
	viper.SetDefault("server.port", "8080")
	viper.SetDefault("server.host", "localhost")
	viper.SetDefault("server.mode", "development")
	viper.SetDefault("server.cors_origins", "http://localhost:4200")

	// Database defaults
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "5432")
	viper.SetDefault("database.name", "siege_game")
	viper.SetDefault("database.user", "siege_user")
	viper.SetDefault("database.password", "siege_password")
	viper.SetDefault("database.ssl_mode", "disable")
	viper.SetDefault("database.max_connections", 20)
	viper.SetDefault("database.max_idle_connections", 5)

	// Redis defaults
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", "6379")
	viper.SetDefault("redis.password", "")
	viper.SetDefault("redis.db", 0)
	viper.SetDefault("redis.max_connections", 10)

	// WebSocket defaults
	viper.SetDefault("websocket.read_buffer_size", 1024)
	viper.SetDefault("websocket.write_buffer_size", 1024)
	viper.SetDefault("websocket.check_origin", false)

	// Game defaults
	viper.SetDefault("game.grid_size", 100)
	viper.SetDefault("game.player_cooldown_seconds", 5)
	viper.SetDefault("game.max_concurrent_players", 1000)

	// Logging defaults
	viper.SetDefault("logging.level", "debug")
	viper.SetDefault("logging.format", "json")

	// Environment default
	viper.SetDefault("environment", "development")
}

// GetDatabaseConnectionString returns a PostgreSQL connection string
func (c *DatabaseConfig) GetDatabaseConnectionString() string {
	return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		c.Host, c.Port, c.User, c.Password, c.Name, c.SSLMode)
}

// GetRedisAddress returns Redis address in host:port format
func (c *RedisConfig) GetRedisAddress() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}

// GetServerAddress returns server address in host:port format
func (c *ServerConfig) GetServerAddress() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}

// IsProduction returns true if running in production mode
func (c *Config) IsProduction() bool {
	return c.Environment == "production"
}

// IsDevelopment returns true if running in development mode
func (c *Config) IsDevelopment() bool {
	return c.Environment == "development"
}
