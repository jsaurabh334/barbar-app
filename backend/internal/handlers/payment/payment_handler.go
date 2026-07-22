package payment

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/barbar-app/backend/internal/config"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PaymentHandler struct {
	db         *gorm.DB
	cfg        *config.Config
	dispatcher notification.Dispatcher
}

func NewPaymentHandler(db *gorm.DB, cfg *config.Config, dispatcher notification.Dispatcher) *PaymentHandler {
	return &PaymentHandler{db: db, cfg: cfg, dispatcher: dispatcher}
}

type InitiatePaymentRequest struct {
	OrderID   uuid.UUID `json:"order_id"`
	BookingID uuid.UUID `json:"booking_id"`
	Gateway   string    `json:"gateway" binding:"required,oneof=razorpay stripe"`
}

func (h *PaymentHandler) InitiatePayment(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var req InitiatePaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	if req.OrderID == uuid.Nil && req.BookingID == uuid.Nil {
		utils.BadRequestResponse(c, "Either order_id or booking_id is required")
		return
	}

	var payment models.Payment

	// Determine target: Order or Booking
	if req.OrderID != uuid.Nil {
		var order models.Order
		if err := h.db.Where("id = ? AND customer_id = ?", req.OrderID, userID).First(&order).Error; err != nil {
			utils.NotFoundResponse(c, "Order not found")
			return
		}
		if order.PaymentStatus == models.PaymentStatusSuccess {
			utils.BadRequestResponse(c, "Order already paid")
			return
		}
		payment = models.Payment{
			OrderID:  order.ID,
			UserID:   userID,
			Amount:   order.FinalAmount,
			Gateway:  models.PaymentGateway(req.Gateway),
			Currency: "INR",
			Status:   models.PayStatusInitiated,
		}
	} else {
		var booking models.Booking
		if err := h.db.Where("id = ? AND customer_id = ?", req.BookingID, userID).First(&booking).Error; err != nil {
			utils.NotFoundResponse(c, "Booking not found")
			return
		}
		if booking.PaymentStatus == "paid" || booking.PaymentStatus == "success" {
			utils.BadRequestResponse(c, "Booking already paid")
			return
		}

		// Record the customer's payment method choice
		booking.PaymentMethod = "upi"
		h.db.Save(&booking)

		payment = models.Payment{
			OrderID:  booking.ID,
			UserID:   userID,
			Amount:   booking.FinalPrice,
			Gateway:  models.PaymentGateway(req.Gateway),
			Currency: "INR",
			Status:   models.PayStatusInitiated,
		}
	}

	if err := h.db.Create(&payment).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to create payment record")
		return
	}

	var result map[string]interface{}

	switch req.Gateway {
	case "razorpay":
		gatewayOrder, err := h.createRazorpayOrder(payment.Amount, payment.ID.String())
		if err != nil {
			payment.Status = models.PayStatusFailed
			payment.FailureReason = err.Error()
			h.db.Save(&payment)
			utils.InternalErrorResponse(c, "Failed to create payment: "+err.Error())
			return
		}

		gatewayOrderID, _ := gatewayOrder["id"].(string)
		payment.GatewayOrderID = gatewayOrderID
		h.db.Save(&payment)

		result = gin.H{
			"payment_id":       payment.ID,
			"gateway":          "razorpay",
			"gateway_order_id": gatewayOrderID,
			"amount":           payment.Amount,
			"key_id":           h.cfg.Razorpay.KeyID,
			"currency":         "INR",
			"order_id":         payment.OrderID,
			"receipt":          payment.ID.String(),
		}

	case "stripe":
		pi, err := h.createStripePaymentIntent(payment.Amount, payment.ID.String())
		if err != nil {
			payment.Status = models.PayStatusFailed
			payment.FailureReason = err.Error()
			h.db.Save(&payment)
			utils.InternalErrorResponse(c, "Failed to create payment: "+err.Error())
			return
		}

		piID, _ := pi["id"].(string)
		clientSecret, _ := pi["client_secret"].(string)
		payment.GatewayPaymentID = piID
		h.db.Save(&payment)

		result = gin.H{
			"payment_id":       payment.ID,
			"gateway":          "stripe",
			"client_secret":    clientSecret,
			"gateway_payment_id": piID,
			"amount":           payment.Amount,
			"currency":         "inr",
			"order_id":         payment.OrderID,
		}
	}

	utils.SuccessResponse(c, result)
}

func (h *PaymentHandler) VerifyPayment(c *gin.Context) {
	var req struct {
		Gateway          string  `json:"gateway" binding:"required"`
		GatewayOrderID   string  `json:"gateway_order_id"`
		GatewayPaymentID string  `json:"gateway_payment_id"`
		GatewaySignature string  `json:"gateway_signature"`
		PaymentID        string  `json:"payment_id"`
		RazorpayPaymentID string `json:"razorpay_payment_id"`
		RazorpayOrderID   string `json:"razorpay_order_id"`
		RazorpaySignature string `json:"razorpay_signature"`
		StripePaymentIntentID string `json:"stripe_payment_intent_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var payment models.Payment
	if req.PaymentID != "" {
		if err := h.db.Where("id = ?", req.PaymentID).First(&payment).Error; err != nil {
			utils.NotFoundResponse(c, "Payment record not found")
			return
		}
	} else if req.GatewayOrderID != "" {
		if err := h.db.Where("gateway_order_id = ?", req.GatewayOrderID).First(&payment).Error; err != nil {
			utils.NotFoundResponse(c, "Payment record not found")
			return
		}
	} else {
		utils.NotFoundResponse(c, "Payment not found")
		return
	}

	switch req.Gateway {
	case "razorpay":
		rOrderID := req.RazorpayOrderID
		rPaymentID := req.RazorpayPaymentID
		rSignature := req.RazorpaySignature

		if rOrderID == "" {
			rOrderID = req.GatewayOrderID
		}
		if rPaymentID == "" {
			rPaymentID = req.GatewayPaymentID
		}
		if rSignature == "" {
			rSignature = req.GatewaySignature
		}

		if rOrderID == "" || rPaymentID == "" {
			utils.BadRequestResponse(c, "Missing Razorpay verification fields")
			return
		}

		// Dev mode: skip signature verification when Razorpay not configured
		if h.cfg.Razorpay.KeySecret != "" {
			if rSignature == "" {
				utils.BadRequestResponse(c, "Missing payment signature")
				return
			}
			if !verifyRazorpaySignature(rOrderID, rPaymentID, rSignature, h.cfg.Razorpay.KeySecret) {
				utils.BadRequestResponse(c, "Payment signature verification failed")
				return
			}
		}

		payment.GatewayOrderID = rOrderID
		payment.GatewayPaymentID = rPaymentID
		payment.GatewaySignature = rSignature
		payment.Status = models.PayStatusSuccess

	case "stripe":
		piID := req.StripePaymentIntentID
		if piID == "" {
			piID = req.GatewayPaymentID
		}
		if piID == "" {
			utils.BadRequestResponse(c, "Missing Stripe PaymentIntent ID")
			return
		}

		pi, err := h.getStripePaymentIntent(piID)
		if err != nil {
			utils.InternalErrorResponse(c, "Failed to verify payment: "+err.Error())
			return
		}

		piStatus, _ := pi["status"].(string)
		if piStatus != "succeeded" {
			utils.BadRequestResponse(c, "Payment not successful. Status: "+piStatus)
			return
		}

		payment.GatewayPaymentID = piID
		payment.GatewayOrderID = piID
		payment.Status = models.PayStatusSuccess

	default:
		utils.BadRequestResponse(c, "Unsupported gateway")
		return
	}

	now := time.Now()
	payment.PaidAt = &now
	h.db.Save(&payment)

	h.updatePaymentTarget(payment)

	if h.dispatcher != nil {
		data := map[string]interface{}{
			"payment_id": payment.ID.String(),
			"amount":     payment.Amount,
		}
		// Check if it's a booking (no matching Order)
		var order models.Order
		if h.db.Where("id = ?", payment.OrderID).First(&order).Error != nil {
			data["booking_id"] = payment.OrderID.String()
		}
		h.dispatcher.Dispatch(c.Request.Context(), notification.NotificationEvent{
			Type:       models.NotifPaymentSuccess,
			ReceiverID: payment.UserID,
			Role:       notification.RoleCustomer,
			Data:       data,
		})
	}

	utils.SuccessResponse(c, gin.H{
		"message": "Payment verified",
		"payment": payment,
	})
}

func (h *PaymentHandler) PaymentWebhook(c *gin.Context) {
	gateway := c.Param("gateway")

	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.JSON(400, gin.H{"error": "Failed to read body"})
		return
	}

	var payload map[string]interface{}
	if err := json.Unmarshal(body, &payload); err != nil {
		c.JSON(400, gin.H{"error": "Invalid payload"})
		return
	}

	logEntry := models.PaymentGatewayLog{
		Gateway:   gateway,
		EventType: c.GetHeader("X-Event-Type"),
		Status:    "received",
		IPAddress: c.ClientIP(),
	}

	switch gateway {
	case "razorpay":
		signature := c.GetHeader("X-Razorpay-Signature")
		if signature != "" && h.cfg.Razorpay.KeySecret != "" {
			expected := hmacSHA256(string(body), h.cfg.Razorpay.KeySecret)
			if subtle.ConstantTimeCompare([]byte(signature), []byte(expected)) != 1 {
				logEntry.Status = "failed_verification"
				json.Unmarshal(body, &logEntry.Response)
				h.db.Create(&logEntry)
				c.JSON(403, gin.H{"error": "Invalid signature"})
				return
			}
		}
		h.processRazorpayWebhook(payload)

	case "stripe":
		sigHeader := c.GetHeader("Stripe-Signature")
		if sigHeader != "" && h.cfg.Stripe.WebhookSecret != "" {
			if !verifyStripeSignature(sigHeader, string(body), h.cfg.Stripe.WebhookSecret) {
				logEntry.Status = "failed_verification"
				json.Unmarshal(body, &logEntry.Response)
				h.db.Create(&logEntry)
				c.JSON(403, gin.H{"error": "Invalid signature"})
				return
			}
		}
		h.processStripeWebhook(payload)
	}

	logEntry.Status = "processed"
	json.Unmarshal(body, &logEntry.Response)
	h.db.Create(&logEntry)

	c.JSON(200, gin.H{"status": "ok"})
}

func (h *PaymentHandler) processRazorpayWebhook(payload map[string]interface{}) {
	event, _ := payload["event"].(string)
	if event == "" {
		return
	}

	switch event {
	case "payment.captured":
		paymentPayload, ok := payload["payload"].(map[string]interface{})["payment"].(map[string]interface{})
		if !ok {
			return
		}
		rpPaymentID, _ := paymentPayload["id"].(string)
		rpOrderID, _ := paymentPayload["order_id"].(string)
		amount, _ := paymentPayload["amount"].(float64)
		status, _ := paymentPayload["status"].(string)

		amount = amount / 100

		var payment models.Payment
		if err := h.db.Where("gateway_order_id = ?", rpOrderID).First(&payment).Error; err != nil {
			log.Printf("Razorpay webhook: payment not found for order %s", rpOrderID)
			return
		}

		payment.GatewayPaymentID = rpPaymentID
		payment.Status = models.PayStatusSuccess
		if status == "failed" {
			payment.Status = models.PayStatusFailed
			if failureReason, ok := paymentPayload["error_description"].(string); ok {
				payment.FailureReason = failureReason
			}
		} else {
			now := time.Now()
			payment.PaidAt = &now
		}
		h.db.Save(&payment)

		if payment.Status == models.PayStatusSuccess {
			h.updatePaymentTarget(payment)
			if h.dispatcher != nil {
				h.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
					Type:       models.NotifPaymentSuccess,
					ReceiverID: payment.UserID,
					Role:       notification.RoleCustomer,
					Data: map[string]interface{}{
						"payment_id": payment.ID.String(),
						"amount":     payment.Amount,
					},
				})
			}
		}

	case "payment.failed":
		paymentPayload, ok := payload["payload"].(map[string]interface{})["payment"].(map[string]interface{})
		if !ok {
			return
		}
		rpOrderID, _ := paymentPayload["order_id"].(string)
		rpPaymentID, _ := paymentPayload["id"].(string)

		var payment models.Payment
		if err := h.db.Where("gateway_order_id = ?", rpOrderID).First(&payment).Error; err != nil {
			return
		}
		payment.Status = models.PayStatusFailed
		payment.GatewayPaymentID = rpPaymentID
		if errDesc, ok := paymentPayload["error_description"].(string); ok {
			payment.FailureReason = errDesc
		}
		h.db.Save(&payment)

		h.db.Model(&models.Booking{}).Where("id = ?", payment.OrderID).Update("payment_status", "failed")

		if h.dispatcher != nil {
			h.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
				Type:       models.NotifPaymentFailed,
				ReceiverID: payment.UserID,
				Role:       notification.RoleCustomer,
				Data: map[string]interface{}{
					"payment_id": payment.ID.String(),
					"reason":     payment.FailureReason,
				},
			})
		}

	case "order.paid":
		orderPayload, ok := payload["payload"].(map[string]interface{})["order"].(map[string]interface{})
		if !ok {
			return
		}
		rpOrderID, _ := orderPayload["id"].(string)

		var payment models.Payment
		if err := h.db.Where("gateway_order_id = ?", rpOrderID).First(&payment).Error; err != nil {
			return
		}
		if payment.Status != models.PayStatusSuccess {
			now := time.Now()
			payment.Status = models.PayStatusSuccess
			payment.PaidAt = &now
			h.db.Save(&payment)

			h.updatePaymentTarget(payment)
			if h.dispatcher != nil {
				h.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
					Type:       models.NotifPaymentSuccess,
					ReceiverID: payment.UserID,
					Role:       notification.RoleCustomer,
					Data: map[string]interface{}{
						"payment_id": payment.ID.String(),
						"amount":     payment.Amount,
					},
				})
			}
		}
	}
}

func (h *PaymentHandler) processStripeWebhook(payload map[string]interface{}) {
	eventType, _ := payload["type"].(string)
	if eventType == "" {
		return
	}

	dataObj, ok := payload["data"].(map[string]interface{})["object"].(map[string]interface{})
	if !ok {
		return
	}

	switch eventType {
	case "payment_intent.succeeded":
		piID, _ := dataObj["id"].(string)
		amount, _ := dataObj["amount_received"].(float64)
		_ = amount

		var payment models.Payment
		if err := h.db.Where("gateway_payment_id = ?", piID).First(&payment).Error; err != nil {
			if err := h.db.Where("gateway_order_id = ?", piID).First(&payment).Error; err != nil {
				return
			}
		}

		now := time.Now()
		payment.Status = models.PayStatusSuccess
		payment.PaidAt = &now
		if chargeID, ok := dataObj["latest_charge"].(string); ok {
			payment.GatewaySignature = chargeID
		}
		h.db.Save(&payment)

		h.updatePaymentTarget(payment)

	case "payment_intent.payment_failed":
		piID, _ := dataObj["id"].(string)
		lastPaymentError, _ := dataObj["last_payment_error"].(map[string]interface{})

		var payment models.Payment
		if err := h.db.Where("gateway_payment_id = ?", piID).First(&payment).Error; err != nil {
			return
		}

		payment.Status = models.PayStatusFailed
		if lastPaymentError != nil {
			if msg, ok := lastPaymentError["message"].(string); ok {
				payment.FailureReason = msg
			}
		}
		h.db.Save(&payment)

		// On failure, update both Order and Booking targets
		h.db.Model(&models.Order{}).Where("id = ?", payment.OrderID).Update("payment_status", models.PaymentStatusFailed)
		h.db.Model(&models.Booking{}).Where("id = ?", payment.OrderID).Update("payment_status", "failed")
	}
}

func (h *PaymentHandler) GetPaymentStatus(c *gin.Context) {
	orderID, err := uuid.Parse(c.Param("order_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var payment models.Payment
	if err := h.db.Where("order_id = ?", orderID).First(&payment).Error; err != nil {
		utils.NotFoundResponse(c, "Payment not found")
		return
	}

	utils.SuccessResponse(c, payment)
}

func (h *PaymentHandler) Refund(c *gin.Context) {
	paymentID, err := uuid.Parse(c.Param("payment_id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid payment ID")
		return
	}

	var req struct {
		Amount float64 `json:"amount"`
		Reason string  `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var payment models.Payment
	if err := h.db.First(&payment, paymentID).Error; err != nil {
		utils.NotFoundResponse(c, "Payment not found")
		return
	}

	if payment.Status != models.PayStatusSuccess {
		utils.BadRequestResponse(c, "Payment is not in a refundable state")
		return
	}

	refundAmount := req.Amount
	if refundAmount <= 0 || refundAmount > payment.Amount {
		refundAmount = payment.Amount
	}

	var gatewayRefundID string

	switch payment.Gateway {
	case models.GatewayRazorpay:
		id, err := h.processRazorpayRefund(payment.GatewayPaymentID, refundAmount, req.Reason)
		if err != nil {
			utils.InternalErrorResponse(c, "Refund failed: "+err.Error())
			return
		}
		gatewayRefundID = id

	case models.GatewayStripe:
		id, err := h.processStripeRefund(payment.GatewayPaymentID, refundAmount, req.Reason)
		if err != nil {
			utils.InternalErrorResponse(c, "Refund failed: "+err.Error())
			return
		}
		gatewayRefundID = id

	case models.GatewayCash:
		gatewayRefundID = "CASH_REFUND_" + uuid.New().String()
	}

	now := time.Now()
	payment.RefundAmount = refundAmount
	payment.RefundStatus = "processed"
	payment.RefundedAt = &now
	payment.GatewaySignature = gatewayRefundID
	h.db.Save(&payment)

	h.db.Model(&models.Order{}).Where("id = ?", payment.OrderID).Update("payment_status", models.PaymentStatusRefunded)

	if h.dispatcher != nil {
		h.dispatcher.Dispatch(context.Background(), notification.NotificationEvent{
			Type:       models.NotifRefundCompleted,
			ReceiverID: payment.UserID,
			Role:       notification.RoleCustomer,
			Data: map[string]interface{}{
				"payment_id": payment.ID.String(),
				"amount":     refundAmount,
			},
		})
	}

	utils.SuccessResponse(c, gin.H{
		"message":   "Refund processed",
		"amount":    refundAmount,
		"refund_id": gatewayRefundID,
	})
}

// ==================== Razorpay API ====================

func (h *PaymentHandler) createRazorpayOrder(amount float64, receipt string) (map[string]interface{}, error) {
	amountPaise := int64(amount * 100)

	// Dev mode: return mock order when Razorpay not configured
	if h.cfg.Razorpay.KeyID == "" || h.cfg.Razorpay.KeySecret == "" {
		return map[string]interface{}{
			"id":       "mock_order_" + receipt,
			"amount":   amountPaise,
			"currency": "INR",
			"status":   "created",
		}, nil
	}

	reqBody := map[string]interface{}{
		"amount":          amountPaise,
		"currency":        "INR",
		"receipt":         receipt,
		"partial_payment": false,
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req, _ := http.NewRequest("POST", "https://api.razorpay.com/v1/orders", bytes.NewBuffer(bodyBytes))
	req.SetBasicAuth(h.cfg.Razorpay.KeyID, h.cfg.Razorpay.KeySecret)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("razorpay API error: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	if resp.StatusCode >= 400 {
		errMsg, _ := json.Marshal(result)
		return nil, fmt.Errorf("razorpay error %d: %s", resp.StatusCode, string(errMsg))
	}

	return result, nil
}

func (h *PaymentHandler) processRazorpayRefund(paymentID string, amount float64, reason string) (string, error) {
	amountPaise := int64(amount * 100)

	reqBody := map[string]interface{}{
		"amount":  amountPaise,
		"speed":   "normal",
	}
	if reason != "" {
		reqBody["notes"] = map[string]string{"reason": reason}
	}
	bodyBytes, _ := json.Marshal(reqBody)

	url := fmt.Sprintf("https://api.razorpay.com/v1/payments/%s/refund", paymentID)
	req, _ := http.NewRequest("POST", url, bytes.NewBuffer(bodyBytes))
	req.SetBasicAuth(h.cfg.Razorpay.KeyID, h.cfg.Razorpay.KeySecret)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("razorpay refund error: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	if resp.StatusCode >= 400 {
		errMsg, _ := json.Marshal(result)
		return "", fmt.Errorf("razorpay refund error %d: %s", resp.StatusCode, string(errMsg))
	}

	refundID, _ := result["id"].(string)
	return refundID, nil
}

// ==================== Stripe API ====================

func (h *PaymentHandler) createStripePaymentIntent(amount float64, metadataID string) (map[string]interface{}, error) {
	amountCents := int64(amount * 100)

	// Dev mode: return mock PaymentIntent when Stripe not configured
	if h.cfg.Stripe.SecretKey == "" {
		return map[string]interface{}{
			"id":            "mock_pi_" + metadataID,
			"amount":        amountCents,
			"currency":      "inr",
			"status":        "requires_payment_method",
			"client_secret": "mock_secret_" + metadataID,
		}, nil
	}

	form := fmt.Sprintf("amount=%d&currency=inr&metadata[payment_id]=%s&automatic_payment_methods[enabled]=true", amountCents, metadataID)
	req, _ := http.NewRequest("POST", "https://api.stripe.com/v1/payment_intents", bytes.NewBufferString(form))
	req.Header.Set("Authorization", "Bearer "+h.cfg.Stripe.SecretKey)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("stripe API error: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	if resp.StatusCode >= 400 {
		errMsg, _ := json.Marshal(result)
		return nil, fmt.Errorf("stripe error %d: %s", resp.StatusCode, string(errMsg))
	}

	return result, nil
}

func (h *PaymentHandler) getStripePaymentIntent(piID string) (map[string]interface{}, error) {
	url := fmt.Sprintf("https://api.stripe.com/v1/payment_intents/%s", piID)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Authorization", "Bearer "+h.cfg.Stripe.SecretKey)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("stripe API error: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	if resp.StatusCode >= 400 {
		errMsg, _ := json.Marshal(result)
		return nil, fmt.Errorf("stripe error %d: %s", resp.StatusCode, string(errMsg))
	}

	return result, nil
}

func (h *PaymentHandler) processStripeRefund(paymentIntentID string, amount float64, reason string) (string, error) {
	amountCents := int64(amount * 100)

	form := fmt.Sprintf("payment_intent=%s&amount=%d", paymentIntentID, amountCents)
	if reason != "" {
		form += "&reason=" + urlEncode(reason)
	}

	req, _ := http.NewRequest("POST", "https://api.stripe.com/v1/refunds", bytes.NewBufferString(form))
	req.Header.Set("Authorization", "Bearer "+h.cfg.Stripe.SecretKey)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("stripe refund error: %w", err)
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	if resp.StatusCode >= 400 {
		errMsg, _ := json.Marshal(result)
		return "", fmt.Errorf("stripe refund error %d: %s", resp.StatusCode, string(errMsg))
	}

	refundID, _ := result["id"].(string)
	return refundID, nil
}

// ==================== Helpers ====================

func verifyRazorpaySignature(orderID, paymentID, signature, secret string) bool {
	data := orderID + "|" + paymentID
	expected := hmacSHA256(data, secret)
	return subtle.ConstantTimeCompare([]byte(signature), []byte(expected)) == 1
}

func verifyStripeSignature(sigHeader, payload, webhookSecret string) bool {
	parts := strings.Split(sigHeader, ",")
	var sig string
	var timestamp string
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if strings.HasPrefix(part, "v1=") {
			sig = strings.TrimPrefix(part, "v1=")
		} else if strings.HasPrefix(part, "t=") {
			timestamp = strings.TrimPrefix(part, "t=")
		}
	}

	if sig == "" || timestamp == "" {
		return false
	}

	signedPayload := timestamp + "." + payload
	expected := hmacSHA256(signedPayload, webhookSecret)
	return subtle.ConstantTimeCompare([]byte(sig), []byte(expected)) == 1
}

// updatePaymentTarget updates the payment status on the target model (Order or Booking)
// based on the Payment record's OrderID field.
func (h *PaymentHandler) updatePaymentTarget(payment models.Payment) {
	var order models.Order
	if h.db.Where("id = ?", payment.OrderID).First(&order).Error == nil {
		h.db.Model(&models.Order{}).Where("id = ?", payment.OrderID).Updates(map[string]interface{}{
			"payment_status": models.PaymentStatusSuccess,
			"payment_id":     payment.ID.String(),
		})
		if order.Status != models.OrderStatusDelivered && order.Status != models.OrderStatusShipped {
			h.db.Model(&models.Order{}).Where("id = ?", payment.OrderID).Update("status", models.OrderStatusConfirmed)
		}
		return
	}

	h.db.Model(&models.Booking{}).Where("id = ?", payment.OrderID).Updates(map[string]interface{}{
		"payment_status": "paid",
		"payment_id":     payment.ID.String(),
	})
}

func hmacSHA256(data, key string) string {
	mac := hmac.New(sha256.New, []byte(key))
	mac.Write([]byte(data))
	return hex.EncodeToString(mac.Sum(nil))
}

func urlEncode(s string) string {
	encoded := ""
	for _, c := range []byte(s) {
		if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~' {
			encoded += string(c)
		} else {
			encoded += fmt.Sprintf("%%%02X", c)
		}
	}
	return encoded
}


