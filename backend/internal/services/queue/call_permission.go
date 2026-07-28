package queue

import (
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/google/uuid"
)

const (
	RoleCustomer = "customer"
	RoleBarber   = "barber"
	RoleAdmin    = "admin"
)

func (s *QueueService) CanCall(bookingID uuid.UUID, callerID uuid.UUID, callerRole string) bool {
	booking, err := s.getBooking(bookingID)
	if err != nil {
		return false
	}

	isToday := isSameDay(booking.ScheduledStart, time.Now())
	if !isToday {
		return false
	}

	switch callerRole {
	case RoleCustomer:
		return booking.CustomerID == callerID
	case RoleBarber:
		var barber models.Barber
		if err := s.db.First(&barber, booking.BarberID).Error; err != nil {
			return false
		}
		return barber.UserID == callerID
	case RoleAdmin:
		return true
	}
	return false
}

func (s *QueueService) GetMaskedPhone(bookingID uuid.UUID, callerID uuid.UUID, callerRole string) (string, string, error) {
	booking, err := s.getBooking(bookingID)
	if err != nil {
		return "", "", err
	}

	if !s.CanCall(bookingID, callerID, callerRole) {
		return "", "", nil
	}

	var barberPhone string
	var barber models.Barber
	if s.db.First(&barber, booking.BarberID).Error == nil {
		barberPhone = maskPhone(barber.Phone)
	}

	customerPhone := ""
	var user models.User
	if s.db.First(&user, booking.CustomerID).Error == nil {
		customerPhone = maskPhone(user.Phone)
	}

	return barberPhone, customerPhone, nil
}

func (s *QueueService) CanCallShop(bookingID uuid.UUID, callerID uuid.UUID) bool {
	return s.CanCall(bookingID, callerID, RoleCustomer)
}

func (s *QueueService) CanCallCustomer(bookingID uuid.UUID, callerID uuid.UUID) bool {
	return s.CanCall(bookingID, callerID, RoleBarber)
}

func maskPhone(phone string) string {
	if len(phone) < 10 {
		return phone
	}
	return phone[:2] + "******" + phone[len(phone)-2:]
}

func isSameDay(t1, t2 time.Time) bool {
	y1, m1, d1 := t1.Date()
	y2, m2, d2 := t2.Date()
	return y1 == y2 && m1 == m2 && d1 == d2
}
