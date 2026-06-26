package utils

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
)

var Cache *CacheService

type CacheService struct {
	client *redis.Client
}

func NewCacheService(client *redis.Client) *CacheService {
	Cache = &CacheService{client: client}
	return Cache
}

func (c *CacheService) Get(ctx context.Context, key string, dest interface{}) error {
	val, err := c.client.Get(ctx, key).Bytes()
	if err != nil {
		return err
	}
	return json.Unmarshal(val, dest)
}

func (c *CacheService) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	if ttl < time.Second {
		ttl = time.Second
	}
	return c.client.Set(ctx, key, data, ttl).Err()
}

func (c *CacheService) Delete(ctx context.Context, keys ...string) error {
	return c.client.Del(ctx, keys...).Err()
}

func (c *CacheService) ClearPattern(ctx context.Context, pattern string) error {
	iter := c.client.Scan(ctx, 0, pattern, 0).Iterator()
	var keys []string
	for iter.Next(ctx) {
		keys = append(keys, iter.Val())
	}
	if err := iter.Err(); err != nil {
		return err
	}
	if len(keys) > 0 {
		return c.client.Del(ctx, keys...).Err()
	}
	return nil
}

func CacheKey(parts ...string) string {
	return fmt.Sprintf("barbar:%s", joinStrings(parts, ":"))
}

func joinStrings(strs []string, sep string) string {
	result := ""
	for i, s := range strs {
		if i > 0 {
			result += sep
		}
		result += s
	}
	return result
}

func CacheBarber(id string) string    { return CacheKey("barber", id) }
func CacheBarbers(city string) string { return CacheKey("barbers", city) }
func CacheProduct(id string) string   { return CacheKey("product", id) }
func CacheCategory(id string) string  { return CacheKey("category", id) }
func CacheVendor(id string) string    { return CacheKey("vendor", id) }
func CacheSettings() string           { return CacheKey("settings") }
