class RevenueAnalytics {
  final String period;
  final double totalRevenue;
  final double totalCommission;
  final int totalOrders;
  final int totalBookings;
  final double avgOrderValue;
  final List<RevenueRecord> records;

  RevenueAnalytics({
    required this.period,
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalOrders,
    required this.totalBookings,
    required this.avgOrderValue,
    required this.records,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final totals = data['totals'] as Map<String, dynamic>? ?? {};
    final rawRecords = data['records'] as List<dynamic>? ?? [];
    return RevenueAnalytics(
      period: data['period'] as String? ?? 'month',
      totalRevenue: (totals['total_revenue'] as num?)?.toDouble() ?? 0,
      totalCommission: (totals['total_commission'] as num?)?.toDouble() ?? 0,
      totalOrders: (totals['total_orders'] as num?)?.toInt() ?? 0,
      totalBookings: (totals['total_bookings'] as num?)?.toInt() ?? 0,
      avgOrderValue: (totals['avg_order_value'] as num?)?.toDouble() ?? 0,
      records: rawRecords.map((r) => RevenueRecord.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}

class RevenueRecord {
  final String date;
  final double bookingRevenue;
  final double orderRevenue;
  final double commission;
  final double totalRevenue;

  RevenueRecord({
    required this.date,
    required this.bookingRevenue,
    required this.orderRevenue,
    required this.commission,
    required this.totalRevenue,
  });

  factory RevenueRecord.fromJson(Map<String, dynamic> json) => RevenueRecord(
    date: json['date'] as String? ?? '',
    bookingRevenue: (json['booking_revenue'] as num?)?.toDouble() ?? 0,
    orderRevenue: (json['order_revenue'] as num?)?.toDouble() ?? 0,
    commission: (json['commission'] as num?)?.toDouble() ?? 0,
    totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
  );
}

class BookingAnalytics {
  final String period;
  final int totalBookings;
  final int completed;
  final int cancelled;
  final double totalRevenue;
  final List<BookingTrend> records;

  BookingAnalytics.fromJson(Map<String, dynamic> json)
    : period = json['period'] as String? ?? 'month',
      totalBookings = (json['totals'] is Map ? (json['totals']['total_bookings'] as num?)?.toInt() : 0) ?? 0,
      completed = (json['totals'] is Map ? (json['totals']['completed'] as num?)?.toInt() : 0) ?? 0,
      cancelled = (json['totals'] is Map ? (json['totals']['cancelled'] as num?)?.toInt() : 0) ?? 0,
      totalRevenue = (json['totals'] is Map ? (json['totals']['total_revenue'] as num?)?.toDouble() : 0) ?? 0,
      records = (json['records'] as List<dynamic>? ?? []).map((r) => BookingTrend.fromJson(r as Map<String, dynamic>)).toList();
}

class BookingTrend {
  final String date;
  final int completed;
  final int cancelled;
  final int pending;
  final int total;
  BookingTrend.fromJson(Map<String, dynamic> json)
    : date = json['date'] as String? ?? '',
      completed = (json['completed'] as num?)?.toInt() ?? 0,
      cancelled = (json['cancelled'] as num?)?.toInt() ?? 0,
      pending = (json['pending'] as num?)?.toInt() ?? 0,
      total = (json['total'] as num?)?.toInt() ?? 0;
}

class OrderAnalytics {
  final String period;
  final int totalOrders;
  final int delivered;
  final double totalRevenue;
  final List<OrderTrend> records;

  OrderAnalytics.fromJson(Map<String, dynamic> json)
    : period = json['period'] as String? ?? 'month',
      totalOrders = (json['totals'] is Map ? (json['totals']['total_orders'] as num?)?.toInt() : 0) ?? 0,
      delivered = (json['totals'] is Map ? (json['totals']['delivered'] as num?)?.toInt() : 0) ?? 0,
      totalRevenue = (json['totals'] is Map ? (json['totals']['total_revenue'] as num?)?.toDouble() : 0) ?? 0,
      records = (json['records'] as List<dynamic>? ?? []).map((r) => OrderTrend.fromJson(r as Map<String, dynamic>)).toList();
}

class OrderTrend {
  final String date;
  final int delivered;
  final int cancelled;
  final int pending;
  final int total;
  final double revenue;
  OrderTrend.fromJson(Map<String, dynamic> json)
    : date = json['date'] as String? ?? '',
      delivered = (json['delivered'] as num?)?.toInt() ?? 0,
      cancelled = (json['cancelled'] as num?)?.toInt() ?? 0,
      pending = (json['pending'] as num?)?.toInt() ?? 0,
      total = (json['total'] as num?)?.toInt() ?? 0,
      revenue = (json['revenue'] as num?)?.toDouble() ?? 0;
}

class CustomerAnalytics {
  final String period;
  final int totalCustomers;
  final int newCustomers;
  final List<CustomerTrend> records;

  CustomerAnalytics.fromJson(Map<String, dynamic> json)
    : period = json['period'] as String? ?? 'month',
      totalCustomers = (json['totals'] is Map ? (json['totals']['total_customers'] as num?)?.toInt() : 0) ?? 0,
      newCustomers = (json['totals'] is Map ? (json['totals']['new_customers'] as num?)?.toInt() : 0) ?? 0,
      records = (json['records'] as List<dynamic>? ?? []).map((r) => CustomerTrend.fromJson(r as Map<String, dynamic>)).toList();
}

class CustomerTrend {
  final String date;
  final int newUsers;
  final int total;
  CustomerTrend.fromJson(Map<String, dynamic> json)
    : date = json['date'] as String? ?? '',
      newUsers = (json['new_users'] as num?)?.toInt() ?? 0,
      total = (json['total'] as num?)?.toInt() ?? 0;
}

class DeliveryAnalytics {
  final int totalPartners;
  final int online;
  final int busy;
  final int offline;
  final int totalDeliveries;
  final double avgRating;

  DeliveryAnalytics.fromJson(Map<String, dynamic> json)
    : totalPartners = (json['total_partners'] as num?)?.toInt() ?? 0,
      online = (json['online'] as num?)?.toInt() ?? 0,
      busy = (json['busy'] as num?)?.toInt() ?? 0,
      offline = (json['offline'] as num?)?.toInt() ?? 0,
      totalDeliveries = (json['total_deliveries'] as num?)?.toInt() ?? 0,
      avgRating = (json['avg_rating'] as num?)?.toDouble() ?? 0;
}

class BarberAnalytics {
  final int totalBarbers;
  final int approved;
  final int pending;
  final double avgRating;
  final int totalBookings;
  final double totalRevenue;
  final List<TopBarber> topBarbers;

  BarberAnalytics.fromJson(Map<String, dynamic> json)
    : totalBarbers = (json['stats'] is Map ? (json['stats']['total_barbers'] as num?)?.toInt() : 0) ?? 0,
      approved = (json['stats'] is Map ? (json['stats']['approved'] as num?)?.toInt() : 0) ?? 0,
      pending = (json['stats'] is Map ? (json['stats']['pending'] as num?)?.toInt() : 0) ?? 0,
      avgRating = (json['stats'] is Map ? (json['stats']['avg_rating'] as num?)?.toDouble() : 0) ?? 0,
      totalBookings = (json['stats'] is Map ? (json['stats']['total_bookings'] as num?)?.toInt() : 0) ?? 0,
      totalRevenue = (json['stats'] is Map ? (json['stats']['total_revenue'] as num?)?.toDouble() : 0) ?? 0,
      topBarbers = (json['top_barbers'] as List<dynamic>? ?? []).map((b) => TopBarber.fromJson(b as Map<String, dynamic>)).toList();
}

class TopBarber {
  final String id;
  final String shopName;
  final int bookings;
  final double revenue;
  final double rating;
  TopBarber.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String? ?? '',
      shopName = json['shop_name'] as String? ?? '',
      bookings = (json['bookings'] as num?)?.toInt() ?? 0,
      revenue = (json['revenue'] as num?)?.toDouble() ?? 0,
      rating = (json['rating'] as num?)?.toDouble() ?? 0;
}
