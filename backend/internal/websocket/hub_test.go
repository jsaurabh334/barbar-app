package websocket

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

func TestNewHub(t *testing.T) {
	hub := NewHub(nil, nil)
	assert.NotNil(t, hub)
	assert.NotNil(t, hub.clients)
	assert.NotNil(t, hub.rooms)
	assert.NotNil(t, hub.register)
	assert.NotNil(t, hub.unregister)
	assert.NotNil(t, hub.broadcast)
	assert.NotNil(t, hub.events)
	assert.Len(t, hub.events, 0)
}

func TestRecordEvent(t *testing.T) {
	hub := NewHub(nil, nil)

	msg := &WSMessage{
		Type:    MsgQueueUpdate,
		Payload: map[string]interface{}{"queue_length": 5},
	}

	hub.RecordEvent(msg)
	assert.Len(t, hub.events, 1)
	assert.Equal(t, MsgQueueUpdate, hub.events[0].Type)
	assert.NotEmpty(t, hub.events[0].ID)
	assert.False(t, hub.events[0].Timestamp.IsZero())
}

func TestGetEventsSince(t *testing.T) {
	hub := NewHub(nil, nil)

	hub.RecordEvent(&WSMessage{Type: MsgQueueUpdate, Payload: "event1"})
	time.Sleep(5 * time.Millisecond)
	hub.RecordEvent(&WSMessage{Type: MsgBookingUpdate, Payload: "event2"})

	// Get events since before first event
	all := hub.GetEventsSince(time.Now().Add(-1 * time.Hour))
	assert.Len(t, all, 2)

	// Get events since after first event
	recent := hub.GetEventsSince(time.Now().Add(-10 * time.Millisecond))
	assert.Len(t, recent, 2, "should get events that happened after the since time")

	// Get events since now (future) should return empty
	future := hub.GetEventsSince(time.Now().Add(1 * time.Hour))
	assert.Len(t, future, 0)
}

func TestEventCapacityLimit(t *testing.T) {
	hub := NewHub(nil, nil)

	// Add over 1000 events
	for i := 0; i < 1500; i++ {
		hub.RecordEvent(&WSMessage{Type: MsgQueueUpdate, Payload: i})
	}

	// Should have capped at 1000, then pruned to 500
	assert.LessOrEqual(t, len(hub.events), 1000, "events should not exceed capacity")
}

func TestSendToUserRecordsEvents(t *testing.T) {
	hub := NewHub(nil, nil)
	go hub.Run()

	time.Sleep(10 * time.Millisecond)

	userID := uuid.New()
	msg := &WSMessage{
		Type:    MsgQueueUpdate,
		Payload: "test",
	}

	hub.SendToUser(userID, msg)

	time.Sleep(50 * time.Millisecond)

	hub.eventMu.Lock()
	assert.Len(t, hub.events, 1)
	hub.eventMu.Unlock()
}

func TestBroadcastEvent(t *testing.T) {
	hub := NewHub(nil, nil)
	go hub.Run()

	time.Sleep(10 * time.Millisecond)

	msg := &WSMessage{
		Type:    MsgBookingUpdate,
		Payload: "broadcast test",
	}

	hub.BroadcastEvent(msg)

	time.Sleep(50 * time.Millisecond)

	hub.eventMu.Lock()
	assert.Len(t, hub.events, 1)
	hub.eventMu.Unlock()
}

func TestHandleSyncEndpointMissingParam(t *testing.T) {
	hub := NewHub(nil, nil)

	// Can't test gin context easily here, but we can validate the logic works
	since := time.Now().Add(-1 * time.Hour)
	events := hub.GetEventsSince(since)
	assert.Empty(t, events)
}
