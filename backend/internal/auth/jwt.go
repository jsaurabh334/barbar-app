package auth

import (
	"errors"
	"time"

	"github.com/barbar-app/backend/internal/config"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type TokenType string

const (
	AccessToken  TokenType = "access"
	RefreshToken TokenType = "refresh"
	EmailToken   TokenType = "email_verify"
	PhoneToken   TokenType = "phone_verify"
	ResetToken   TokenType = "password_reset"
)

type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
	Phone  string    `json:"phone"`
	Role   string    `json:"role"`
	Type   TokenType `json:"type"`
	jwt.RegisteredClaims
}

type TokenPair struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	TokenType    string    `json:"token_type"`
}

type JWTManager struct {
	cfg *config.JWTConfig
}

func NewJWTManager(cfg *config.JWTConfig) *JWTManager {
	return &JWTManager{cfg: cfg}
}

func (m *JWTManager) GenerateTokenPair(userID uuid.UUID, email, phone, role string) (*TokenPair, error) {
	now := time.Now()
	accessExp := now.Add(m.cfg.AccessTokenTTL)
	refreshExp := now.Add(m.cfg.RefreshTokenTTL)

	accessClaims := &Claims{
		UserID: userID,
		Email:  email,
		Phone:  phone,
		Role:   role,
		Type:   AccessToken,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(accessExp),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    m.cfg.Issuer,
			ID:        uuid.New().String(),
		},
	}

	refreshClaims := &Claims{
		UserID: userID,
		Email:  email,
		Role:   role,
		Type:   RefreshToken,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(refreshExp),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    m.cfg.Issuer,
			ID:        uuid.New().String(),
		},
	}

	accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString([]byte(m.cfg.Secret))
	if err != nil {
		return nil, err
	}

	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString([]byte(m.cfg.Secret))
	if err != nil {
		return nil, err
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresAt:    accessExp,
		TokenType:    "Bearer",
	}, nil
}

func (m *JWTManager) ValidateToken(tokenString string, tokenType TokenType) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(m.cfg.Secret), nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	if claims.Type != tokenType {
		return nil, errors.New("invalid token type")
	}

	return claims, nil
}

func (m *JWTManager) GenerateCustomToken(userID uuid.UUID, email, role string, ttl time.Duration, tokenType TokenType) (string, error) {
	claims := &Claims{
		UserID: userID,
		Email:  email,
		Role:   role,
		Type:   tokenType,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(ttl)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    m.cfg.Issuer,
			ID:        uuid.New().String(),
		},
	}

	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(m.cfg.Secret))
}
