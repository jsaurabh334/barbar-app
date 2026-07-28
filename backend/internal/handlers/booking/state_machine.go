package booking

import (
	"fmt"

	"github.com/barbar-app/backend/internal/models"
)

type Transition struct {
	From models.BookingStatus
	To   models.BookingStatus
}

var validTransitions = map[models.BookingStatus]map[models.BookingStatus]bool{
	models.BookingStatusPending: {
		models.BookingStatusConfirmed:  true,
		models.BookingStatusCancelled:  true,
	},
	models.BookingStatusConfirmed: {
		models.BookingStatusCheckedIn: true,
		models.BookingStatusCancelled: true,
		models.BookingStatusNoShow:    true,
	},
	models.BookingStatusCheckedIn: {
		models.BookingStatusWaiting:  true,
		models.BookingStatusCancelled: true,
		models.BookingStatusNoShow:    true,
	},
	models.BookingStatusWaiting: {
		models.BookingStatusNext:      true,
		models.BookingStatusCancelled: true,
		models.BookingStatusNoShow:    true,
	},
	models.BookingStatusNext: {
		models.BookingStatusInProgress: true,
		models.BookingStatusCancelled:  true,
		models.BookingStatusNoShow:     true,
	},
	models.BookingStatusInProgress: {
		models.BookingStatusCompleted: true,
	},
	models.BookingStatusCompleted: {},
	models.BookingStatusCancelled:  {},
	models.BookingStatusNoShow:     {},
	models.BookingStatusRescheduled: {
		models.BookingStatusPending:   true,
		models.BookingStatusCancelled: true,
	},
	models.BookingStatusHomeServicePending: {
		models.BookingStatusConfirmed: true,
		models.BookingStatusCancelled: true,
	},
}

func IsValidTransition(from, to models.BookingStatus) bool {
	if allowed, ok := validTransitions[from]; ok {
		return allowed[to]
	}
	return false
}

func ValidateTransition(from, to models.BookingStatus) error {
	if !IsValidTransition(from, to) {
		return fmt.Errorf("invalid booking status transition from %s to %s", from, to)
	}
	return nil
}

func QueueStatuses() []models.BookingStatus {
	return []models.BookingStatus{
		models.BookingStatusCheckedIn,
		models.BookingStatusWaiting,
		models.BookingStatusNext,
		models.BookingStatusInProgress,
	}
}

func ActiveStatuses() []models.BookingStatus {
	return []models.BookingStatus{
		models.BookingStatusPending,
		models.BookingStatusConfirmed,
		models.BookingStatusCheckedIn,
		models.BookingStatusWaiting,
		models.BookingStatusNext,
		models.BookingStatusInProgress,
	}
}
