package middleware

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
)

type cachedResponse struct {
	Status int             `json:"s"`
	Body   json.RawMessage `json:"b"`
}

type cacheWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (w *cacheWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

func (w *cacheWriter) WriteString(s string) (int, error) {
	w.body.WriteString(s)
	return w.ResponseWriter.WriteString(s)
}

func cacheKey(c *gin.Context) string {
	h := sha256.New()
	h.Write([]byte(c.Request.Method))
	h.Write([]byte(c.Request.URL.String()))
	return fmt.Sprintf("cache:%x", h.Sum(nil))
}

func CacheMiddleware(ttl time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.Method != "GET" && c.Request.Method != "HEAD" {
			c.Next()
			return
		}

		key := cacheKey(c)

		var cached cachedResponse
		if err := utils.Cache.Get(c.Request.Context(), key, &cached); err == nil {
			c.Data(cached.Status, c.ContentType(), cached.Body)
			c.Abort()
			return
		}

		w := &cacheWriter{body: &bytes.Buffer{}, ResponseWriter: c.Writer}
		c.Writer = w
		c.Next()

		if c.Writer.Status() < 300 {
			body := w.body.Bytes()
			resp := cachedResponse{Status: c.Writer.Status(), Body: json.RawMessage(body)}
			utils.Cache.Set(c.Request.Context(), key, &resp, ttl)
		}
	}
}

func InvalidateCacheOnWrite() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		if c.Request.Method == "POST" || c.Request.Method == "PUT" || c.Request.Method == "PATCH" || c.Request.Method == "DELETE" {
			if c.Writer.Status() < 400 {
				utils.Cache.ClearPattern(c.Request.Context(), "cache:*")
			}
		}
	}
}


