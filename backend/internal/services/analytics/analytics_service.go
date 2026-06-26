package analytics

import (
	"fmt"
	"time"

	"github.com/barbar-app/backend/internal/models"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AnalyticsService struct {
	db *gorm.DB
}

func NewAnalyticsService(db *gorm.DB) *AnalyticsService {
	return &AnalyticsService{db: db}
}

type RevenueReport struct {
	Period         string           `json:"period"`
	TotalRevenue   float64          `json:"total_revenue"`
	TotalBookings  int64            `json:"total_bookings"`
	TotalOrders    int64            `json:"total_orders"`
	TotalCommission float64         `json:"total_commission"`
	Records        []RevenueRecord  `json:"records"`
}

type RevenueRecord struct {
	Date          string  `json:"date"`
	BookingRevenue float64 `json:"booking_revenue"`
	OrderRevenue  float64 `json:"order_revenue"`
	Commission    float64 `json:"commission"`
	Total         float64 `json:"total"`
}

func (s *AnalyticsService) GetRevenueReport(c *gin.Context) (*RevenueReport, error) {
	period := c.DefaultQuery("period", "month")

	now := time.Now()
	var since time.Time
	switch period {
	case "week":
		since = now.AddDate(0, 0, -7)
	case "month":
		since = now.AddDate(0, -1, 0)
	case "year":
		since = now.AddDate(-1, 0, 0)
	default:
		since = now.AddDate(0, -1, 0)
	}

	var records []RevenueRecord
	s.db.Raw(`
		SELECT 
			DATE(dates) as date,
			COALESCE(SUM(CASE WHEN entity = 'booking' THEN amount END), 0) as booking_revenue,
			COALESCE(SUM(CASE WHEN entity = 'order' THEN amount END), 0) as order_revenue,
			COALESCE(SUM(CASE WHEN entity = 'commission' THEN amount END), 0) as commission,
			COALESCE(SUM(amount), 0) as total
		FROM (
			SELECT DATE(created_at) as dates, 'booking' as entity, final_price as amount FROM bookings WHERE status = 'completed' AND created_at >= ?
			UNION ALL
			SELECT DATE(created_at) as dates, 'order' as entity, final_amount as amount FROM orders WHERE status = 'delivered' AND created_at >= ?
			UNION ALL
			SELECT DATE(created_at) as dates, 'commission' as entity, commission_amount as amount FROM commission_transactions WHERE created_at >= ?
		) combined
		GROUP BY DATE(dates)
		ORDER BY date ASC
	`, since, since, since).Scan(&records)

	var report RevenueReport
	s.db.Model(&models.Booking{}).Where("status = ? AND created_at >= ?", models.BookingStatusCompleted, since).Count(&report.TotalBookings)
	s.db.Model(&models.Order{}).Where("status = ? AND created_at >= ?", models.OrderStatusDelivered, since).Count(&report.TotalOrders)

	s.db.Raw(`
		SELECT COALESCE(SUM(final_amount), 0) as total_revenue, COALESCE(SUM(commission_amount), 0) as total_commission
		FROM orders WHERE status IN ('delivered','refunded') AND created_at >= ?
	`, since).Scan(&report)

	report.Period = period
	report.Records = records

	return &report, nil
}

func (s *AnalyticsService) ExportRevenueCSV(c *gin.Context) (string, error) {
	report, err := s.GetRevenueReport(c)
	if err != nil {
		return "", err
	}

	rows := [][]string{
		{"Date", "Booking Revenue", "Order Revenue", "Commission", "Total"},
	}
	for _, r := range report.Records {
		rows = append(rows, []string{
			r.Date,
			fmt.Sprintf("%.2f", r.BookingRevenue),
			fmt.Sprintf("%.2f", r.OrderRevenue),
			fmt.Sprintf("%.2f", r.Commission),
			fmt.Sprintf("%.2f", r.Total),
		})
	}

	return formatCSV(rows), nil
}

func formatCSV(rows [][]string) string {
	var csvStr string
	for _, row := range rows {
		record := ""
		for i, field := range row {
			if i > 0 {
				record += ","
			}
			record += fmt.Sprintf(`"%s"`, field)
		}
		csvStr += record + "\n"
	}
	return csvStr
}

type UserGrowthReport struct {
	Period   string         `json:"period"`
	Total    int64          `json:"total"`
	Records  []GrowthRecord `json:"records"`
}

type GrowthRecord struct {
	Date      string `json:"date"`
	Customers int64  `json:"customers"`
	Barbers   int64  `json:"barbers"`
	Vendors   int64  `json:"vendors"`
	Total     int64  `json:"total"`
}

func (s *AnalyticsService) ExportUserGrowthCSV(c *gin.Context) (string, error) {
	period := c.DefaultQuery("period", "month")

	now := time.Now()
	var since time.Time
	switch period {
	case "week":
		since = now.AddDate(0, 0, -7)
	case "month":
		since = now.AddDate(0, -1, 0)
	case "year":
		since = now.AddDate(-1, 0, 0)
	default:
		since = now.AddDate(0, -1, 0)
	}

	var records []GrowthRecord
	s.db.Raw(`
		SELECT 
			DATE(dates) as date,
			COALESCE(SUM(CASE WHEN role = 'customer' THEN 1 END), 0) as customers,
			COALESCE(SUM(CASE WHEN role = 'barber' THEN 1 END), 0) as barbers,
			COALESCE(SUM(CASE WHEN role = 'vendor' THEN 1 END), 0) as vendors,
			COUNT(*) as total
		FROM (
			SELECT DATE(created_at) as dates, role FROM users WHERE created_at >= ?
		) daily
		GROUP BY DATE(dates)
		ORDER BY date ASC
	`, since).Scan(&records)

	rows := [][]string{
		{"Date", "Customers", "Barbers", "Vendors", "Total"},
	}
	for _, r := range records {
		rows = append(rows, []string{
			r.Date,
			fmt.Sprintf("%d", r.Customers),
			fmt.Sprintf("%d", r.Barbers),
			fmt.Sprintf("%d", r.Vendors),
			fmt.Sprintf("%d", r.Total),
		})
	}

	return formatCSV(rows), nil
}

type TopBarbersReport struct {
	BarberName  string  `json:"barber_name"`
	ShopName    string  `json:"shop_name"`
	Bookings    int64   `json:"bookings"`
	Revenue     float64 `json:"revenue"`
	Rating      float64 `json:"rating"`
}

func (s *AnalyticsService) ExportTopBarbersCSV(c *gin.Context) (string, error) {
	period := c.DefaultQuery("period", "month")

	now := time.Now()
	var since time.Time
	switch period {
	case "week":
		since = now.AddDate(0, 0, -7)
	case "month":
		since = now.AddDate(0, -1, 0)
	case "year":
		since = now.AddDate(-1, 0, 0)
	default:
		since = now.AddDate(0, -1, 0)
	}

	var results []struct {
		BarberName string
		ShopName   string
		Bookings   int64
		Revenue    float64
		Rating     float64
	}
	s.db.Raw(`
		SELECT 
			u.name as barber_name,
			b.shop_name,
			COUNT(bk.id) as bookings,
			COALESCE(SUM(bk.final_price), 0) as revenue,
			COALESCE(b.rating, 0) as rating
		FROM barbers b
		JOIN users u ON u.id = b.user_id
		LEFT JOIN bookings bk ON bk.barber_id = b.id AND bk.status = 'completed' AND bk.scheduled_start >= ?
		GROUP BY b.id, u.name, b.shop_name, b.rating
		ORDER BY revenue DESC
		LIMIT 20
	`, since).Scan(&results)

	rows := [][]string{
		{"Barber Name", "Shop Name", "Bookings", "Revenue", "Rating"},
	}
	for _, r := range results {
		rows = append(rows, []string{
			r.BarberName,
			r.ShopName,
			fmt.Sprintf("%d", r.Bookings),
			fmt.Sprintf("%.2f", r.Revenue),
			fmt.Sprintf("%.1f", r.Rating),
		})
	}

	return formatCSV(rows), nil
}
