package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/config"
	"github.com/gorilla/websocket"
	"github.com/google/uuid"
)

type MessageType string

const (
	MsgQueueUpdate    MessageType = "queue_update"
	MsgBookingUpdate  MessageType = "booking_update"
	MsgStatusChange   MessageType = "status_change"
	MsgWaitTimeChange MessageType = "wait_time_change"
	MsgNotification   MessageType = "notification"
	MsgOrderUpdate    MessageType = "order_update"
	MsgVendorUpdate   MessageType = "vendor_update"
	MsgAdminAlert     MessageType = "admin_alert"
	MsgDriverOnline   MessageType = "driver.online"
	MsgDriverOffline  MessageType = "driver.offline"
	MsgDriverBusy     MessageType = "driver.busy"
	MsgDriverAvailable MessageType = "driver.available"
	MsgDriverLocation  MessageType = "driver.location_updated"
	MsgOrderStatusChanged  MessageType = "order.status_changed"
	MsgDeliveryOTPGenerated MessageType = "delivery_otp_generated"
)

type WSMessage struct {
	Type    MessageType  `json:"type"`
	Payload interface{} `json:"payload"`
	Room    string      `json:"room,omitempty"`
}

type Client struct {
	ID       uuid.UUID
	UserID   uuid.UUID
	Role     string
	Conn     *websocket.Conn
	Hub      *Hub
	Rooms    map[string]bool
	Send     chan []byte
	LastPong time.Time
	mu       sync.Mutex
}

type Hub struct {
	cfg      *config.Config
	jwt      *auth.JWTManager
	clients  map[uuid.UUID]*Client
	rooms    map[string]map[uuid.UUID]*Client
	register chan *Client
	unregister chan *Client
	broadcast chan *WSMessage
	mu       sync.RWMutex
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func NewHub(cfg *config.Config, jwt *auth.JWTManager) *Hub {
	return &Hub{
		cfg:        cfg,
		jwt:        jwt,
		clients:    make(map[uuid.UUID]*Client),
		rooms:      make(map[string]map[uuid.UUID]*Client),
		register:   make(chan *Client, 100),
		unregister: make(chan *Client, 100),
		broadcast:  make(chan *WSMessage, 100),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.ID] = client
			h.mu.Unlock()
			log.Printf("WebSocket client connected: %s (user: %s)", client.ID, client.UserID)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.ID]; ok {
				for room := range client.Rooms {
					if clients, ok := h.rooms[room]; ok {
						delete(clients, client.ID)
					}
				}
				delete(h.clients, client.ID)
				close(client.Send)
			}
			h.mu.Unlock()
			log.Printf("WebSocket client disconnected: %s", client.ID)

		case message := <-h.broadcast:
			h.mu.Lock()
			if message.Room != "" {
				// Send to room
				if clients, ok := h.rooms[message.Room]; ok {
					data, _ := json.Marshal(message)
					for _, client := range clients {
						select {
						case client.Send <- data:
						default:
							close(client.Send)
							delete(h.clients, client.ID)
						}
					}
				}
			} else {
				// Broadcast all
				data, _ := json.Marshal(message)
				for _, client := range h.clients {
					select {
					case client.Send <- data:
					default:
						close(client.Send)
						delete(h.clients, client.ID)
					}
				}
			}
			h.mu.Unlock()
		}
	}
}

func (h *Hub) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	if token == "" {
		http.Error(w, "Authentication required", http.StatusUnauthorized)
		return
	}

	claims, err := h.jwt.ValidateToken(token, auth.AccessToken)
	if err != nil {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &Client{
		ID:       uuid.New(),
		UserID:   claims.UserID,
		Role:     claims.Role,
		Conn:     conn,
		Hub:      h,
		Rooms:    make(map[string]bool),
		Send:     make(chan []byte, 256),
		LastPong: time.Now(),
	}

	// Auto-join rooms based on role
	client.Rooms["user:"+claims.UserID.String()] = true
	h.addToRoom("user:"+claims.UserID.String(), client)

	if claims.Role == "barber" || claims.Role == "admin" {
		client.Rooms["barbers"] = true
		h.addToRoom("barbers", client)
	}
	if claims.Role == "vendor" {
		client.Rooms["vendors"] = true
		h.addToRoom("vendors", client)
	}
	if claims.Role == "delivery" {
		client.Rooms["delivery"] = true
		h.addToRoom("delivery", client)
	}
	if claims.Role == "admin" || claims.Role == "super_admin" {
		client.Rooms["admins"] = true
		h.addToRoom("admins", client)
	}

	h.register <- client

	go client.writePump()
	go client.readPump()
}

func (h *Hub) addToRoom(room string, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.rooms[room] == nil {
		h.rooms[room] = make(map[uuid.UUID]*Client)
	}
	h.rooms[room][client.ID] = client
}

func (h *Hub) SendToUser(userID uuid.UUID, msg *WSMessage) {
	room := "user:" + userID.String()
	msg.Room = room
	h.broadcast <- msg
}

func (h *Hub) SendToRoom(room string, msg *WSMessage) {
	msg.Room = room
	h.broadcast <- msg
}

func (h *Hub) BroadcastToRole(role string, msg *WSMessage) {
	switch role {
	case "barber":
		msg.Room = "barbers"
	case "vendor":
		msg.Room = "vendors"
	case "delivery":
		msg.Room = "delivery"
	case "admin", "super_admin":
		msg.Room = "admins"
	default:
		return
	}
	h.broadcast <- msg
}

func (c *Client) readPump() {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(4096)
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.LastPong = time.Now()
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			break
		}

		var msg WSMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			continue
		}

		// Handle client messages
		switch msg.Type {
		case "ping":
			c.Send <- []byte(`{"type":"pong"}`)
		case "join_room":
			if room, ok := msg.Payload.(string); ok {
				c.Rooms[room] = true
				c.Hub.addToRoom(room, c)
			}
		case "subscribe_barber":
			if barberID, ok := msg.Payload.(string); ok {
				c.Rooms["barber:"+barberID] = true
				c.Hub.addToRoom("barber:"+barberID, c)
			}
		case "subscribe_order":
			if orderID, ok := msg.Payload.(string); ok {
				c.Rooms["order:"+orderID] = true
				c.Hub.addToRoom("order:"+orderID, c)
			}
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
