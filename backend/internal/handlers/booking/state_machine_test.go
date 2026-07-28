package booking

import (
	"testing"

	"github.com/barbar-app/backend/internal/models"
	"github.com/stretchr/testify/assert"
)

func TestIsValidTransition(t *testing.T) {
	tests := []struct {
		name     string
		from     models.BookingStatus
		to       models.BookingStatus
		expected bool
	}{
		{"pending -> confirmed", models.BookingStatusPending, models.BookingStatusConfirmed, true},
		{"pending -> cancelled", models.BookingStatusPending, models.BookingStatusCancelled, true},
		{"pending -> in_progress", models.BookingStatusPending, models.BookingStatusInProgress, false},
		{"confirmed -> checked_in", models.BookingStatusConfirmed, models.BookingStatusCheckedIn, true},
		{"confirmed -> cancelled", models.BookingStatusConfirmed, models.BookingStatusCancelled, true},
		{"confirmed -> no_show", models.BookingStatusConfirmed, models.BookingStatusNoShow, true},
		{"confirmed -> completed", models.BookingStatusConfirmed, models.BookingStatusCompleted, false},
		{"checked_in -> waiting", models.BookingStatusCheckedIn, models.BookingStatusWaiting, true},
		{"checked_in -> cancelled", models.BookingStatusCheckedIn, models.BookingStatusCancelled, true},
		{"checked_in -> no_show", models.BookingStatusCheckedIn, models.BookingStatusNoShow, true},
		{"waiting -> next", models.BookingStatusWaiting, models.BookingStatusNext, true},
		{"waiting -> cancelled", models.BookingStatusWaiting, models.BookingStatusCancelled, true},
		{"next -> in_progress", models.BookingStatusNext, models.BookingStatusInProgress, true},
		{"next -> cancelled", models.BookingStatusNext, models.BookingStatusCancelled, true},
		{"in_progress -> completed", models.BookingStatusInProgress, models.BookingStatusCompleted, true},
		{"in_progress -> cancelled", models.BookingStatusInProgress, models.BookingStatusCancelled, false},
		{"completed -> in_progress", models.BookingStatusCompleted, models.BookingStatusInProgress, false},
		{"completed -> cancelled", models.BookingStatusCompleted, models.BookingStatusCancelled, false},
		{"cancelled -> confirmed", models.BookingStatusCancelled, models.BookingStatusConfirmed, false},
		{"no_show -> confirmed", models.BookingStatusNoShow, models.BookingStatusConfirmed, false},
		{"rescheduled -> pending", models.BookingStatusRescheduled, models.BookingStatusPending, true},
		{"rescheduled -> cancelled", models.BookingStatusRescheduled, models.BookingStatusCancelled, true},
		{"home_service_pending -> confirmed", models.BookingStatusHomeServicePending, models.BookingStatusConfirmed, true},
		{"home_service_pending -> cancelled", models.BookingStatusHomeServicePending, models.BookingStatusCancelled, true},
		{"unknown -> anything", models.BookingStatus("unknown"), models.BookingStatusConfirmed, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := IsValidTransition(tt.from, tt.to)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestValidateTransition(t *testing.T) {
	assert.NoError(t, ValidateTransition(models.BookingStatusPending, models.BookingStatusConfirmed))
	assert.Error(t, ValidateTransition(models.BookingStatusPending, models.BookingStatusCompleted))
	assert.Error(t, ValidateTransition(models.BookingStatusCompleted, models.BookingStatusPending))
	assert.Contains(t, ValidateTransition(models.BookingStatusPending, models.BookingStatusCompleted).Error(), "invalid booking status transition")
}

func TestQueueAndActiveStatuses(t *testing.T) {
	queue := QueueStatuses()
	assert.Contains(t, queue, models.BookingStatusCheckedIn)
	assert.Contains(t, queue, models.BookingStatusWaiting)
	assert.Contains(t, queue, models.BookingStatusNext)
	assert.Contains(t, queue, models.BookingStatusInProgress)
	assert.NotContains(t, queue, models.BookingStatusConfirmed)
	assert.NotContains(t, queue, models.BookingStatusCompleted)

	active := ActiveStatuses()
	assert.Contains(t, active, models.BookingStatusPending)
	assert.Contains(t, active, models.BookingStatusConfirmed)
	assert.Contains(t, active, models.BookingStatusCheckedIn)
	assert.Contains(t, active, models.BookingStatusInProgress)
	assert.NotContains(t, active, models.BookingStatusCompleted)
	assert.NotContains(t, active, models.BookingStatusCancelled)

	assert.Subset(t, active, queue, "queue statuses should be a subset of active statuses")
}
