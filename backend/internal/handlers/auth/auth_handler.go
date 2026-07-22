package auth

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/database"
	"github.com/barbar-app/backend/internal/models"
	notifService "github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

var emailSvc *notifService.EmailService
var smsSvc *notifService.SMSService
var hmacSecret string

func InitNotificationServices(cfg *config.Config) {
	emailSvc = notifService.NewEmailService(&cfg.SMTP)
	smsSvc = notifService.NewSMSService(&cfg.SMS)
	hmacSecret = cfg.JWT.Secret
}

func computeOTPHash(otp string) string {
	mac := hmac.New(sha256.New, []byte(hmacSecret))
	mac.Write([]byte(otp))
	return hex.EncodeToString(mac.Sum(nil))
}

func generateOTP() (string, error) {
	const digits = "0123456789"
	otp := make([]byte, 6)
	for i := range otp {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", fmt.Errorf("failed to generate OTP: %w", err)
		}
		otp[i] = digits[n.Int64()]
	}
	return string(otp), nil
}

func hashRefreshToken(token string) string {
	h := sha256.Sum256([]byte(token))
	return hex.EncodeToString(h[:])
}

func maxOTPAttemptsReached(phone string) bool {
	ctx := context.Background()
	val, err := database.RedisClient.Get(ctx, "otp:attempts:"+phone).Int()
	if err != nil {
		return false
	}
	return val >= 5
}

func incrementOTPAttempts(phone string) {
	ctx := context.Background()
	database.RedisClient.Incr(ctx, "otp:attempts:"+phone)
	database.RedisClient.Expire(ctx, "otp:attempts:"+phone, 5*time.Minute)
}

func resetOTPAttempts(phone string) {
	ctx := context.Background()
	database.RedisClient.Del(ctx, "otp:attempts:"+phone)
}

type AuthHandler struct {
	db         *gorm.DB
	jwtManager *auth.JWTManager
}

func NewAuthHandler(db *gorm.DB, jwtManager *auth.JWTManager) *AuthHandler {
	return &AuthHandler{db: db, jwtManager: jwtManager}
}

type RegisterRequest struct {
	FullName string `json:"full_name" binding:"required,min=2,max=255"`
	Email    string `json:"email" binding:"omitempty,email,max=255"`
	Phone    string `json:"phone" binding:"required,min=10,max=20"`
	Password string `json:"password" binding:"required,min=8,max=100"`
	Role     string `json:"role" binding:"omitempty,oneof=customer barber vendor delivery admin"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"omitempty,email"`
	Phone    string `json:"phone" binding:"omitempty"`
	Password string `json:"password" binding:"required"`
}

type OTPRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type OTPVerifyRequest struct {
	Phone string `json:"phone" binding:"required"`
	OTP   string `json:"otp" binding:"required,len=6"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if req.Role == "" {
		req.Role = string(models.RoleCustomer)
	}
	allowedRoles := map[string]bool{
		string(models.RoleCustomer): true,
		string(models.RoleBarber):   true,
		string(models.RoleVendor):   true,
		string(models.RoleDelivery): true,
		string(models.RoleAdmin):    true,
	}
	if !allowedRoles[req.Role] {
		utils.BadRequestResponse(c, "Invalid role: "+req.Role)
		return
	}
	req.Phone = strings.ReplaceAll(req.Phone, " ", "")

	if req.Email == "" {
		cleanPhone := strings.ReplaceAll(strings.ReplaceAll(req.Phone, "+", ""), " ", "")
		req.Email = fmt.Sprintf("user_%s@barbar.app", cleanPhone)
	}

	var existing models.User
	if err := h.db.Where("email = ? OR phone = ?", req.Email, req.Phone).First(&existing).Error; err == nil {
		utils.BadRequestResponse(c, "User with this email or phone already exists")
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to hash password")
		return
	}

	user := models.User{
		FullName:     req.FullName,
		Email:        req.Email,
		Phone:        req.Phone,
		PasswordHash: string(hashedPassword),
		Role:         models.UserRole(req.Role),
		Status:       models.UserStatusActive,
		LanguagePref: "en",
	}

	if err := h.db.Create(&user).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create user")
		return
	}

	userID := user.ID
	utils.DefaultPool.SubmitNamed("create_wallet", func(p interface{}) error {
		wallet := models.Wallet{UserID: &userID, Balance: 0}
		return h.db.Create(&wallet).Error
	}, nil)

	tokens, err := h.jwtManager.GenerateTokenPair(user.ID, user.Email, user.Phone, string(user.Role))
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate tokens")
		return
	}

	utils.CreatedResponse(c, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}
	req.Phone = strings.ReplaceAll(req.Phone, " ", "")

	var user models.User
	query := h.db.Where("email = ?", req.Email)
	if req.Phone != "" {
		query = h.db.Where("phone = ?", req.Phone)
	}
	if req.Email == "" && req.Phone == "" {
		utils.BadRequestResponse(c, "Email or phone is required")
		return
	}

	if err := query.First(&user).Error; err != nil {
		utils.UnauthorizedResponse(c, "Invalid credentials")
		return
	}

	if user.Status != models.UserStatusActive {
		utils.ForbiddenResponse(c, "Account is not active")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		utils.UnauthorizedResponse(c, "Invalid credentials")
		return
	}

	now := time.Now()
	user.LastLoginAt = &now
	h.db.Model(&user).Update("last_login_at", &now)

	tokens, err := h.jwtManager.GenerateTokenPair(user.ID, user.Email, user.Phone, string(user.Role))
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate tokens")
		return
	}

	// Save session with hashed refresh token
	session := models.UserSession{
		UserID:       user.ID,
		RefreshToken: hashRefreshToken(tokens.RefreshToken),
		AccessToken:  tokens.AccessToken,
		IPAddress:    c.ClientIP(),
		UserAgent:    c.Request.UserAgent(),
		IsActive:     true,
		ExpiresAt:    time.Now().Add(7 * 24 * time.Hour),
	}
	h.db.Create(&session)

	utils.SuccessResponse(c, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

func (h *AuthHandler) SendOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}
	req.Phone = strings.ReplaceAll(req.Phone, " ", "")

	otp, err := generateOTP()
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate OTP")
		return
	}
	otpHash := computeOTPHash(otp)
	expiresAt := time.Now().Add(5 * time.Minute)

	cleanPhone := strings.ReplaceAll(strings.ReplaceAll(req.Phone, "+", ""), " ", "")
	autoEmail := fmt.Sprintf("user_%s@barbar.app", cleanPhone)

	var user models.User
	result := h.db.Where("phone = ? OR email = ?", req.Phone, autoEmail).First(&user)
	if result.Error != nil {
		// Create temp user if not exists
		user = models.User{
			Phone:        req.Phone,
			Email:        autoEmail,
			Role:         models.RoleCustomer,
			Status:       models.UserStatusActive,
			OTP:          otpHash,
			OTPExpiresAt: &expiresAt,
		}
		h.db.Create(&user)
	} else {
		h.db.Model(&user).Updates(map[string]interface{}{
			"otp":            otpHash,
			"otp_expires_at": &expiresAt,
		})
	}

	// Reset attempt counter on fresh OTP send
	resetOTPAttempts(req.Phone)

	// Send SMS via Twilio or similar
	go sendSMS(req.Phone, otp)

	if os.Getenv("DEV_OTP_DEBUG") == "true" {
		log.Printf("[DEV_OTP] Phone=%s Code=%s\n", req.Phone, otp)
	}

	utils.SuccessResponse(c, gin.H{
		"message": "OTP sent successfully",
	})
}

func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var req OTPVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}
	req.Phone = strings.ReplaceAll(req.Phone, " ", "")

	// Check attempt limit
	if maxOTPAttemptsReached(req.Phone) {
		utils.BadRequestResponse(c, "Too many attempts. Request a new OTP.")
		return
	}

	otpHash := computeOTPHash(req.OTP)

	var user models.User
	if err := h.db.Where("phone = ? AND otp = ? AND otp_expires_at > ?", req.Phone, otpHash, time.Now()).First(&user).Error; err != nil {
		// Increment attempt counter
		incrementOTPAttempts(req.Phone)
		utils.BadRequestResponse(c, "Invalid or expired OTP")
		return
	}

	// Constant-time comparison safeguard
	if subtle.ConstantTimeCompare([]byte(user.OTP), []byte(otpHash)) != 1 {
		incrementOTPAttempts(req.Phone)
		utils.BadRequestResponse(c, "Invalid or expired OTP")
		return
	}

	// Reset attempt counter on success
	resetOTPAttempts(req.Phone)

	now := time.Now()
	user.PhoneVerifiedAt = &now
	user.OTPVerified = true
	user.LastLoginAt = &now
	h.db.Save(&user)

	tokens, err := h.jwtManager.GenerateTokenPair(user.ID, user.Email, user.Phone, string(user.Role))
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate tokens")
		return
	}

	// Save session with hashed refresh token
	session := models.UserSession{
		UserID:       user.ID,
		RefreshToken: hashRefreshToken(tokens.RefreshToken),
		AccessToken:  tokens.AccessToken,
		IPAddress:    c.ClientIP(),
		UserAgent:    c.Request.UserAgent(),
		IsActive:     true,
		ExpiresAt:    time.Now().Add(7 * 24 * time.Hour),
	}
	h.db.Create(&session)

	utils.SuccessResponse(c, gin.H{
		"user":   user,
		"tokens": tokens,
	})
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	claims, err := h.jwtManager.ValidateToken(req.RefreshToken, auth.RefreshToken)
	if err != nil {
		utils.UnauthorizedResponse(c, "Invalid or expired refresh token")
		return
	}

	// Hash incoming refresh token and look up session
	tokenHash := hashRefreshToken(req.RefreshToken)
	var session models.UserSession
	if err := h.db.Where("refresh_token = ? AND is_active = ?", tokenHash, true).First(&session).Error; err != nil {
		// Token already rotated or revoked — possible theft
		// Revoke all sessions for this user to be safe
		now := time.Now()
		h.db.Model(&models.UserSession{}).Where("user_id = ? AND is_active = ?", claims.UserID, true).
			Updates(map[string]interface{}{
				"is_active":  false,
				"revoked_at": &now,
			})
		utils.UnauthorizedResponse(c, "Refresh token has already been used. All sessions revoked for security.")
		return
	}

	// Revoke old session
	now := time.Now()
	h.db.Model(&session).Updates(map[string]interface{}{
		"is_active":  false,
		"revoked_at": &now,
	})

	var user models.User
	if err := h.db.First(&user, claims.UserID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	if user.Status != models.UserStatusActive {
		utils.ForbiddenResponse(c, "Account is not active")
		return
	}

	tokens, err := h.jwtManager.GenerateTokenPair(user.ID, user.Email, user.Phone, string(user.Role))
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate tokens")
		return
	}

	// Save new session with hashed refresh token
	newSession := models.UserSession{
		UserID:       user.ID,
		RefreshToken: hashRefreshToken(tokens.RefreshToken),
		AccessToken:  tokens.AccessToken,
		IPAddress:    c.ClientIP(),
		UserAgent:    c.Request.UserAgent(),
		IsActive:     true,
		ExpiresAt:    time.Now().Add(7 * 24 * time.Hour),
	}
	h.db.Create(&newSession)

	utils.SuccessResponse(c, gin.H{"tokens": tokens})
}

func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var user models.User
	if err := h.db.Preload("Addresses").First(&user, userID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	utils.SuccessResponse(c, user)
}

func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	allowed := []string{"full_name", "avatar", "language_pref", "email"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	if err := h.db.Model(&models.User{}).Where("id = ?", userID).Updates(filtered).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to update profile")
		return
	}

	var user models.User
	h.db.First(&user, userID)
	utils.SuccessResponse(c, user)
}

func (h *AuthHandler) ChangePassword(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req struct {
		OldPassword string `json:"old_password" binding:"required"`
		NewPassword string `json:"new_password" binding:"required,min=8,max=100"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var user models.User
	if err := h.db.First(&user, userID).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		utils.BadRequestResponse(c, "Current password is incorrect")
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to hash password")
		return
	}

	h.db.Model(&user).Update("password_hash", string(hashedPassword))

	// Invalidate all active sessions on password change
	now := time.Now()
	h.db.Model(&models.UserSession{}).Where("user_id = ? AND is_active = ?", userID, true).
		Updates(map[string]interface{}{
			"is_active":  false,
			"revoked_at": &now,
		})

	utils.SuccessResponse(c, gin.H{"message": "Password changed successfully"})
}

func (h *AuthHandler) Logout(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	h.db.Model(&models.UserSession{}).Where("user_id = ? AND is_active = ?", userID, true).Update("is_active", false)

	utils.SuccessResponse(c, gin.H{"message": "Logged out successfully"})
}

func (h *AuthHandler) DeleteAccount(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	h.db.Model(&models.User{}).Where("id = ?", userID).Update("status", models.UserStatusInactive)
	utils.SuccessResponse(c, gin.H{"message": "Account deleted successfully"})
}

func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"omitempty,email"`
		Phone string `json:"phone" binding:"omitempty"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var user models.User
	query := h.db
	if req.Email != "" {
		query = query.Where("email = ?", req.Email)
	} else if req.Phone != "" {
		query = query.Where("phone = ?", req.Phone)
	} else {
		utils.BadRequestResponse(c, "Email or phone required")
		return
	}

	if err := query.First(&user).Error; err != nil {
		// Don't reveal if user exists
		utils.SuccessResponse(c, gin.H{"message": "If account exists, reset instructions sent"})
		return
	}

	otp, err := generateOTP()
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to generate OTP")
		return
	}
	otpHash := computeOTPHash(otp)
	expiresAt := time.Now().Add(5 * time.Minute)
	h.db.Model(&user).Updates(map[string]interface{}{
		"otp":            otpHash,
		"otp_expires_at": &expiresAt,
	})
	resetOTPAttempts(req.Phone)

	if req.Email != "" {
		go sendEmail(user.Email, "Password Reset OTP", "Your OTP: "+otp)
	} else {
		go sendSMS(user.Phone, otp)
	}

	utils.SuccessResponse(c, gin.H{"message": "If account exists, reset instructions sent"})
}

func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req struct {
		Phone       string `json:"phone" binding:"required"`
		OTP         string `json:"otp" binding:"required,len=6"`
		NewPassword string `json:"new_password" binding:"required,min=8,max=100"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	// Check attempt limit
	if maxOTPAttemptsReached(req.Phone) {
		utils.BadRequestResponse(c, "Too many attempts. Request a new OTP.")
		return
	}

	otpHash := computeOTPHash(req.OTP)

	var user models.User
	if err := h.db.Where("phone = ? AND otp = ? AND otp_expires_at > ?", req.Phone, otpHash, time.Now()).First(&user).Error; err != nil {
		incrementOTPAttempts(req.Phone)
		utils.BadRequestResponse(c, "Invalid or expired OTP")
		return
	}

	// Constant-time comparison safeguard
	if subtle.ConstantTimeCompare([]byte(user.OTP), []byte(otpHash)) != 1 {
		incrementOTPAttempts(req.Phone)
		utils.BadRequestResponse(c, "Invalid or expired OTP")
		return
	}

	resetOTPAttempts(req.Phone)

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.InternalErrorResponse(c, "Failed to hash password")
		return
	}

	h.db.Model(&user).Update("password_hash", string(hashedPassword))
	utils.SuccessResponse(c, gin.H{"message": "Password reset successfully"})
}

// Admin endpoints
func (h *AuthHandler) ListUsers(c *gin.Context) {
	page, pageSize := utils.GetPageParams(c)
	var users []models.User
	var total int64

	query := h.db.Model(&models.User{})
	if role := c.Query("role"); role != "" {
		query = query.Where("role = ?", role)
	}
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("full_name ILIKE ? OR email ILIKE ? OR phone ILIKE ?", "%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	query.Count(&total)
	query.Offset((page - 1) * pageSize).Limit(pageSize).Order("created_at DESC").Find(&users)

	utils.PaginatedResponse(c, users, page, pageSize, total)
}

func (h *AuthHandler) GetUser(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var user models.User
	if err := h.db.Preload("Addresses").Preload("Barber").Preload("Vendor").First(&user, id).Error; err != nil {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	utils.SuccessResponse(c, user)
}

func (h *AuthHandler) UpdateUserStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid user ID")
		return
	}

	var req struct {
		Status string `json:"status" binding:"required,oneof=active inactive suspended blocked"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	result := h.db.Model(&models.User{}).Where("id = ?", id).Update("status", models.UserStatus(req.Status))
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "User not found")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "User status updated"})
}

// GetOTPDebug returns the current stored OTP for a phone number.
// ONLY available when the server is not running in production mode.
func (h *AuthHandler) GetOTPDebug(c *gin.Context) {
	phone := c.Param("phone")

	var user models.User
	if err := h.db.Where("phone = ?", phone).Order("created_at DESC").First(&user).Error; err != nil {
		utils.NotFoundResponse(c, "No user found with this phone number")
		return
	}

	if user.OTP == "" || user.OTPExpiresAt == nil || time.Now().After(*user.OTPExpiresAt) {
		utils.NotFoundResponse(c, "No active OTP found for this phone number")
		return
	}

	utils.SuccessResponse(c, gin.H{
		"phone":          user.Phone,
		"otp":            user.OTP,
		"expires_at":     user.OTPExpiresAt,
		"remaining_secs": int(time.Until(*user.OTPExpiresAt).Seconds()),
	})
}

func sendSMS(phone, message string) {
	if smsSvc == nil {
		return
	}
	utils.DefaultPool.SubmitNamed("send_sms", func(p interface{}) error {
		return smsSvc.Send(phone, message)
	}, nil)
}

func sendEmail(email, subject, body string) {
	if emailSvc == nil {
		return
	}
	utils.DefaultPool.SubmitNamed("send_email", func(p interface{}) error {
		return emailSvc.Send(email, subject, body)
	}, nil)
}
