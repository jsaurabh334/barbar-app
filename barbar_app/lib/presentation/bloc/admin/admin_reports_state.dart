part of 'admin_reports_bloc.dart';

abstract class AdminReportsState extends Equatable {
  const AdminReportsState();
  @override
  List<Object?> get props => [];
}

class AdminReportsInitial extends AdminReportsState {}

class AdminReportsLoading extends AdminReportsState {}

class AdminRevenueReportLoaded extends AdminReportsState {
  final RevenueAnalytics data;
  const AdminRevenueReportLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminBookingAnalyticsLoaded extends AdminReportsState {
  final BookingAnalytics data;
  const AdminBookingAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminOrderAnalyticsLoaded extends AdminReportsState {
  final OrderAnalytics data;
  const AdminOrderAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminCustomerAnalyticsLoaded extends AdminReportsState {
  final CustomerAnalytics data;
  const AdminCustomerAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminDeliveryAnalyticsLoaded extends AdminReportsState {
  final DeliveryAnalytics data;
  const AdminDeliveryAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminBarberAnalyticsLoaded extends AdminReportsState {
  final BarberAnalytics data;
  const AdminBarberAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminCommissionAnalyticsLoaded extends AdminReportsState {
  final Map<String, dynamic> data;
  const AdminCommissionAnalyticsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class AdminReportsExporting extends AdminReportsState {}

class AdminReportsExportSuccess extends AdminReportsState {}

class AdminReportsError extends AdminReportsState {
  final String message;
  const AdminReportsError(this.message);
  @override
  List<Object?> get props => [message];
}
