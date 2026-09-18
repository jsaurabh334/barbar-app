package booking

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	settlementSvc "github.com/barbar-app/backend/internal/services/settlement"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupOTPTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	if err != nil {
		t.Skipf("skipping DB test: sqlite3 not available (requires CGO): %v", err)
	}
	require.NoError(t, db.AutoMigrate(&models.Booking{}))
	require.NoError(t, db.AutoMigrate(&models.Barber{}))
	require.NoError(t, db.AutoMigrate(&models.BarberStaff{}))
	require.NoError(t, db.AutoMigrate(&models.BookingStatusLog{}))
	require.NoError(t, db.AutoMigrate(&models.BarberEarning{}))
	require.NoError(t, db.AutoMigrate(&models.Wallet{}))
	require.NoError(t, db.AutoMigrate(&models.WalletTransaction{}))
	return db
}

// newOTPTestContext builds a gin test context with the given user/claims and body.
func newOTPTestContext(method, url, body string, userID uuid.UUID, claims *auth.Claims) (*gin.Context, *httptest.ResponseRecorder) {
	gin.SetMode(gin.TestMode)
	_ = gin.New()
	var req *http.Request
	if body != "" {
		req = httptest.NewRequest(method, url, bytes.NewBufferString(body))
		req.Header.Set("Content-Type", "application/json")
	} else {
		req = httptest.NewRequest(method, url, nil)
	}
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = req
	c.Set("user", userID)
	if claims != nil {
		c.Set("claims", claims)
	}
	return c, w
}

func createOTPBooking(t *testing.T, db *gorm.DB, status models.BookingStatus, isHome bool) (*models.Booking, *models.Barber, uuid.UUID) {
	t.Helper()
	barberUserID := uuid.New()
	customerID := uuid.New()
	barber := models.Barber{
		ShopName: "Test Shop",
		UserID:   barberUserID,
		Status:   models.BarberStatusActive,
	}
	require.NoError(t, db.Create(&barber).Error)

	booking := models.Booking{
		BarberID:       barber.ID,
		CustomerID:     customerID,
		Status:         status,
		IsHomeService:  isHome,
		ScheduledStart: time.Now().Add(1 * time.Hour),
		ScheduledEnd:   time.Now().Add(2 * time.Hour),
		FinalPrice:     500,
	}
	require.NoError(t, db.Create(&booking).Error)
	return &booking, &barber, barberUserID
}

func TestRequestCompletion(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)

	c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/request-completion", "", barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.RequestCompletion(c)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp struct {
		Data struct {
			Status          string `json:"status"`
			EndOTPGenerated string `json:"end_otp_generated_at"`
		} `json:"data"`
	}
	require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
	assert.Equal(t, string(models.BookingStatusAwaitingCustomerConfirmation), resp.Data.Status)

	var updated models.Booking
	db.First(&updated, booking.ID)
	assert.Equal(t, models.BookingStatusAwaitingCustomerConfirmation, updated.Status)
	assert.NotEmpty(t, updated.EndOTPHash)
	assert.NotNil(t, updated.EndOTPGeneratedAt)
	assert.Equal(t, 0, updated.EndOTPAttempts)
	// OTP must never leak into the response body
	assert.NotContains(t, w.Body.String(), "completion_otp")

	// Status log records the actual actor role
	var log models.BookingStatusLog
	require.NoError(t, db.Where("booking_id = ?", booking.ID).Order("created_at desc").First(&log).Error)
	assert.Equal(t, string(models.RoleBarber), log.ChangedByRole)

	// Authz: unrelated user cannot request completion
	otherUser := uuid.New()
	c2, w2 := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/request-completion", "", otherUser, &auth.Claims{UserID: otherUser, Role: string(models.RoleBarber)})
	h.RequestCompletion(c2)
	assert.Equal(t, http.StatusForbidden, w2.Code)

	// Shop bookings cannot use this flow
	shopBooking, _, owner := createOTPBooking(t, db, models.BookingStatusInProgress, false)
	c3, w3 := newOTPTestContext("POST", "/barber/home-service/"+shopBooking.ID.String()+"/request-completion", "", owner, &auth.Claims{UserID: owner, Role: string(models.RoleBarber)})
	h.RequestCompletion(c3)
	assert.Equal(t, http.StatusBadRequest, w3.Code)

	// Only in_progress bookings can request completion
	badBooking, _, owner2 := createOTPBooking(t, db, models.BookingStatusConfirmed, true)
	c4, w4 := newOTPTestContext("POST", "/barber/home-service/"+badBooking.ID.String()+"/request-completion", "", owner2, &auth.Claims{UserID: owner2, Role: string(models.RoleBarber)})
	h.RequestCompletion(c4)
	assert.Equal(t, http.StatusBadRequest, w4.Code)
}

func TestVerifyCompletionOTP(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)
	code := h.generateCompletionOTP(booking)
	booking.Status = models.BookingStatusAwaitingCustomerConfirmation
	require.NoError(t, db.Save(booking).Error)

	// Wrong OTP increments attempts and is rejected
	c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"000000"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c)
	assert.Equal(t, http.StatusBadRequest, w.Code)
	db.First(booking, booking.ID)
	assert.Equal(t, 1, booking.EndOTPAttempts)

	// Correct OTP completes the booking
	c2, w2 := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"`+code+`"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c2)
	assert.Equal(t, http.StatusOK, w2.Code)

	db.First(booking, booking.ID)
	assert.Equal(t, models.BookingStatusCompleted, booking.Status)
	assert.NotNil(t, booking.EndOTPVerifiedAt)
	assert.NotNil(t, booking.CompletedAt)
	assert.NotNil(t, booking.ActualEnd)

	// Verification is impossible after completion
	c3, w3 := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"`+code+`"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c3)
	assert.Equal(t, http.StatusBadRequest, w3.Code)
}

func TestVerifyCompletionOTPAttemptLimit(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)
	h.generateCompletionOTP(booking)
	booking.Status = models.BookingStatusAwaitingCustomerConfirmation
	require.NoError(t, db.Save(booking).Error)

	for i := 0; i < maxCompletionOTPAttempts; i++ {
		c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"111111"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
		h.VerifyCompletionOTP(c)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	}

	// Locked out after exhausting attempts
	c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"222222"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c)
	assert.Equal(t, http.StatusBadRequest, w.Code)
	assert.Contains(t, w.Body.String(), "Too many failed attempts")
}

func TestRegenerateAndResendCompletionOTP(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)
	h.generateCompletionOTP(booking)
	booking.Status = models.BookingStatusAwaitingCustomerConfirmation
	require.NoError(t, db.Save(booking).Error)
	oldHash := booking.EndOTPHash

	// Barber regenerates → new hash, attempts reset
	c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/regenerate-completion-otp", "", barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.RegenerateCompletionOTP(c)
	assert.Equal(t, http.StatusOK, w.Code)
	db.First(booking, booking.ID)
	assert.NotEmpty(t, booking.EndOTPHash)
	assert.NotEqual(t, oldHash, booking.EndOTPHash)
	assert.Equal(t, 0, booking.EndOTPAttempts)

	// Customer resends → new hash, attempts reset
	oldHash2 := booking.EndOTPHash
	c2, w2 := newOTPTestContext("POST", "/bookings/"+booking.ID.String()+"/completion-otp/resend", "", booking.CustomerID, &auth.Claims{UserID: booking.CustomerID, Role: string(models.RoleCustomer)})
	h.ResendCompletionOTP(c2)
	assert.Equal(t, http.StatusOK, w2.Code)
	db.First(booking, booking.ID)
	assert.NotEqual(t, oldHash2, booking.EndOTPHash)

	// Non-owner customer cannot resend
	c3, w3 := newOTPTestContext("POST", "/bookings/"+booking.ID.String()+"/completion-otp/resend", "", uuid.New(), &auth.Claims{UserID: uuid.New(), Role: string(models.RoleCustomer)})
	h.ResendCompletionOTP(c3)
	assert.Equal(t, http.StatusForbidden, w3.Code)
}

func TestVerifyCompletionOTPReplacedOTP(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)
	firstCode := h.generateCompletionOTP(booking)
	booking.Status = models.BookingStatusAwaitingCustomerConfirmation
	require.NoError(t, db.Save(booking).Error)

	// Customer resends → a fresh OTP supersedes the previous one
	secondCode := h.generateCompletionOTP(booking)
	require.NoError(t, db.Save(booking).Error)
	assert.NotEqual(t, firstCode, secondCode)
	assert.NotEmpty(t, booking.EndOTPPrevHash)

	// The superseded OTP yields a clear "replaced" error and is NOT penalised
	// against the attempt limit
	c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"`+firstCode+`"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c)
	assert.Equal(t, http.StatusBadRequest, w.Code)
	assert.Contains(t, w.Body.String(), "has been replaced")
	db.First(booking, booking.ID)
	assert.Equal(t, 0, booking.EndOTPAttempts)

	// The latest OTP still verifies and completes the booking
	c2, w2 := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"`+secondCode+`"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c2)
	assert.Equal(t, http.StatusOK, w2.Code)
	db.First(booking, booking.ID)
	assert.Equal(t, models.BookingStatusCompleted, booking.Status)
}

func TestProblemStillExists(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, _ := createOTPBooking(t, db, models.BookingStatusInProgress, true)
	h.generateCompletionOTP(booking)
	booking.Status = models.BookingStatusAwaitingCustomerConfirmation
	require.NoError(t, db.Save(booking).Error)

	c, w := newOTPTestContext("POST", "/bookings/"+booking.ID.String()+"/problem-still-exists", "", booking.CustomerID, &auth.Claims{UserID: booking.CustomerID, Role: string(models.RoleCustomer)})
	h.ProblemStillExists(c)
	assert.Equal(t, http.StatusOK, w.Code)

	db.First(booking, booking.ID)
	assert.Equal(t, models.BookingStatusInProgress, booking.Status)
	assert.Empty(t, booking.EndOTPHash)
	assert.Equal(t, 0, booking.EndOTPAttempts)

	// OTP is no longer verifiable once the booking is back in progress
	c2, w2 := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"123456"}`, booking.BarberID, &auth.Claims{UserID: booking.BarberID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c2)
	assert.Equal(t, http.StatusBadRequest, w2.Code)
}

func TestIsAssignedActor(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)

	staffUserID := uuid.New()
	staff := models.BarberStaff{
		BarberID: booking.BarberID,
		UserID:   &staffUserID,
		Name:     "Staff A",
		IsActive: true,
	}
	require.NoError(t, db.Create(&staff).Error)

	assert.True(t, h.isAssignedActor(booking, barberUserID))
	assert.False(t, h.isAssignedActor(booking, uuid.New()))

	booking.StaffID = &staff.ID
	assert.True(t, h.isAssignedActor(booking, staffUserID))
}

func TestUtilsVerifyOTP(t *testing.T) {
	code := utils.GenerateOTP(6)
	hash := utils.HashOTP(code)
	assert.True(t, utils.VerifyOTP(hash, code))
	assert.False(t, utils.VerifyOTP(hash, "000000"))
	assert.False(t, utils.VerifyOTP("", code))
	assert.Equal(t, 6, len(code))
}

func TestVerifyCompletionOTPCreatesPendingEarning(t *testing.T) {
	db := setupOTPTestDB(t)
	h := &BookingHandler{db: db, settlement: settlementSvc.NewBookingSettlementService(db)}

	booking, _, barberUserID := createOTPBooking(t, db, models.BookingStatusInProgress, true)
	code := h.generateCompletionOTP(booking)
	booking.Status = models.BookingStatusAwaitingCustomerConfirmation
	require.NoError(t, db.Save(booking).Error)

	c, w := newOTPTestContext("POST", "/barber/home-service/"+booking.ID.String()+"/verify-completion-otp", `{"otp":"`+code+`"}`, barberUserID, &auth.Claims{UserID: barberUserID, Role: string(models.RoleBarber)})
	h.VerifyCompletionOTP(c)
	assert.Equal(t, http.StatusOK, w.Code)

	// A pending earning is captured for the barber (escrow held, not yet released)
	var earnings []models.BarberEarning
	require.NoError(t, db.Where("booking_id = ?", booking.ID).Find(&earnings).Error)
	require.Len(t, earnings, 1)
	assert.Equal(t, booking.BarberID, earnings[0].BarberID)
	assert.Equal(t, booking.FinalPrice, earnings[0].Amount)
	assert.Equal(t, models.EarningStatusPending, earnings[0].Status)
}
