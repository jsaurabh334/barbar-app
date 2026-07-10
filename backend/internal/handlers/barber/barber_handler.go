package barber

import (
	"fmt"
	"strconv"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/middleware"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BarberHandler struct {
	db *gorm.DB
}

func NewBarberHandler(db *gorm.DB) *BarberHandler {
	return &BarberHandler{db: db}
}

type RegisterBarberRequest struct {
	ShopName              string   `json:"shop_name" binding:"required,min=2,max=255"`
	ShopDescription       string   `json:"shop_description"`
	Address               string   `json:"address" binding:"required"`
	City                  string   `json:"city" binding:"required"`
	State                 string   `json:"state" binding:"required"`
	Pincode               string   `json:"pincode" binding:"required"`
	Latitude              float64  `json:"latitude"`
	Longitude             float64  `json:"longitude"`
	StartTime             string   `json:"start_time" binding:"required"`
	EndTime               string   `json:"end_time" binding:"required"`
	ExperienceYears       int      `json:"experience_years"`
	Services              []ServiceInput `json:"services"`
	IsHomeServiceAvailable bool   `json:"is_home_service_available"`
	ServiceRadiusKm       float64  `json:"service_radius_km"`
	TravelChargePerKm     float64  `json:"travel_charge_per_km"`
	BaseTravelCharge      float64  `json:"base_travel_charge"`
}

type ServiceInput struct {
	Name        string    `json:"name" binding:"required"`
	Description string    `json:"description"`
	CategoryID  uuid.UUID `json:"category_id" binding:"required"`
	Price       float64   `json:"price" binding:"required,gt=0"`
	DurationMin int       `json:"duration_minutes" binding:"required,gt=0"`
	IsAddon     bool      `json:"is_addon"`
}

func (h *BarberHandler) Register(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet(middleware.ContextKeyClaims).(*auth.Claims)
	userRole := claims.Role

	if userRole != string(models.RoleBarber) && userRole != string(models.RoleAdmin) {
		utils.ForbiddenResponse(c, "Only barbers can register a shop")
		return
	}

	var req RegisterBarberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	var existing models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&existing).Error; err == nil {
		utils.BadRequestResponse(c, "Barber profile already exists")
		return
	}

	tx := h.db.Begin()

	barber := models.Barber{
		UserID:                 userID,
		ShopName:               req.ShopName,
		ShopDescription:        req.ShopDescription,
		Address:                req.Address,
		City:                   req.City,
		State:                  req.State,
		Pincode:                req.Pincode,
		Latitude:               req.Latitude,
		Longitude:              req.Longitude,
		Status:                 models.BarberStatusActive,
		StartTime:              req.StartTime,
		EndTime:                req.EndTime,
		ExperienceYears:        req.ExperienceYears,
		SlotDuration:           30,
		BufferBetweenSlots:     5,
		MaxQueueSize:           50,
		IsAvailable:            true,
		IsHomeServiceAvailable: req.IsHomeServiceAvailable,
		ServiceRadiusKm:        req.ServiceRadiusKm,
		TravelChargePerKm:      req.TravelChargePerKm,
		BaseTravelCharge:       req.BaseTravelCharge,
	}

	if err := tx.Create(&barber).Error; err != nil {
		tx.Rollback()
		utils.InternalErrorResponse(c, "Failed to create barber profile")
		return
	}

	// Create services
	for _, svc := range req.Services {
		service := models.BarberService{
			BarberID:    barber.ID,
			Name:        svc.Name,
			Description: svc.Description,
			CategoryID:  &svc.CategoryID,
			Price:       svc.Price,
			DurationMin: svc.DurationMin,
			IsAddon:     svc.IsAddon,
		}
		if err := tx.Create(&service).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to create services")
			return
		}
	}

	tx.Commit()

	utils.CreatedResponse(c, barber)
}

func (h *BarberHandler) GetProfile(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		// Get own profile
		userID := c.MustGet("user").(uuid.UUID)
		var barber models.Barber
		if err := h.db.Preload("Services").Where("user_id = ?", userID).First(&barber).Error; err != nil {
			utils.NotFoundResponse(c, "Barber profile not found")
			return
		}
		utils.SuccessResponse(c, barber)
		return
	}

	var barber models.Barber
	if err := h.db.Preload("Services").Preload("User").First(&barber, id).Error; err != nil {
		utils.NotFoundResponse(c, "Barber not found")
		return
	}

	utils.SuccessResponse(c, barber)
}

func (h *BarberHandler) UpdateProfile(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	allowed := []string{"shop_name", "shop_description", "address", "city", "state", "pincode",
		"latitude", "longitude", "start_time", "end_time", "break_start_time", "break_end_time",
		"slot_duration", "max_queue_size", "experience_years", "shop_image", "tags", "phone", "email", "amenities",
		"is_home_service_available", "service_radius_km", "travel_charge_per_km", "base_travel_charge"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	h.db.Model(&barber).Updates(filtered)
	h.db.Preload("Services").First(&barber, barber.ID)
	utils.SuccessResponse(c, barber)
}

func (h *BarberHandler) UpdateAvailability(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var req struct {
		IsAvailable bool `json:"is_available"`
		Status      string `json:"status" binding:"omitempty,oneof=active inactive on_break closed"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	updates := map[string]interface{}{"is_available": req.IsAvailable}
	if req.Status != "" {
		updates["status"] = models.BarberStatus(req.Status)
	}
	h.db.Model(&barber).Updates(updates)
	utils.SuccessResponse(c, gin.H{"message": "Availability updated"})
}

func (h *BarberHandler) ListAvailableSlots(c *gin.Context) {
	barberID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid barber ID")
		return
	}

	dateStr := c.Query("date")
	if dateStr == "" {
		utils.BadRequestResponse(c, "date query parameter is required (YYYY-MM-DD)")
		return
	}
	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		utils.BadRequestResponse(c, "Invalid date format, use YYYY-MM-DD")
		return
	}

	var barber models.Barber
	if err := h.db.First(&barber, barberID).Error; err != nil {
		utils.NotFoundResponse(c, "Barber not found")
		return
	}

	// Check if barber is closed this day via BarberHoliday
	var holiday int64
	h.db.Model(&models.BarberHoliday{}).Where("barber_id = ? AND date = ? AND is_active = ?", barberID, date, true).Count(&holiday)
	if holiday > 0 {
		utils.SuccessResponse(c, []map[string]interface{}{})
		return
	}

	dayOfWeek := int(date.Weekday()) // 0=Sunday, 6=Saturday

	// Get weekly schedule override if it exists
	var weekly models.BarberAvailability
	startTime := barber.StartTime
	endTime := barber.EndTime
	h.db.Where("barber_id = ? AND day_of_week = ? AND is_active = ?", barberID, dayOfWeek, true).Limit(1).Find(&weekly)
	if weekly.ID != uuid.Nil {
		startTime = weekly.StartTime
		endTime = weekly.EndTime
	} else if startTime == "" || endTime == "" {
		utils.SuccessResponse(c, []map[string]interface{}{})
		return
	}

	// Parse slot duration from barber config
	slotDur := barber.SlotDuration
	if slotDur <= 0 {
		slotDur = 30
	}
	buffer := barber.BufferBetweenSlots
	if buffer < 0 {
		buffer = 0
	}
	step := slotDur + buffer
	if step <= 0 {
		step = 30
	}

	startParsed, _ := time.Parse("15:04", startTime)
	endParsed, _ := time.Parse("15:04", endTime)

	breakStart, breakEnd := -1, -1
	if barber.BreakStartTime != "" && barber.BreakEndTime != "" {
		bs, _ := time.Parse("15:04", barber.BreakStartTime)
		be, _ := time.Parse("15:04", barber.BreakEndTime)
		breakStart = bs.Hour()*60 + bs.Minute()
		breakEnd = be.Hour()*60 + be.Minute()
	}

	// Fetch existing bookings for this date
	dayStart := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.Local)
	dayEnd := dayStart.Add(24 * time.Hour)
	var existingBookings []models.Booking
	h.db.Where("barber_id = ? AND scheduled_start >= ? AND scheduled_start < ? AND status IN ?",
		barberID, dayStart, dayEnd,
		[]models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress},
	).Find(&existingBookings)

	// Build occupied time map: for each existing booking, mark its slot range
	type occupiedRange struct{ startMin, endMin int }
	occupied := make([]occupiedRange, 0)
	for _, b := range existingBookings {
		bTime := b.ScheduledStart
		bMin := bTime.Hour()*60 + bTime.Minute()
		dur := b.TotalDuration
		if dur <= 0 {
			dur = slotDur
		}
		occupied = append(occupied, occupiedRange{startMin: bMin, endMin: bMin + dur})
	}

	// Generate slots
	var slots []map[string]interface{}
	startMin := startParsed.Hour()*60 + startParsed.Minute()
	endMin := endParsed.Hour()*60 + endParsed.Minute()
	now := time.Now()
	isToday := date.Year() == now.Year() && date.YearDay() == now.YearDay()

	for slotStart := startMin; slotStart+slotDur <= endMin; slotStart += step {
		slotEnd := slotStart + slotDur

		// Skip break hours
		if breakStart >= 0 && slotStart >= breakStart && slotStart < breakEnd {
			continue
		}

		// Skip past slots (if today)
		if isToday && slotStart <= now.Hour()*60+now.Minute() {
			continue
		}

		// Check overlap with existing bookings
		available := true
		for _, occ := range occupied {
			if slotStart < occ.endMin && slotEnd > occ.startMin {
				available = false
				break
			}
		}

		hour := slotStart / 60
		min := slotStart % 60
		timeStr := fmt.Sprintf("%02d:%02d", hour, min)
		slots = append(slots, map[string]interface{}{
			"time":      timeStr,
			"available": available,
		})
	}

	utils.SuccessResponse(c, slots)
}

func (h *BarberHandler) ListServices(c *gin.Context) {
	barberID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		userID := c.MustGet("user").(uuid.UUID)
		var barber models.Barber
		h.db.Where("user_id = ?", userID).First(&barber)
		barberID = barber.ID
	}

	var services []models.BarberService
	h.db.Where("barber_id = ? AND is_active = ?", barberID, true).Order("sort_order ASC").Find(&services)
	utils.SuccessResponse(c, services)
}

func (h *BarberHandler) AddService(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var req struct {
		Name        string    `json:"name" binding:"required"`
		Description string    `json:"description"`
		CategoryID  uuid.UUID `json:"category_id" binding:"required"`
		Price       float64   `json:"price" binding:"required,gt=0"`
		DurationMin int       `json:"duration_minutes" binding:"required,gt=0"`
		IsAddon     bool      `json:"is_addon"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	service := models.BarberService{
		BarberID:    barber.ID,
		Name:        req.Name,
		Description: req.Description,
		CategoryID:  &req.CategoryID,
		Price:       req.Price,
		DurationMin: req.DurationMin,
		IsAddon:     req.IsAddon,
	}
	h.db.Create(&service)
	utils.CreatedResponse(c, service)
}

func (h *BarberHandler) UpdateService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("service_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid service ID")
		return
	}

	var service models.BarberService
	if err := h.db.First(&service, serviceID).Error; err != nil {
		utils.NotFoundResponse(c, "Service not found")
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	allowed := []string{"name", "description", "category_id", "price", "discount_price", "duration_minutes", "is_active", "is_addon", "sort_order"}
	filtered := make(map[string]interface{})
	for _, key := range allowed {
		if val, ok := updates[key]; ok {
			filtered[key] = val
		}
	}

	h.db.Model(&service).Updates(filtered)
	h.db.First(&service, serviceID)
	utils.SuccessResponse(c, service)
}

func (h *BarberHandler) DeleteService(c *gin.Context) {
	serviceID, err := uuid.Parse(c.Param("service_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid service ID")
		return
	}

	result := h.db.Delete(&models.BarberService{}, serviceID)
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Service not found")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Service deleted"})
}

func (h *BarberHandler) ListNearby(c *gin.Context) {
	lat := c.Query("lat")
	if lat == "" {
		lat = c.Query("latitude")
	}
	lng := c.Query("lng")
	if lng == "" {
		lng = c.Query("longitude")
	}
	latF, _ := strconv.ParseFloat(lat, 64)
	lngF, _ := strconv.ParseFloat(lng, 64)
	radius, _ := strconv.ParseFloat(c.Query("radius"), 64)
	page, pageSize := utils.GetPageParams(c)

	if radius == 0 {
		radius = 10
	}

	var barbers []models.Barber
	var total int64
	baseCond := "status = ? AND is_available = ? AND verification_status = ?"
	baseArgs := []interface{}{models.BarberStatusActive, true, models.BarberVerifApproved}

	countQuery := h.db.Model(&models.Barber{}).Where(baseCond, baseArgs...)
	dataQuery := h.db.Where(baseCond, baseArgs...)

	// Filter by city
	if city := c.Query("city"); city != "" {
		countQuery = countQuery.Where("LOWER(city) = LOWER(?)", city)
		dataQuery = dataQuery.Where("LOWER(city) = LOWER(?)", city)
	}

	// Search by service name or shop name
	search := c.Query("search")
	if search == "" {
		search = c.Query("service")
	}
	if search != "" {
		like := "%" + search + "%"
		countQuery = countQuery.Where(
			"(LOWER(shop_name) LIKE LOWER(?) OR id IN (SELECT barber_id FROM barber_services WHERE LOWER(name) LIKE LOWER(?)))",
			like, like,
		)
		dataQuery = dataQuery.Where(
			"(LOWER(shop_name) LIKE LOWER(?) OR id IN (SELECT barber_id FROM barber_services WHERE LOWER(name) LIKE LOWER(?)))",
			like, like,
		)
	}
	if minRating := c.Query("min_rating"); minRating != "" {
		countQuery = countQuery.Where("rating >= ?", minRating)
		dataQuery = dataQuery.Where("rating >= ?", minRating)
	}

	if c.Query("open_now") == "true" {
		now := time.Now()
		currentTime := now.Format("15:04")
		countQuery = countQuery.Where("start_time <= ? AND end_time > ?", currentTime, currentTime).
			Where("(break_start_time IS NULL OR break_start_time = '' OR break_end_time IS NULL OR break_end_time = '' OR ? < break_start_time OR ? >= break_end_time)", currentTime, currentTime)
		dataQuery = dataQuery.Where("start_time <= ? AND end_time > ?", currentTime, currentTime).
			Where("(break_start_time IS NULL OR break_start_time = '' OR break_end_time IS NULL OR break_end_time = '' OR ? < break_start_time OR ? >= break_end_time)", currentTime, currentTime)
	}

	if categoryID := c.Query("category_id"); categoryID != "" {
		countQuery = countQuery.Joins("JOIN barber_services ON barber_services.barber_id = barbers.id AND barber_services.deleted_at IS NULL").
			Where("barber_services.category_id = ? AND barber_services.is_active = ?", categoryID, true).
			Distinct("barbers.id")
		dataQuery = dataQuery.Joins("JOIN barber_services ON barber_services.barber_id = barbers.id AND barber_services.deleted_at IS NULL").
			Where("barber_services.category_id = ? AND barber_services.is_active = ?", categoryID, true).
			Group("barbers.id")
	}

	countQuery.Count(&total)

	// Haversine distance calculation
	if latF != 0 && lngF != 0 {
		dataQuery = dataQuery.Where("(6371 * acos(cos(radians(?)) * cos(radians(latitude)) * cos(radians(longitude) - radians(?)) + sin(radians(?)) * sin(radians(latitude)))) <= ?",
			latF, lngF, latF, radius)
	}

	dataQuery.Offset((page - 1) * pageSize).Limit(pageSize).Order("is_featured DESC, rating DESC, barbers.created_at DESC").Find(&barbers)

	utils.PaginatedResponse(c, barbers, page, pageSize, total)
}

func (h *BarberHandler) GetDashboard(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)

	var (
		todayBookings  int64
		pendingCount   int64
		inProgressCount int64
		completedToday int64
		totalEarnings  float64
		queueBookings  []models.Booking
	)

	h.db.Model(&models.Booking{}).Where("barber_id = ? AND scheduled_start >= ? AND scheduled_start < ?", barber.ID, today, tomorrow).Count(&todayBookings)
	h.db.Model(&models.Booking{}).Where("barber_id = ? AND status = ?", barber.ID, models.BookingStatusPending).Count(&pendingCount)
	h.db.Model(&models.Booking{}).Where("barber_id = ? AND status = ?", barber.ID, models.BookingStatusInProgress).Count(&inProgressCount)
	h.db.Model(&models.Booking{}).Where("barber_id = ? AND status = ? AND scheduled_start >= ? AND scheduled_start < ?", barber.ID, models.BookingStatusCompleted, today, tomorrow).Count(&completedToday)
	h.db.Model(&models.Booking{}).Where("barber_id = ? AND status = ? AND scheduled_start >= ? AND scheduled_start < ?", barber.ID, models.BookingStatusCompleted, today, tomorrow).Select("COALESCE(SUM(final_price), 0)").Scan(&totalEarnings)
	h.db.Where("barber_id = ? AND scheduled_start >= ? AND status IN ?", barber.ID, time.Now(), []models.BookingStatus{models.BookingStatusPending, models.BookingStatusConfirmed, models.BookingStatusInProgress}).Order("scheduled_start ASC").Find(&queueBookings)

	utils.SuccessResponse(c, gin.H{
		"barber":          barber,
		"today_bookings":  todayBookings,
		"pending":         pendingCount,
		"in_progress":     inProgressCount,
		"completed_today": completedToday,
		"total_earnings":  totalEarnings,
		"queue":           queueBookings,
	})
}

func (h *BarberHandler) GetEarnings(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	period := c.DefaultQuery("period", "week")

	var barber models.Barber
	h.db.Where("user_id = ?", userID).First(&barber)

	now := time.Now()
	var since time.Time
	switch period {
	case "week":
		since = now.AddDate(0, 0, -7)
	case "month":
		since = now.AddDate(0, -1, 0)
	case "year":
		since = now.AddDate(-1, 0, 0)
	default:
		since = now.AddDate(0, 0, -7)
	}

	type EarningRecord struct {
		Date   string  `json:"date"`
		Amount float64 `json:"amount"`
		Count  int     `json:"count"`
	}
	var records []EarningRecord
	h.db.Model(&models.Booking{}).
		Select("DATE(scheduled_start) as date, COUNT(*) as count, SUM(final_price) as amount").
		Where("barber_id = ? AND status = ? AND scheduled_start >= ?", barber.ID, models.BookingStatusCompleted, since).
		Group("DATE(scheduled_start)").
		Order("date ASC").
		Scan(&records)

	var totalEarnings float64
	h.db.Model(&models.Booking{}).
		Where("barber_id = ? AND status = ? AND scheduled_start >= ?", barber.ID, models.BookingStatusCompleted, since).
		Select("COALESCE(SUM(final_price), 0)").Scan(&totalEarnings)

	utils.SuccessResponse(c, gin.H{
		"period":   period,
		"total":    totalEarnings,
		"earnings": records,
	})
}

func (h *BarberHandler) AddHoliday(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	h.db.Where("user_id = ?", userID).First(&barber)

	var req struct {
		Date   time.Time `json:"date" binding:"required"`
		Reason string    `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	holiday := models.BarberHoliday{
		BarberID: barber.ID,
		Date:     req.Date,
		Reason:   req.Reason,
	}
	h.db.Create(&holiday)
	utils.CreatedResponse(c, holiday)
}

func (h *BarberHandler) ListHolidays(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	h.db.Where("user_id = ?", userID).First(&barber)

	var holidays []models.BarberHoliday
	h.db.Where("barber_id = ? AND is_active = ?", barber.ID, true).Order("date DESC").Find(&holidays)
	utils.SuccessResponse(c, holidays)
}

// ================ Barber Availability (Weekly Schedule) ================
func (h *BarberHandler) SetWeeklySchedule(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var req []struct {
		DayOfWeek int    `json:"day_of_week" binding:"required,min=0,max=6"`
		StartTime string `json:"start_time" binding:"required"`
		EndTime   string `json:"end_time" binding:"required"`
		IsActive  *bool  `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: expected array of day schedules")
		return
	}

	tx := h.db.Begin()
	for _, s := range req {
		active := true
		if s.IsActive != nil {
			active = *s.IsActive
		}

		// Upsert: find existing record for this barber + day
		var existing models.BarberAvailability
		result := tx.Where("barber_id = ? AND day_of_week = ?", barber.ID, s.DayOfWeek).First(&existing)
		if result.Error != nil {
			// Create
			avail := models.BarberAvailability{
				BarberID:  barber.ID,
				DayOfWeek: s.DayOfWeek,
				StartTime: s.StartTime,
				EndTime:   s.EndTime,
				IsActive:  active,
			}
			if err := tx.Create(&avail).Error; err != nil {
				tx.Rollback()
				utils.InternalErrorResponse(c, "Failed to save schedule")
				return
			}
		} else {
			tx.Model(&existing).Updates(map[string]interface{}{
				"start_time": s.StartTime,
				"end_time":   s.EndTime,
				"is_active":  active,
			})
		}
	}
	tx.Commit()

	// Return updated schedule
	var schedule []models.BarberAvailability
	h.db.Where("barber_id = ?", barber.ID).Order("day_of_week ASC").Find(&schedule)
	utils.SuccessResponse(c, schedule)
}

func (h *BarberHandler) GetWeeklySchedule(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var schedule []models.BarberAvailability
	h.db.Where("barber_id = ?", barber.ID).Order("day_of_week ASC").Find(&schedule)
	utils.SuccessResponse(c, schedule)
}

// ================ Barber Documents ================
func (h *BarberHandler) UploadDocument(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var req struct {
		DocType string `json:"doc_type" binding:"required"`
		DocURL  string `json:"doc_url" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	doc := models.BarberDocument{
		BarberID: barber.ID,
		DocType:  req.DocType,
		DocURL:   req.DocURL,
		Status:   "pending",
	}
	h.db.Create(&doc)
	utils.CreatedResponse(c, doc)
}

func (h *BarberHandler) ListDocuments(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	var docs []models.BarberDocument
	h.db.Where("barber_id = ?", barber.ID).Order("created_at DESC").Find(&docs)
	utils.SuccessResponse(c, docs)
}

func (h *BarberHandler) DeleteDocument(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	docID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid document ID")
		return
	}

	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.NotFoundResponse(c, "Barber profile not found")
		return
	}

	result := h.db.Where("id = ? AND barber_id = ?", docID, barber.ID).Delete(&models.BarberDocument{})
	if result.RowsAffected == 0 {
		utils.NotFoundResponse(c, "Document not found")
		return
	}
	utils.SuccessResponse(c, gin.H{"message": "Document deleted"})
}
