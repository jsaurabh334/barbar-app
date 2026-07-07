class DashboardStatsModel {
  final int totalCustomers;
  final int approvedBarbers;
  final int pendingBarbers;
  final int todayBookings;
  final int vendors;
  final int deliveryPartners;
  final double todayRevenue;
  final int liveQueue;
  final int pendingReports;
  final int pendingKyc;

  DashboardStatsModel({
    required this.totalCustomers,
    required this.approvedBarbers,
    required this.pendingBarbers,
    required this.todayBookings,
    required this.vendors,
    required this.deliveryPartners,
    required this.todayRevenue,
    required this.liveQueue,
    required this.pendingReports,
    required this.pendingKyc,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCustomers: json['total_customers'] ?? 0,
      approvedBarbers: json['approved_barbers'] ?? 0,
      pendingBarbers: json['pending_barbers'] ?? 0,
      todayBookings: json['today_bookings'] ?? 0,
      vendors: json['total_vendors'] ?? 0,
      deliveryPartners: json['delivery_partners'] ?? 0,
      todayRevenue: (json['today_revenue'] ?? 0).toDouble(),
      liveQueue: json['live_queue'] ?? 0,
      pendingReports: json['pending_reports'] ?? 0,
      pendingKyc: json['pending_kyc'] ?? 0,
    );
  }
}
