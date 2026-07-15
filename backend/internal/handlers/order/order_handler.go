package order

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/auth"
	"github.com/barbar-app/backend/internal/models"
	"github.com/barbar-app/backend/internal/services/notification"
	"github.com/barbar-app/backend/internal/utils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type OrderHandler struct {
	db         *gorm.DB
	dispatcher notification.Dispatcher
}

func NewOrderHandler(db *gorm.DB, dispatcher notification.Dispatcher) *OrderHandler {
	return &OrderHandler{db: db, dispatcher: dispatcher}
}

type PlaceOrderRequest struct {
	Items             []OrderItemInput `json:"items" binding:"required,min=1,dive"`
	ShippingAddressID *uuid.UUID       `json:"shipping_address_id"`
	CouponCode        string           `json:"coupon_code"`
	WalletAmount      float64          `json:"wallet_amount"`
	PaymentMethod     string           `json:"payment_method" binding:"required"`
	Notes             string           `json:"notes"`
	Address           *AddressInput    `json:"address,omitempty"`
}

type OrderItemInput struct {
	ProductID uuid.UUID `json:"product_id" binding:"required"`
	VariantID *uuid.UUID `json:"variant_id"`
	Quantity  int        `json:"quantity" binding:"required,min=1"`
}

type AddressInput struct {
	FullName  string `json:"full_name" binding:"required"`
	Phone     string `json:"phone" binding:"required"`
	Pincode   string `json:"pincode" binding:"required"`
	Line1     string `json:"line_1" binding:"required"`
	Line2     string `json:"line_2"`
	Landmark  string `json:"landmark"`
	City      string `json:"city" binding:"required"`
	State     string `json:"state" binding:"required"`
	Label     string `json:"label"`
}

func (h *OrderHandler) PlaceOrder(c *gin.Context) {
	customerID := c.MustGet("user").(uuid.UUID)

	var req PlaceOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input: "+err.Error())
		return
	}

	// Validate and group items by vendor
	type vendorItems struct {
		vendor models.Vendor
		items  []OrderItemInput
		pAmount float64
	}

	vendorMap := make(map[uuid.UUID]*vendorItems)
	var totalAmount float64

	for _, item := range req.Items {
		var product models.Product
		if err := h.db.Where("id = ? AND is_active = ? AND is_approved = ?", item.ProductID, true, true).First(&product).Error; err != nil {
			utils.BadRequestResponse(c, fmt.Sprintf("Product %s not found or unavailable", item.ProductID))
			return
		}

		if product.AvailableStock < item.Quantity {
			utils.BadRequestResponse(c, fmt.Sprintf("Insufficient stock for %s", product.Name))
			return
		}

		unitPrice := product.BasePrice
		if product.DiscountPrice > 0 {
			unitPrice = product.DiscountPrice
		}

		if item.VariantID != nil {
			var variant models.ProductVariant
			if err := h.db.Where("id = ? AND product_id = ? AND is_active = ?", *item.VariantID, product.ID, true).First(&variant).Error; err != nil {
				utils.BadRequestResponse(c, "Variant not found")
				return
			}
			if variant.Stock < item.Quantity {
				utils.BadRequestResponse(c, fmt.Sprintf("Insufficient stock for variant %s", variant.Name))
				return
			}
			unitPrice = variant.Price
			if variant.DiscountPrice > 0 {
				unitPrice = variant.DiscountPrice
			}
		}

		itemTotal := unitPrice * float64(item.Quantity)
		totalAmount += itemTotal

		if _, exists := vendorMap[product.VendorID]; !exists {
			var vendor models.Vendor
			h.db.First(&vendor, product.VendorID)
			vendorMap[product.VendorID] = &vendorItems{vendor: vendor, items: []OrderItemInput{}, pAmount: 0}
		}
		vendorMap[product.VendorID].items = append(vendorMap[product.VendorID].items, item)
		vendorMap[product.VendorID].pAmount += itemTotal
	}

	// Handle coupon
	var discountAmount float64
	var couponCode string
	if req.CouponCode != "" {
		var coupon models.Coupon
		if err := h.db.Where("code = ? AND is_active = ? AND valid_from <= ? AND valid_to >= ?",
			req.CouponCode, true, time.Now(), time.Now()).First(&coupon).Error; err == nil {
			if coupon.UsedCount < coupon.UsageLimit || coupon.UsageLimit == 0 {
				if totalAmount >= coupon.MinOrderAmount {
					switch coupon.Type {
					case models.CouponTypePercentage:
						discountAmount = totalAmount * coupon.Value / 100
						if coupon.MaxDiscount > 0 && discountAmount > coupon.MaxDiscount {
							discountAmount = coupon.MaxDiscount
						}
					case models.CouponTypeFixed:
						discountAmount = coupon.Value
					}
					couponCode = req.CouponCode
				}
			}
		}
	}

	// Handle wallet
	var walletUsed float64
	if req.WalletAmount > 0 {
		var wallet models.Wallet
		if err := h.db.Where("user_id = ?", customerID).First(&wallet).Error; err == nil {
			netPayable := totalAmount - discountAmount
			if req.WalletAmount > netPayable {
				walletUsed = netPayable
			} else {
				walletUsed = req.WalletAmount
			}
			if walletUsed > 0 {
				h.db.Model(&wallet).Update("balance", gorm.Expr("balance - ?", walletUsed))
				h.db.Create(&models.WalletTransaction{
					WalletID: wallet.ID,
					TxnType:  models.TxnTypeDebit,
					Amount:   walletUsed,
					ReferenceType: models.TxnRefOrder,
					Description: "Order payment via wallet",
				})
			}
		}
	}

	// Handle shipping address
	var shippingAddressID *uuid.UUID
	if req.ShippingAddressID != nil {
		shippingAddressID = req.ShippingAddressID
	} else if req.Address != nil {
		addr := models.Address{
			UserID:   customerID,
			Label:    req.Address.Label,
			FullName: req.Address.FullName,
			Phone:    req.Address.Phone,
			Pincode:  req.Address.Pincode,
			Line1:    req.Address.Line1,
			Line2:    req.Address.Line2,
			Landmark: req.Address.Landmark,
			City:     req.Address.City,
			State:    req.Address.State,
		}
		h.db.Create(&addr)
		shippingAddressID = &addr.ID
	}

	tx := h.db.Begin()
	var orders []models.Order

	for _, vi := range vendorMap {
		order := models.Order{
			CustomerID:        customerID,
			VendorID:          vi.vendor.ID,
			OrderNumber:       generateOrderNumber(),
			Status:            models.OrderStatusPending,
			PaymentMethod:     req.PaymentMethod,
			ShippingAddressID: shippingAddressID,
			CouponCode:        couponCode,
			CouponDiscount:    discountAmount,
			WalletUsed:        walletUsed,
			DeliveryNotes:     req.Notes,
		}

		var orderTotal float64
		for _, item := range vi.items {
			var product models.Product
			h.db.First(&product, item.ProductID)

			unitPrice := product.BasePrice
			if product.DiscountPrice > 0 {
				unitPrice = product.DiscountPrice
			}
			variantName := ""
			if item.VariantID != nil {
				var variant models.ProductVariant
				h.db.First(&variant, *item.VariantID)
				unitPrice = variant.Price
				if variant.DiscountPrice > 0 {
					unitPrice = variant.DiscountPrice
				}
				variantName = variant.Name + ": " + variant.Value
			}

			itemTotal := unitPrice * float64(item.Quantity)
			orderTotal += itemTotal

			productImage := ""
			if len(product.Images) > 0 {
				productImage = product.Images[0].ImageURL
			}

			orderItem := models.OrderItem{
				ProductID:    item.ProductID,
				VariantID:    item.VariantID,
				ProductName:  product.Name,
				VariantName:  variantName,
				ProductImage: productImage,
				Quantity:     item.Quantity,
				UnitPrice:    unitPrice,
				TotalPrice:   itemTotal,
			}
			order.Items = append(order.Items, orderItem)

			// Decrease stock
			if item.VariantID != nil {
				tx.Model(&models.ProductVariant{}).Where("id = ?", *item.VariantID).
					Updates(map[string]interface{}{
						"stock":          gorm.Expr("stock - ?", item.Quantity),
						"reserved_stock": gorm.Expr("reserved_stock + ?", item.Quantity),
					})
			}
			tx.Model(&models.Product{}).Where("id = ?", item.ProductID).
				Updates(map[string]interface{}{
					"available_stock": gorm.Expr("available_stock - ?", item.Quantity),
					"reserved_stock":  gorm.Expr("reserved_stock + ?", item.Quantity),
					"sold_count":      gorm.Expr("sold_count + ?", item.Quantity),
				})
		}

		shippingCharge := getShippingCharge(orderTotal)
		taxAmount := orderTotal * 0.18
		finalAmount := orderTotal + shippingCharge + taxAmount
		vendorDiscount := discountAmount * (orderTotal / totalAmount)
		vendorWalletUsed := walletUsed * (orderTotal / totalAmount)

		order.ItemsTotal = orderTotal
		order.ShippingCharge = shippingCharge
		order.TaxAmount = taxAmount
		order.CouponDiscount = vendorDiscount
		order.WalletUsed = vendorWalletUsed
		order.FinalAmount = finalAmount - vendorDiscount - vendorWalletUsed
		order.CommissionAmount = orderTotal * vi.vendor.CommissionRate
		order.VendorEarnings = orderTotal - order.CommissionAmount - vendorDiscount

		if err := tx.Create(&order).Error; err != nil {
			tx.Rollback()
			utils.InternalErrorResponse(c, "Failed to create order")
			return
		}

		orders = append(orders, order)
	}

	tx.Commit()

	for _, o := range orders {
		h.dispatchOrderEvent(c.Request.Context(), o, models.NotifOrderPlaced)
	}

	// Update coupon usage
	if couponCode != "" {
		h.db.Model(&models.Coupon{}).Where("code = ?", couponCode).Update("used_count", gorm.Expr("used_count + 1"))
	}

	utils.CreatedResponse(c, gin.H{
		"orders": orders,
		"message": "Orders placed successfully",
	})
}

func (h *OrderHandler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var order models.Order
	if err := h.db.Preload("Items").Preload("StatusLog").Preload("ShippingAddress").Preload("Payment").First(&order, id).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	utils.SuccessResponse(c, order)
}

func (h *OrderHandler) ListMyOrders(c *gin.Context) {
	customerID := c.MustGet("user").(uuid.UUID)
	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")

	var orders []models.Order
	var total int64

	query := h.db.Where("customer_id = ?", customerID)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	query.Model(&models.Order{}).Count(&total)
	query.Preload("Items").Preload("Vendor").
		Offset((page-1)*pageSize).Limit(pageSize).
		Order("created_at DESC").Find(&orders)

	utils.PaginatedResponse(c, orders, page, pageSize, total)
}

func (h *OrderHandler) ListVendorOrders(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	var vendor models.Vendor
	if err := h.db.Where("user_id = ?", userID).First(&vendor).Error; err != nil {
		utils.NotFoundResponse(c, "Vendor profile not found")
		return
	}

	page, pageSize := utils.GetPageParams(c)
	status := c.Query("status")

	var orders []models.Order
	var total int64

	query := h.db.Where("vendor_id = ?", vendor.ID)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	query.Model(&models.Order{}).Count(&total)
	query.Preload("Items").Preload("Customer").
		Offset((page-1)*pageSize).Limit(pageSize).
		Order("created_at DESC").Find(&orders)

	utils.PaginatedResponse(c, orders, page, pageSize, total)
}

func (h *OrderHandler) UpdateStatus(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)
	claims := c.MustGet("claims").(*auth.Claims)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var req struct {
		Status string `json:"status" binding:"required"`
		Note   string `json:"note"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var order models.Order
	if err := h.db.First(&order, id).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	fromStatus := order.Status
	order.Status = models.OrderStatus(req.Status)

	now := time.Now()
	if req.Status == "delivered" {
		order.DeliveredAt = &now
		// Release reserved stock and credit vendor wallet
		var commission models.CommissionTransaction
		commission = models.CommissionTransaction{
			OrderID:         order.ID,
			VendorID:        order.VendorID,
			OrderAmount:     order.FinalAmount,
			CommissionRate:  order.CommissionAmount / order.FinalAmount,
			CommissionAmount: order.CommissionAmount,
			PlatformFee:     order.PlatformFee,
			NetAmount:       order.VendorEarnings,
			Status:          "settled",
		}
		h.db.Create(&commission)

		// Credit vendor wallet
		var wallet models.Wallet
		if err := h.db.Where("vendor_id = ?", order.VendorID).First(&wallet).Error; err == nil {
			h.db.Model(&wallet).Update("balance", gorm.Expr("balance + ?", order.VendorEarnings))
			h.db.Create(&models.WalletTransaction{
				WalletID:      wallet.ID,
				TxnType:       models.TxnTypeCredit,
				Amount:        order.VendorEarnings,
				ReferenceType: models.TxnRefOrder,
				ReferenceID:   order.OrderNumber,
				Description:   "Earnings from order " + order.OrderNumber,
				TxnDate:       now,
			})
		}

		// Generate invoice
		go h.generateInvoice(&order)
	}

	if req.Status == "cancelled" {
		order.CancelledAt = &now
		order.CancellationReason = req.Note
	}

	h.db.Save(&order)

	h.db.Create(&models.OrderStatusLog{
		OrderID:    order.ID,
		FromStatus: fromStatus,
		ToStatus:   models.OrderStatus(req.Status),
		ChangedBy:  userID,
		Role:       claims.Role,
		Note:       req.Note,
	})

	switch req.Status {
	case "confirmed":
		h.dispatchOrderEvent(c.Request.Context(), order, models.NotifOrderConfirmed)
	case "shipped":
		h.dispatchOrderEvent(c.Request.Context(), order, models.NotifOrderShipped)
	case "delivered":
		h.dispatchOrderEvent(c.Request.Context(), order, models.NotifOrderDelivered)
	case "cancelled":
		h.dispatchOrderEvent(c.Request.Context(), order, models.NotifOrderCancelled)
	}

	utils.SuccessResponse(c, order)
}

func (h *OrderHandler) CancelOrder(c *gin.Context) {
	userID := c.MustGet("user").(uuid.UUID)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var req struct {
		Reason string `json:"reason" binding:"required"`
	}
	c.ShouldBindJSON(&req)

	var order models.Order
	if err := h.db.First(&order, id).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	if order.CustomerID != userID {
		var vendor models.Vendor
		h.db.Where("user_id = ?", userID).First(&vendor)
		if order.VendorID != vendor.ID {
			utils.ForbiddenResponse(c, "Not authorized")
			return
		}
	}

	if order.Status != models.OrderStatusPending && order.Status != models.OrderStatusConfirmed {
		utils.BadRequestResponse(c, "Order cannot be cancelled at this stage")
		return
	}

	now := time.Now()
	order.Status = models.OrderStatusCancelled
	order.CancellationReason = req.Reason
	order.CancelledAt = &now
	h.db.Save(&order)

	h.db.Create(&models.OrderStatusLog{
		OrderID: order.ID,
		FromStatus: order.Status,
		ToStatus:   models.OrderStatusCancelled,
		ChangedBy:  userID,
		Role:       "customer",
		Note:       req.Reason,
	})

	h.dispatchOrderEvent(c.Request.Context(), order, models.NotifOrderCancelled)

	utils.SuccessResponse(c, gin.H{"message": "Order cancelled"})
}

func (h *OrderHandler) TrackOrder(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var order models.Order
	if err := h.db.Preload("StatusLog").First(&order, id).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	utils.SuccessResponse(c, gin.H{
		"status":        order.Status,
		"tracking":      order.TrackingNumber,
		"courier":       order.CourierPartner,
		"estimated_delivery": order.EstimatedDelivery,
		"timeline":      order.StatusLog,
	})
}

func (h *OrderHandler) SubmitReturnRequest(c *gin.Context) {
	customerID := c.MustGet("user").(uuid.UUID)

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestResponse(c, "Invalid order ID")
		return
	}

	var req struct {
		Reason string   `json:"reason" binding:"required"`
		Items  []uuid.UUID `json:"items"`
		Images []string `json:"images"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestResponse(c, "Invalid input")
		return
	}

	var order models.Order
	if err := h.db.Where("id = ? AND customer_id = ?", id, customerID).First(&order).Error; err != nil {
		utils.NotFoundResponse(c, "Order not found")
		return
	}

	if order.Status != models.OrderStatusDelivered {
		utils.BadRequestResponse(c, "Only delivered orders can be returned")
		return
	}

	var refundType string
	refundAmount := order.FinalAmount
	if len(req.Items) > 0 {
		refundType = "partial"
		// Calculate partial refund amount
		refundAmount = 0
		for _, itemID := range req.Items {
			var orderItem models.OrderItem
			if err := h.db.Where("order_id = ? AND id = ?", order.ID, itemID).First(&orderItem).Error; err == nil {
				refundAmount += orderItem.TotalPrice
			}
		}
	} else {
		refundType = "full"
	}

	refund := models.RefundRequest{
		OrderID:     order.ID,
		CustomerID:  customerID,
		VendorID:    order.VendorID,
		Reason:      req.Reason,
		RefundType:  refundType,
		RefundAmount: refundAmount,
		Status:      "pending",
	}
	if len(req.Images) > 0 {
		imgBytes, _ := json.Marshal(req.Images)
		json.Unmarshal(imgBytes, &refund.Images)
	}
	if err := h.db.Create(&refund).Error; err != nil {
		utils.InternalErrorResponse(c, "Failed to submit return request")
		return
	}

	order.Status = models.OrderStatusReturned
	order.ReturnReason = req.Reason
	now := time.Now()
	order.ReturnRequestedAt = &now
	h.db.Save(&order)

	utils.CreatedResponse(c, refund)
}

func (h *OrderHandler) generateInvoice(order *models.Order) {
	invoiceNo := "INV-" + order.OrderNumber + "-" + time.Now().Format("20060102150405")
	invoice := models.Invoice{
		OrderID:       order.ID,
		InvoiceNumber: invoiceNo,
		TotalAmount:   order.FinalAmount,
		TaxAmount:     order.TaxAmount,
	}
	h.db.Create(&invoice)
	// Generate PDF invoice here
}

func generateOrderNumber() string {
	return "ORD-" + time.Now().Format("20060102") + "-" + uuid.New().String()[:8]
}

func getShippingCharge(amount float64) float64 {
	if amount >= 499 {
		return 0
	}
	return 49
}

func (h *OrderHandler) dispatchOrderEvent(ctx context.Context, order models.Order, event models.NotificationType) {
	if h.dispatcher == nil {
		return
	}
	
	switch event {
	case models.NotifOrderPlaced:
		var vendor models.Vendor
		if err := h.db.First(&vendor, order.VendorID).Error; err == nil {
			h.dispatcher.Dispatch(ctx, notification.NotificationEvent{
				Type:       event,
				ReceiverID: vendor.UserID,
				Role:       notification.RoleVendor,
				Data:       map[string]interface{}{"order_id": order.ID.String()},
			})
		}
	case models.NotifOrderConfirmed, models.NotifOrderShipped, models.NotifOrderDelivered:
		h.dispatcher.Dispatch(ctx, notification.NotificationEvent{
			Type:       event,
			ReceiverID: order.CustomerID,
			Role:       notification.RoleCustomer,
			Data:       map[string]interface{}{"order_id": order.ID.String()},
		})
	case models.NotifOrderCancelled:
		// Notify Customer
		h.dispatcher.Dispatch(ctx, notification.NotificationEvent{
			Type:       event,
			ReceiverID: order.CustomerID,
			Role:       notification.RoleCustomer,
			Data:       map[string]interface{}{"order_id": order.ID.String()},
		})
		// Notify Vendor
		var vendor models.Vendor
		if err := h.db.First(&vendor, order.VendorID).Error; err == nil {
			h.dispatcher.Dispatch(ctx, notification.NotificationEvent{
				Type:       event,
				ReceiverID: vendor.UserID,
				Role:       notification.RoleVendor,
				Data:       map[string]interface{}{"order_id": order.ID.String()},
			})
		}
	}
}
