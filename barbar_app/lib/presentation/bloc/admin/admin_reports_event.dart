part of 'admin_reports_bloc.dart';

abstract class AdminReportsEvent extends Equatable {
  const AdminReportsEvent();
  @override
  List<Object?> get props => [];
}

class LoadRevenueReport extends AdminReportsEvent {
  final String period;
  const LoadRevenueReport({this.period = 'month'});
  @override
  List<Object?> get props => [period];
}

class LoadBookingAnalytics extends AdminReportsEvent {
  final String period;
  const LoadBookingAnalytics({this.period = 'month'});
  @override
  List<Object?> get props => [period];
}

class LoadOrderAnalytics extends AdminReportsEvent {
  final String period;
  const LoadOrderAnalytics({this.period = 'month'});
  @override
  List<Object?> get props => [period];
}

class LoadCustomerAnalytics extends AdminReportsEvent {
  final String period;
  const LoadCustomerAnalytics({this.period = 'month'});
  @override
  List<Object?> get props => [period];
}

class LoadDeliveryAnalytics extends AdminReportsEvent {
  const LoadDeliveryAnalytics();
}

class LoadBarberAnalytics extends AdminReportsEvent {
  const LoadBarberAnalytics();
}

class LoadCommissionAnalytics extends AdminReportsEvent {
  final int page;
  const LoadCommissionAnalytics({this.page = 1});
  @override
  List<Object?> get props => [page];
}

class ExportReport extends AdminReportsEvent {
  final String section;
  final String period;
  const ExportReport({required this.section, this.period = 'month'});
  @override
  List<Object?> get props => [section, period];
}
