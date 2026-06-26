package database

import (
	"context"
	"fmt"
	"log"

	"github.com/barbar-app/backend/internal/config"
	"github.com/go-redis/redis/v8"
)

var RedisClient *redis.Client

func InitRedis(cfg *config.RedisConfig) *redis.Client {
	client := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", cfg.Host, cfg.Port),
		Password: cfg.Password,
		DB:       cfg.DB,
	})

	ctx := context.Background()
	_, err := client.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}

	RedisClient = client
	log.Println("Redis connected successfully")
	return client
}
