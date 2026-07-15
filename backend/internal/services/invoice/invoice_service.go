package invoice

import (
	"bytes"
	"fmt"
	"html/template"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"gorm.io/gorm"
)

type InvoiceService struct {
	db       *gorm.DB
	baseURL  string
	platform string
}

type InvoiceData struct {
	InvoiceNo     string        `json:"invoice_no"`
	Date          string        `json:"date"`
	DueDate       string        `json:"due_date"`
	CustomerName  string        `json:"customer_name"`
	CustomerAddr  string        `json:"customer_addr"`
	CustomerPhone string        `json:"customer_phone"`
	CustomerEmail string        `json:"customer_email"`
	Items         []InvoiceItem `json:"items"`
	Subtotal      float64       `json:"subtotal"`
	Tax           float64       `json:"tax"`
	Discount      float64       `json:"discount"`
	Shipping      float64       `json:"shipping"`
	Total         float64       `json:"total"`
	PlatformName  string        `json:"platform_name"`
	Currency      string        `json:"currency"`
	Status        string        `json:"status"`
	Notes         string        `json:"notes"`
}

type InvoiceItem struct {
	Name     string  `json:"name"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
	Total    float64 `json:"total"`
}

func NewInvoiceService(db *gorm.DB, baseURL string) *InvoiceService {
	return &InvoiceService{
		db:       db,
		baseURL:  baseURL,
		platform: "Barbar App",
	}
}

func (s *InvoiceService) GenerateOrderInvoice(orderID string) (string, error) {
	var order models.Order
	if err := s.db.Preload("Items").Preload("Customer").Preload("Vendor").First(&order, "id = ?", orderID).Error; err != nil {
		return "", fmt.Errorf("order not found: %w", err)
	}

	customerName := "Guest"
	customerEmail := ""
	customerPhone := ""
	if order.Customer != nil {
		customerName = order.Customer.FullName
		customerEmail = order.Customer.Email
		customerPhone = order.Customer.Phone
	}

	var items []InvoiceItem
	for _, item := range order.Items {
		items = append(items, InvoiceItem{
			Name:     item.ProductName,
			Quantity: item.Quantity,
			Price:    item.UnitPrice,
			Total:    item.TotalPrice,
		})
	}

	data := InvoiceData{
		InvoiceNo:    fmt.Sprintf("INV-%s", order.ID.String()[:8]),
		Date:         order.CreatedAt.Format("02 Jan 2006"),
		DueDate:      order.CreatedAt.Add(7 * 24 * time.Hour).Format("02 Jan 2006"),
		CustomerName: customerName,
		CustomerEmail: customerEmail,
		CustomerPhone: customerPhone,
		Items:        items,
		Subtotal:     order.ItemsTotal,
		Tax:          order.TaxAmount,
		Discount:     order.DiscountAmount,
		Shipping:     order.ShippingCharge,
		Total:        order.FinalAmount,
		PlatformName: s.platform,
		Currency:     "INR",
		Status:       string(order.Status),
		Notes:        "Thank you for your business!",
	}

	return s.renderHTML(data), nil
}

func (s *InvoiceService) GetBookingInvoiceData(bookingID string) (*InvoiceData, error) {
	var booking models.Booking
	if err := s.db.Preload("Barber").Preload("Customer").Preload("Services").First(&booking, "id = ?", bookingID).Error; err != nil {
		return nil, fmt.Errorf("booking not found: %w", err)
	}

	customerName := "Guest"
	customerEmail := ""
	customerPhone := ""
	if booking.Customer != nil {
		customerName = booking.Customer.FullName
		customerEmail = booking.Customer.Email
		customerPhone = booking.Customer.Phone
	}

	var items []InvoiceItem
	for _, svc := range booking.Services {
		items = append(items, InvoiceItem{
			Name:     svc.ServiceName,
			Quantity: svc.Quantity,
			Price:    svc.UnitPrice,
			Total:    svc.TotalPrice,
		})
	}

	// Fallback if no services are preloaded or present
	if len(items) == 0 {
		barberName := ""
		if booking.Barber != nil {
			barberName = booking.Barber.ShopName
		}
		items = append(items, InvoiceItem{
			Name:     fmt.Sprintf("Barber Service - %s", barberName),
			Quantity: 1,
			Price:    booking.FinalPrice,
			Total:    booking.FinalPrice,
		})
	}

	subtotal := booking.TotalPrice
	discount := booking.DiscountAmount
	tax := 0.0
	total := booking.FinalPrice

	data := InvoiceData{
		InvoiceNo:     fmt.Sprintf("REC-%s", booking.ID.String()[:8]),
		Date:          booking.CreatedAt.Format("02 Jan 2006"),
		DueDate:       booking.ScheduledStart.Format("02 Jan 2006"),
		CustomerName:  customerName,
		CustomerEmail: customerEmail,
		CustomerPhone: customerPhone,
		Items:         items,
		Subtotal:      subtotal,
		Tax:           tax,
		Discount:      discount,
		Total:         total,
		PlatformName:  s.platform,
		Currency:      "INR",
		Status:        string(booking.Status),
		Notes:         "Booking receipt",
	}

	return &data, nil
}

func (s *InvoiceService) GenerateBookingReceipt(bookingID string) (string, error) {
	data, err := s.GetBookingInvoiceData(bookingID)
	if err != nil {
		return "", err
	}
	return s.renderHTML(*data), nil
}

const invoiceHTML = `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
body{font-family:Arial,sans-serif;margin:0;padding:20px;color:#333}
.invoice{max-width:800px;margin:0 auto;border:1px solid #ddd;padding:30px}
.header{border-bottom:2px solid #1a1a2e;padding-bottom:15px;margin-bottom:20px}
.header h1{margin:0;color:#1a1a2e;font-size:24px}
.header p{margin:5px 0 0;color:#666}
.invoice-info{display:flex;justify-content:space-between;margin-bottom:30px}
.info-box h3{margin:0 0 5px;color:#1a1a2e;font-size:14px}
.info-box p{margin:2px 0;color:#555;font-size:13px}
table{width:100%;border-collapse:collapse;margin-bottom:20px}
th{background:#1a1a2e;color:white;padding:10px;text-align:left;font-size:13px}
td{padding:10px;border-bottom:1px solid #eee;font-size:13px}
.totals{text-align:right;margin-top:20px}
.totals div{margin:5px 0}
.totals .grand{font-size:18px;font-weight:bold;color:#1a1a2e;border-top:2px solid #1a1a2e;padding-top:10px}
.footer{margin-top:40px;padding-top:20px;border-top:1px solid #ddd;text-align:center;color:#888;font-size:12px}
.status{display:inline-block;padding:3px 10px;border-radius:3px;font-size:12px;font-weight:bold}
.status-confirmed{background:#e8f5e9;color:#2e7d32}
.status-pending{background:#fff3e0;color:#e65100}
.status-completed{background:#e3f2fd;color:#1565c0}
.status-cancelled{background:#fbe9e7;color:#c62828}
</style>
</head>
<body>
<div class="invoice">
<div class="header">
<h1>{{.PlatformName}}</h1>
<p>Invoice #{{.InvoiceNo}}</p>
</div>
<div class="invoice-info">
<div class="info-box">
<h3>Bill To</h3>
<p>{{.CustomerName}}</p>
{{if .CustomerEmail}}<p>{{.CustomerEmail}}</p>{{end}}
{{if .CustomerPhone}}<p>{{.CustomerPhone}}</p>{{end}}
</div>
<div class="info-box">
<h3>Invoice Details</h3>
<p>Date: {{.Date}}</p>
<p>Due Date: {{.DueDate}}</p>
<p>Status: <span class="status status-{{.Status}}">{{.Status}}</span></p>
</div>
</div>
<table>
<tr><th>Item</th><th>Qty</th><th>Price</th><th>Total</th></tr>
{{range .Items}}
<tr><td>{{.Name}}</td><td>{{.Quantity}}</td><td>{{printf "%.2f" .Price}}</td><td>{{printf "%.2f" .Total}}</td></tr>
{{end}}
</table>
<div class="totals">
<div>Subtotal: {{printf "%.2f" .Subtotal}}</div>
{{if .Tax}}<div>Tax: {{printf "%.2f" .Tax}}</div>{{end}}
{{if .Discount}}<div>Discount: {{printf "%.2f" .Discount}}</div>{{end}}
{{if .Shipping}}<div>Shipping: {{printf "%.2f" .Shipping}}</div>{{end}}
<div class="grand">Total: {{.Currency}} {{printf "%.2f" .Total}}</div>
</div>
{{if .Notes}}<p style="margin-top:20px;color:#666;font-size:13px">{{.Notes}}</p>{{end}}
<div class="footer">
<p>{{.PlatformName}} - Generated on {{.Date}}</p>
</div>
</div>
</body>
</html>`

var invoiceTemplate = template.Must(template.New("invoice").Parse(invoiceHTML))

func (s *InvoiceService) renderHTML(data InvoiceData) string {
	t, err := invoiceTemplate.Clone()
	if err != nil {
		return fmt.Sprintf("<html><body><h1>Invoice %s</h1><pre>%+v</pre></body></html>", data.InvoiceNo, data)
	}

	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return fmt.Sprintf("<html><body><h1>Invoice %s</h1><pre>%+v</pre></body></html>", data.InvoiceNo, data)
	}

	return buf.String()
}
