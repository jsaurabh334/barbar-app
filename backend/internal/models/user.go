package models

import (
	"github.com/google/uuid"
	"time"
)

type UserRole string

const (
	RoleCustomer UserRole = "customer"
	RoleBarber   UserRole = "barber"
	RoleVendor   UserRole = "vendor"
	RoleAdmin    UserRole = "admin"
	RoleSuperAdmin UserRole = "super_admin"
)

type UserStatus string

const (
	UserStatusActive   UserStatus = "active"
	UserStatusInactive UserStatus = "inactive"
	UserStatusSuspended UserStatus = "suspended"
	UserStatusBlocked  UserStatus = "blocked"
)

type User struct {
	BaseModel
	Email           string     `gorm:"uniqueIndex;size:255" json:"email"`
	Phone           string     `gorm:"uniqueIndex;size:20" json:"phone"`
	PasswordHash    string     `gorm:"size:255" json:"-"`
	FullName        string     `gorm:"size:255" json:"full_name"`
	Avatar          string     `gorm:"size:500" json:"avatar,omitempty"`
	Role            UserRole   `gorm:"size:50;default:customer;index" json:"role"`
	Status          UserStatus `gorm:"size:50;default:active;index" json:"status"`
	EmailVerifiedAt *time.Time `json:"email_verified_at,omitempty"`
	PhoneVerifiedAt *time.Time `json:"phone_verified_at,omitempty"`
	DeviceType      string     `gorm:"size:50" json:"device_type,omitempty"`
	FCMToken        string     `gorm:"size:500" json:"fcm_token,omitempty"`
	LastLoginAt     *time.Time `json:"last_login_at,omitempty"`
	LastActiveAt    *time.Time `json:"last_active_at,omitempty"`
	OTP             string     `gorm:"size:10" json:"-"`
	OTPExpiresAt    *time.Time `json:"-"`
	OTPVerified     bool       `gorm:"default:false" json:"otp_verified"`
	TwoFactorEnabled bool     `gorm:"default:false" json:"two_factor_enabled"`
	LanguagePref    string     `gorm:"size:10;default:en" json:"language_pref"`
	Metadata        JSONB      `gorm:"type:jsonb" json:"metadata,omitempty"`

	// Relations
	Barber  *Barber  `gorm:"foreignKey:UserID" json:"barber,omitempty"`
	Vendor  *Vendor  `gorm:"foreignKey:UserID" json:"vendor,omitempty"`
	Wallet  *Wallet  `gorm:"foreignKey:UserID" json:"wallet,omitempty"`
	Addresses []Address `gorm:"foreignKey:UserID" json:"addresses,omitempty"`
}

type UserSession struct {
	BaseModel
	UserID       uuid.UUID  `gorm:"type:uuid;index" json:"user_id"`
	RefreshToken string     `gorm:"size:500;uniqueIndex" json:"-"`
	AccessToken  string     `gorm:"size:500" json:"-"`
	DeviceInfo   string     `gorm:"size:500" json:"device_info,omitempty"`
	IPAddress    string     `gorm:"size:50" json:"ip_address,omitempty"`
	UserAgent    string     `gorm:"size:500" json:"user_agent,omitempty"`
	IsActive     bool       `gorm:"default:true" json:"is_active"`
	ExpiresAt    time.Time  `json:"expires_at"`
	RevokedAt    *time.Time `json:"revoked_at,omitempty"`
}

type Address struct {
	BaseModel
	UserID     uuid.UUID `gorm:"type:uuid;index" json:"user_id"`
	Label      string    `gorm:"size:100" json:"label"`
	FullName   string    `gorm:"size:255" json:"full_name"`
	Phone      string    `gorm:"size:20" json:"phone"`
	Pincode    string    `gorm:"size:10;index" json:"pincode"`
	Line1      string    `gorm:"size:500" json:"line_1"`
	Line2      string    `gorm:"size:500" json:"line_2,omitempty"`
	Landmark   string    `gorm:"size:255" json:"landmark,omitempty"`
	City       string    `gorm:"size:100;index" json:"city"`
	State      string    `gorm:"size:100" json:"state"`
	Country    string    `gorm:"size:100;default:India" json:"country"`
	Latitude   float64   `json:"latitude,omitempty"`
	Longitude  float64   `json:"longitude,omitempty"`
	IsDefault  bool      `gorm:"default:false" json:"is_default"`
	AddressType string   `gorm:"size:50" json:"address_type"`
}
