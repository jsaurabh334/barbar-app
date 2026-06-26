package middleware

import (
	"net/http"
	"strings"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	"github.com/gin-gonic/gin"
)

const (
	ContextKeyUser   = "user"
	ContextKeyClaims = "claims"
)

type AuthMiddleware struct {
	jwtManager *auth.JWTManager
}

func NewAuthMiddleware(jwtManager *auth.JWTManager) *AuthMiddleware {
	return &AuthMiddleware{jwtManager: jwtManager}
}

func (m *AuthMiddleware) Authenticate() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, models.APIResponse{
				Success: false,
				Error:   "Authorization token required",
			})
			return
		}

		claims, err := m.jwtManager.ValidateToken(token, auth.AccessToken)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, models.APIResponse{
				Success: false,
				Error:   "Invalid or expired token",
			})
			return
		}

		c.Set(ContextKeyClaims, claims)
		c.Set(ContextKeyUser, claims.UserID)
		c.Next()
	}
}

func (m *AuthMiddleware) RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get(ContextKeyClaims)
		if !exists {
			c.AbortWithStatusJSON(http.StatusUnauthorized, models.APIResponse{
				Success: false,
				Error:   "Authentication required",
			})
			return
		}

		userClaims, ok := claims.(*auth.Claims)
		if !ok {
			c.AbortWithStatusJSON(http.StatusInternalServerError, models.APIResponse{
				Success: false,
				Error:   "Invalid claims format",
			})
			return
		}

		for _, role := range roles {
			if userClaims.Role == role {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, models.APIResponse{
			Success: false,
			Error:   "Insufficient permissions",
		})
	}
}

func (m *AuthMiddleware) OptionalAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractToken(c)
		if token != "" {
			claims, err := m.jwtManager.ValidateToken(token, auth.AccessToken)
			if err == nil {
				c.Set(ContextKeyClaims, claims)
				c.Set(ContextKeyUser, claims.UserID)
			}
		}
		c.Next()
	}
}

func extractToken(c *gin.Context) string {
	// Check Authorization header
	authHeader := c.GetHeader("Authorization")
	if authHeader != "" {
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) == 2 && strings.ToLower(parts[0]) == "bearer" {
			return parts[1]
		}
	}

	// Check query parameter
	if token := c.Query("token"); token != "" {
		return token
	}

	return ""
}
