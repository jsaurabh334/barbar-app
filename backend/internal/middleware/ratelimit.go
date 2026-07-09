package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
)

var rateLimitScript = redis.NewScript(`
	local count = redis.call('INCR', KEYS[1])
	if count == 1 then
		redis.call('PEXPIRE', KEYS[1], ARGV[1])
	end
	return count
`)

type RateLimiter struct {
	client *redis.Client
}

func NewRateLimiter(client *redis.Client) *RateLimiter {
	return &RateLimiter{client: client}
}

func (rl *RateLimiter) RateLimit(limit int, window time.Duration, keyFn func(*gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if gin.Mode() == gin.TestMode {
			c.Next()
			return
		}
		key := fmt.Sprintf("rate:%s:%s", keyFn(c), c.FullPath())

		count, err := rateLimitScript.Run(c, rl.client, []string{key}, window.Milliseconds()).Int()
		if err != nil {
			c.Next()
			return
		}

		remaining := limit - int(count)
		if remaining < 0 {
			remaining = 0
		}

		c.Header("X-RateLimit-Limit", strconv.Itoa(limit))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(remaining))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(window).Unix(), 10))

		if count > limit {
			utils.ErrorResponse(c, http.StatusTooManyRequests, "Rate limit exceeded. Try again later")
			c.Abort()
			return
		}

		c.Next()
	}
}

func RateLimitByIP(c *gin.Context) string {
	return "ip:" + c.ClientIP()
}

func RateLimitByUser(c *gin.Context) string {
	userID, exists := c.Get("user")
	if !exists {
		return "ip:" + c.ClientIP()
	}
	return "user:" + userID.(uuid.UUID).String()
}
