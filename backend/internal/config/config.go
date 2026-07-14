package config

import (
	"os"
	"strconv"
	"sync"
	"time"
)

var (
	cachedConfig *Config
	loadOnce     sync.Once
)

type Config struct {
	Server   ServerConfig
	Database DatabaseConfig
	Redis    RedisConfig
	JWT      JWTConfig
	SMTP     SMTPConfig
	SMS      SMSConfig
	Razorpay RazorpayConfig
	Stripe   StripeConfig
	AWS      AWSConfig
	Cloudinary CloudinaryConfig
	App      AppConfig
	FCM      FCMConfig
}

type FCMConfig struct {
	ServerKey string
}

type ServerConfig struct {
	Port         string
	Mode         string
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	AllowOrigins string
}

type DatabaseConfig struct {
	Host            string
	Port            string
	User            string
	Password        string
	Name            string
	SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

type JWTConfig struct {
	Secret           string
	AccessTokenTTL   time.Duration
	RefreshTokenTTL  time.Duration
	Issuer           string
}

type SMTPConfig struct {
	Host     string
	Port     int
	Username string
	Password string
	From     string
}

type SMSConfig struct {
	AccountSID string
	AuthToken  string
	FromNumber string
}

type RazorpayConfig struct {
	KeyID     string
	KeySecret string
}

type StripeConfig struct {
	SecretKey      string
	PublishableKey string
	WebhookSecret  string
}

type AWSConfig struct {
	AccessKeyID     string
	SecretAccessKey string
	Region          string
	S3Bucket        string
}

type CloudinaryConfig struct {
	CloudName string
	APIKey    string
	APISecret string
}

type UploadConfig struct {
	Dir     string
	MaxSize int64
}

type AppConfig struct {
	Name             string
	Version          string
	BaseURL          string
	DefaultPageSize  int
	MaxPageSize      int
	Currency         string
	CommissionRate   float64
	PlatformFee      float64
	TaxRate          float64
	SupportEmail     string
	SupportPhone     string
	Upload           UploadConfig
}

func (c *Config) IsDevMode() bool {
	return c.Server.Mode != "release"
}

func Load() *Config {
	loadOnce.Do(func() {
		cachedConfig = &Config{
		Server: ServerConfig{
			Port:         getEnv("SERVER_PORT", "8080"),
			Mode:         getEnv("GIN_MODE", "debug"),
			ReadTimeout:  30 * time.Second,
			WriteTimeout: 30 * time.Second,
			AllowOrigins: getEnv("ALLOW_ORIGINS", "*"),
		},
		Database: DatabaseConfig{
			Host:            getEnv("DB_HOST", "localhost"),
			Port:            getEnv("DB_PORT", "5432"),
			User:            getEnv("DB_USER", "postgres"),
			Password:        getEnv("DB_PASSWORD", "postgres"),
			Name:            getEnv("DB_NAME", "barbar_app"),
			SSLMode:         getEnv("DB_SSLMODE", "disable"),
			MaxOpenConns:    getEnvInt("DB_MAX_OPEN_CONNS", 50),
			MaxIdleConns:    getEnvInt("DB_MAX_IDLE_CONNS", 25),
			ConnMaxLifetime: 30 * time.Minute,
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvInt("REDIS_DB", 0),
		},
		JWT: JWTConfig{
			Secret:          getEnv("JWT_SECRET", "super-secret-key-change-in-production"),
			AccessTokenTTL:  15 * time.Minute,
			RefreshTokenTTL: 7 * 24 * time.Hour,
			Issuer:          "barbar-app",
		},
		SMTP: SMTPConfig{
			Host:     getEnv("SMTP_HOST", "smtp.sendgrid.net"),
			Port:     getEnvInt("SMTP_PORT", 587),
			Username: getEnv("SMTP_USERNAME", "apikey"),
			Password: getEnv("SMTP_PASSWORD", ""),
			From:     getEnv("SMTP_FROM", "noreply@barbar.app"),
		},
		SMS: SMSConfig{
			AccountSID: getEnv("TWILIO_ACCOUNT_SID", ""),
			AuthToken:  getEnv("TWILIO_AUTH_TOKEN", ""),
			FromNumber: getEnv("TWILIO_FROM_NUMBER", ""),
		},
		Razorpay: RazorpayConfig{
			KeyID:     getEnv("RAZORPAY_KEY_ID", ""),
			KeySecret: getEnv("RAZORPAY_KEY_SECRET", ""),
		},
		Stripe: StripeConfig{
			SecretKey:      getEnv("STRIPE_SECRET_KEY", ""),
			PublishableKey: getEnv("STRIPE_PUBLISHABLE_KEY", ""),
			WebhookSecret:  getEnv("STRIPE_WEBHOOK_SECRET", ""),
		},
		FCM: FCMConfig{
			ServerKey: getEnv("FCM_SERVER_KEY", ""),
		},
		AWS: AWSConfig{
			AccessKeyID:     getEnv("AWS_ACCESS_KEY_ID", ""),
			SecretAccessKey: getEnv("AWS_SECRET_ACCESS_KEY", ""),
			Region:          getEnv("AWS_REGION", "ap-south-1"),
			S3Bucket:        getEnv("AWS_S3_BUCKET", "barbar-app-uploads"),
		},
		Cloudinary: CloudinaryConfig{
			CloudName: getEnv("CLOUDINARY_CLOUD_NAME", ""),
			APIKey:    getEnv("CLOUDINARY_API_KEY", ""),
			APISecret: getEnv("CLOUDINARY_API_SECRET", ""),
		},
		App: AppConfig{
			Name:            "Barbar App",
			Version:         "1.0.0",
			BaseURL:         getEnv("BASE_URL", "http://localhost:8080"),
			DefaultPageSize: 20,
			MaxPageSize:     100,
			Currency:        "INR",
			CommissionRate:  0.10,
			PlatformFee:     5.00,
			TaxRate:         0.18,
			SupportEmail:    "support@barbar.app",
			SupportPhone:    "+919999999999",
			Upload: UploadConfig{
				Dir:     getEnv("UPLOAD_DIR", "uploads"),
				MaxSize: int64(getEnvInt("UPLOAD_MAX_SIZE_MB", 10)) * 1024 * 1024,
			},
		},
	}
	})
	return cachedConfig
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
	}
	return defaultValue
}
