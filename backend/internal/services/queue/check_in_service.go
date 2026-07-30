package queue

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"math"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/google/uuid"
)

type CheckInService struct {
	svc *QueueService
}

func (s *QueueService) CheckInService() *CheckInService {
	return &CheckInService{svc: s}
}

func (s *CheckInService) GenerateQRToken(bookingID uuid.UUID) string {
	secret := fmt.Sprintf("barbar-checkin-%s-%d", bookingID.String(), time.Now().Truncate(15*time.Minute).Unix())
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(bookingID.String()))
	return base64.URLEncoding.EncodeToString(mac.Sum(nil))[:32]
}

func (s *CheckInService) VerifyQR(bookingID uuid.UUID, token string) bool {
	expected := s.GenerateQRToken(bookingID)
	return hmac.Equal([]byte(token), []byte(expected))
}

func (s *CheckInService) CheckIn(bookingID uuid.UUID, method string) error {
	var barberID uuid.UUID
	var customerID uuid.UUID

	err := s.svc.MutateQueue(bookingID, func(b *models.Booking) error {
		now := time.Now()
		barberID = b.BarberID
		customerID = b.CustomerID
		b.Status = models.BookingStatusCheckedIn
		b.CheckInAt = &now

		return nil
	}, "system", method)
	if err != nil {
		return err
	}

	// Notify barber that customer checked in
	if s.svc.dispatcher != nil {
		customerName := ""
		var user models.User
		if err := s.svc.db.First(&user, customerID).Error; err == nil {
			customerName = user.FullName
		}

		var barber models.Barber
		if err := s.svc.db.First(&barber, barberID).Error; err == nil {
			s.svc.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
				Type:       models.NotifCustomerCheckedIn,
				ReceiverID: barber.UserID,
				Role:       notification.RoleBarber,
				Data: map[string]any{
					"entity_id":     bookingID.String(),
					"customer_id":   customerID.String(),
					"customer_name": customerName,
				},
			})
		}
	}

	return nil
}

func (s *CheckInService) ImComing(bookingID uuid.UUID) error {
	var barberID uuid.UUID
	var staffID *uuid.UUID
	var queuePos int

	err := s.svc.withLockedBooking(bookingID, func(b *models.Booking) error {
		if !b.IsLate {
			return fmt.Errorf("booking is not late")
		}
		if b.Status != models.BookingStatusConfirmed && b.Status != models.BookingStatusCheckedIn &&
			b.Status != models.BookingStatusWaiting && b.Status != models.BookingStatusNext {
			return fmt.Errorf("cannot use I'm Coming for booking in status %s", b.Status)
		}

		now := time.Now()
		extendedUntil := now.Add(10 * time.Minute)
		b.ImComingAt = &now
		b.GraceExtendedUntil = &extendedUntil

		barberID = b.BarberID
		staffID = b.StaffID
		queuePos = b.QueuePosition
		return nil
	})
	if err != nil {
		return err
	}

	s.svc.CreateAuditLog(barberID, staffID, bookingID, models.QueueActionImComing, queuePos, queuePos, uuid.Nil, "customer", "I'm Coming - grace extended by 10 min")
	s.svc.BroadcastQueueUpdate(barberID)

	return nil
}

func (s *CheckInService) ValidateGPS(bookingID uuid.UUID, lat, lng float64, radiusMeters float64) (bool, error) {
	booking, err := s.svc.getBooking(bookingID)
	if err != nil {
		return false, err
	}

	var barber models.Barber
	if err := s.svc.db.First(&barber, booking.BarberID).Error; err != nil {
		return false, err
	}

	if radiusMeters <= 0 {
		radiusMeters = 100
	}

	dist := haversineMeters(barber.Latitude, barber.Longitude, lat, lng)
	return dist <= radiusMeters, nil
}

func haversineMeters(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371000.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return R * c
}
