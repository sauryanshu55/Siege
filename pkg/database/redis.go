package database

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"

	"github.com/sauryanshu55/Siege/internal/config"
)

var redisClient *redis.Client

// Initialize connection to Redis
func InitRedis(cfg config.RedisConfig) (*redis.Client, error) {
	redisClient = redis.NewClient(&redis.Options{
		Addr:     cfg.GetRedisAddress(),
		Password: cfg.Password,
		DB:       cfg.DB,
		PoolSize: cfg.MaxConnections,
	})

	// Test connection
	ctx := context.Background()
	_, err := redisClient.Ping(ctx).Result()
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	return redisClient, nil
}

func GetRedis() *redis.Client {
	return redisClient
}

func CloseRedis() error {
	if redisClient == nil {
		return nil
	}
	return redisClient.Close()
}
