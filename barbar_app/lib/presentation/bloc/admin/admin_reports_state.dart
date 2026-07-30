part of 'admin_reports_bloc.dart';

class AdminReportsState extends Equatable {
  final bool isLoading;
  final bool isExporting;
  final bool isExportSuccess;
  final String? errorMessage;
  final RevenueAnalytics? revenueData;
  final BookingAnalytics? bookingData;
  final OrderAnalytics? orderData;
  final CustomerAnalytics? customerData;
  final DeliveryAnalytics? deliveryData;
  final BarberAnalytics? barberData;
  final Map<String, dynamic>? commissionData;

  const AdminReportsState({
    this.isLoading = false,
    this.isExporting = false,
    this.isExportSuccess = false,
    this.errorMessage,
    this.revenueData,
    this.bookingData,
    this.orderData,
    this.customerData,
    this.deliveryData,
    this.barberData,
    this.commissionData,
  });

  AdminReportsState copyWith({
    bool? isLoading,
    bool? isExporting,
    bool? isExportSuccess,
    String? errorMessage,
    RevenueAnalytics? revenueData,
    BookingAnalytics? bookingData,
    OrderAnalytics? orderData,
    CustomerAnalytics? customerData,
    DeliveryAnalytics? deliveryData,
    BarberAnalytics? barberData,
    Map<String, dynamic>? commissionData,
  }) {
    return AdminReportsState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      isExportSuccess: isExportSuccess ?? this.isExportSuccess,
      errorMessage: errorMessage,
      revenueData: revenueData ?? this.revenueData,
      bookingData: bookingData ?? this.bookingData,
      orderData: orderData ?? this.orderData,
      customerData: customerData ?? this.customerData,
      deliveryData: deliveryData ?? this.deliveryData,
      barberData: barberData ?? this.barberData,
      commissionData: commissionData ?? this.commissionData,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isExporting,
        isExportSuccess,
        errorMessage,
        revenueData,
        bookingData,
        orderData,
        customerData,
        deliveryData,
        barberData,
        commissionData,
      ];
}
