package barber

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type StaffHandler struct {
	db *gorm.DB
}

func NewStaffHandler(db *gorm.DB) *StaffHandler {
	return &StaffHandler{db: db}
}

// getBarberIDFromUser looks up the barber record from the authenticated user ID
func (h *StaffHandler) getBarberIDFromUser(c *gin.Context) (uuid.UUID, bool) {
	userID := c.MustGet("user").(uuid.UUID)
	var barber models.Barber
	if err := h.db.Where("user_id = ?", userID).First(&barber).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Barber profile not found")
		return uuid.Nil, false
	}
	return barber.ID, true
}

// AddStaff adds a new staff member to the barber's shop
func (h *StaffHandler) AddStaff(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	var req struct {
		Name            string   `json:"name" binding:"required"`
		Image           string   `json:"image"`
		Phone           string   `json:"phone"`
		Role            string   `json:"role" binding:"omitempty,oneof=staff manager"`
		Bio             string   `json:"bio"`
		ExperienceYears int      `json:"experience_years"`
		Languages       []string `json:"languages"`
		Specializations string   `json:"specializations"`
		Instagram       string   `json:"instagram"`
		StartTime       string   `json:"start_time"`
		EndTime         string   `json:"end_time"`
		WorkingDays     string   `json:"working_days"`
		DayOff          string   `json:"day_off"`
		ServiceIDs      []string `json:"service_ids"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid request body: "+err.Error())
		return
	}

	role := models.RoleStaff
	if req.Role == string(models.RoleManager) {
		role = models.RoleManager
	}

	if req.StartTime == "" {
		req.StartTime = "09:00"
	}
	if req.EndTime == "" {
		req.EndTime = "21:00"
	}
	if req.WorkingDays == "" {
		req.WorkingDays = "1,2,3,4,5,6"
	}
	dayOffInt := 0
	if req.DayOff != "" {
		if d, err := strconv.Atoi(req.DayOff); err == nil {
			dayOffInt = d
		}
	}

	languagesJSON := []byte("[]")
	if req.Languages != nil {
		languagesJSON, _ = json.Marshal(req.Languages)
	}

	staff := models.BarberStaff{
		BarberID:         barberID,
		Name:             req.Name,
		Image:            req.Image,
		Phone:            req.Phone,
		Role:             role,
		IsActive:         true,
		Bio:              req.Bio,
		ExperienceYears:  req.ExperienceYears,
		Languages:        languagesJSON,
		Specializations:  req.Specializations,
		Instagram:        req.Instagram,
		StartTime:        req.StartTime,
		EndTime:          req.EndTime,
		WorkingDays:      req.WorkingDays,
		DayOff:           dayOffInt,
	}

	if err := h.db.Create(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to add staff")
		return
	}

	if req.ServiceIDs != nil {
		for _, sid := range req.ServiceIDs {
			if parsed, err := uuid.Parse(sid); err == nil {
				h.db.Create(&models.StaffService{
					StaffID:   staff.ID,
					ServiceID: parsed,
					IsActive:  true,
				})
			}
		}
	}

	utils.CreatedResponse(c, staff)
}

// GetStaffByID returns a single staff member by ID
func (h *StaffHandler) GetStaffByID(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Preload("Services.Service").Where("id = ? AND barber_id = ?", staffID, barberID).First(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Staff member not found")
		return
	}

	utils.SuccessResponse(c, staff)
}

// GetStaff returns all staff members for the barber's shop
func (h *StaffHandler) GetStaff(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	var staffList []models.BarberStaff
	if err := h.db.Preload("Services.Service").Where("barber_id = ?", barberID).Order("created_at ASC").Find(&staffList).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to fetch staff")
		return
	}

	utils.SuccessResponse(c, staffList)
}

// UpdateStaff updates staff member details
func (h *StaffHandler) UpdateStaff(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Where("id = ? AND barber_id = ?", staffID, barberID).First(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Staff member not found")
		return
	}

	var req struct {
		Name            *string  `json:"name"`
		Image           *string  `json:"image"`
		Phone           *string  `json:"phone"`
		Role            *string  `json:"role" binding:"omitempty,oneof=staff manager"`
		IsActive        *bool    `json:"is_active"`
		Bio             *string  `json:"bio"`
		ExperienceYears *int     `json:"experience_years"`
		Languages       []string `json:"languages"`
		Specializations *string  `json:"specializations"`
		Instagram       *string  `json:"instagram"`
		StartTime       *string  `json:"start_time"`
		EndTime         *string  `json:"end_time"`
		WorkingDays     *string  `json:"working_days"`
		DayOff          *string  `json:"day_off"`
		ServiceIDs      []string `json:"service_ids"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		log.Println("UpdateStaff BIND ERROR:", err.Error())
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid request body: "+err.Error())
		return
	}

	updates := make(map[string]interface{})
	if req.Name != nil {
		updates["name"] = *req.Name
	}
	if req.Image != nil {
		updates["image"] = *req.Image
	}
	if req.Phone != nil {
		updates["phone"] = *req.Phone
	}
	if req.Role != nil {
		updates["role"] = *req.Role
	}
	if req.IsActive != nil {
		updates["is_active"] = *req.IsActive
	}
	if req.Bio != nil {
		updates["bio"] = *req.Bio
	}
	if req.ExperienceYears != nil {
		updates["experience_years"] = *req.ExperienceYears
	}
	if req.Languages != nil {
		langJSON, _ := json.Marshal(req.Languages)
		updates["languages"] = langJSON
	}
	if req.Specializations != nil {
		updates["specializations"] = *req.Specializations
	}
	if req.Instagram != nil {
		updates["instagram"] = *req.Instagram
	}
	if req.StartTime != nil {
		updates["start_time"] = *req.StartTime
	}
	if req.EndTime != nil {
		updates["end_time"] = *req.EndTime
	}
	if req.WorkingDays != nil {
		updates["working_days"] = *req.WorkingDays
	}
	if req.DayOff != nil {
		if d, err := strconv.Atoi(*req.DayOff); err == nil {
			updates["day_off"] = d
		} else {
			updates["day_off"] = 0
		}
	}

	if len(updates) > 0 {
		updates["updated_at"] = time.Now()
		h.db.Model(&staff).Updates(updates)
	}

	if req.ServiceIDs != nil {
		h.db.Where("staff_id = ?", staffID).Delete(&models.StaffService{})
		for _, sid := range req.ServiceIDs {
			if parsed, err := uuid.Parse(sid); err == nil {
				h.db.Create(&models.StaffService{
					StaffID:   staffID,
					ServiceID: parsed,
					IsActive:  true,
				})
			}
		}
	}

	h.db.Preload("Services.Service").Where("id = ?", staffID).First(&staff)
	utils.SuccessResponse(c, staff)
}

// ArchiveStaff soft-deletes a staff member by setting IsActive = false
func (h *StaffHandler) ArchiveStaff(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Where("id = ? AND barber_id = ?", staffID, barberID).First(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Staff member not found")
		return
	}

	staff.IsActive = false
	if err := h.db.Save(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to archive staff")
		return
	}

	utils.SuccessResponse(c, gin.H{"message": "Staff member archived"})
}

// AssignServices assigns services to a staff member with optional price/duration overrides
func (h *StaffHandler) AssignServices(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Where("id = ? AND barber_id = ?", staffID, barberID).First(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Staff member not found")
		return
	}

	var req struct {
		Services []struct {
			ServiceID   uuid.UUID `json:"service_id" binding:"required"`
			Price       float64   `json:"price"`
			DurationMin int       `json:"duration_minutes"`
			BufferMin   int       `json:"buffer_minutes"`
		} `json:"services" binding:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid request body: "+err.Error())
		return
	}

	// Verify all service IDs belong to this barber
	serviceIDs := make([]uuid.UUID, len(req.Services))
	for i, s := range req.Services {
		serviceIDs[i] = s.ServiceID
	}

	var count int64
	h.db.Model(&models.BarberService{}).Where("id IN ? AND barber_id = ? AND is_active = ?", serviceIDs, barberID, true).Count(&count)
	if count != int64(len(serviceIDs)) {
		utils.ErrorResponse(c, http.StatusBadRequest, "One or more services do not belong to this shop or are inactive")
		return
	}

	tx := h.db.Begin()

	// Remove existing assignments
	tx.Where("staff_id = ?", staffID).Delete(&models.StaffService{})

	// Create new assignments
	for _, s := range req.Services {
		ss := models.StaffService{
			StaffID:     staffID,
			ServiceID:   s.ServiceID,
			Price:       s.Price,
			DurationMin: s.DurationMin,
			BufferMin:   s.BufferMin,
			IsActive:    true,
		}
		if err := tx.Create(&ss).Error; err != nil {
			tx.Rollback()
			utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to assign services")
			return
		}
	}

	tx.Commit()

	// Return updated staff with services
	h.db.Preload("Services.Service").Where("id = ?", staffID).First(&staff)
	utils.SuccessResponse(c, staff)
}

// GetStaffServices returns services assigned to a specific staff member
func (h *StaffHandler) GetStaffServices(c *gin.Context) {
	barberID, ok := h.getBarberIDFromUser(c)
	if !ok {
		return
	}

	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Where("id = ? AND barber_id = ?", staffID, barberID).First(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Staff member not found")
		return
	}

	var staffServices []models.StaffService
	h.db.Preload("Service").Where("staff_id = ? AND is_active = ?", staffID, true).Find(&staffServices)

	utils.SuccessResponse(c, staffServices)
}

// GetPublicStaffProfile returns a single staff member with rating summary (public endpoint)
func (h *StaffHandler) GetPublicStaffProfile(c *gin.Context) {
	staffID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid staff ID")
		return
	}

	var staff models.BarberStaff
	if err := h.db.Preload("Services.Service").Where("id = ? AND is_active = ?", staffID, true).First(&staff).Error; err != nil {
		utils.ErrorResponse(c, http.StatusNotFound, "Staff member not found")
		return
	}

	dist := models.RatingDistribution{}
	if staff.RatingDistribution != nil {
		json.Unmarshal(staff.RatingDistribution, &dist)
	}

	utils.SuccessResponse(c, gin.H{
		"staff": staff,
		"rating_summary": gin.H{
			"avg_rating":    staff.Rating,
			"total_reviews": staff.ReviewCount,
			"distribution": gin.H{
				"5": dist.Star5,
				"4": dist.Star4,
				"3": dist.Star3,
				"2": dist.Star2,
				"1": dist.Star1,
			},
		},
	})
}

// ListPublicStaff returns all active staff members for a barber (public endpoint)
func (h *StaffHandler) ListPublicStaff(c *gin.Context) {
	barberID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "Invalid barber ID")
		return
	}

	var staffList []models.BarberStaff
	if err := h.db.Preload("Services.Service").Where("barber_id = ? AND is_active = ?", barberID, true).Find(&staffList).Error; err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "Failed to fetch staff")
		return
	}

	utils.SuccessResponse(c, staffList)
}
