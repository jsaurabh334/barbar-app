import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/data/models/analytics_dashboard_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

part 'admin_reports_event.dart';
part 'admin_reports_state.dart';

class AdminReportsBloc extends Bloc<AdminReportsEvent, AdminReportsState> {
  final AdminRepository _adminRepository;

  AdminReportsBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AdminReportsState()) {
    on<LoadRevenueReport>(_onLoadRevenueReport);
    on<LoadBookingAnalytics>(_onLoadBookingAnalytics);
    on<LoadOrderAnalytics>(_onLoadOrderAnalytics);
    on<LoadCustomerAnalytics>(_onLoadCustomerAnalytics);
    on<LoadDeliveryAnalytics>(_onLoadDeliveryAnalytics);
    on<LoadBarberAnalytics>(_onLoadBarberAnalytics);
    on<LoadCommissionAnalytics>(_onLoadCommissionAnalytics);
    on<ExportReport>(_onExportReport);
  }

  Future<void> _onLoadRevenueReport(LoadRevenueReport event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminRevenueAnalytics(period: event.period);
      emit(state.copyWith(isLoading: false, revenueData: RevenueAnalytics.fromJson(data)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadBookingAnalytics(LoadBookingAnalytics event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminBookingAnalytics(period: event.period);
      emit(state.copyWith(isLoading: false, bookingData: BookingAnalytics.fromJson(data)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadOrderAnalytics(LoadOrderAnalytics event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminOrderAnalytics(period: event.period);
      emit(state.copyWith(isLoading: false, orderData: OrderAnalytics.fromJson(data)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadCustomerAnalytics(LoadCustomerAnalytics event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminCustomerAnalytics(period: event.period);
      emit(state.copyWith(isLoading: false, customerData: CustomerAnalytics.fromJson(data)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadDeliveryAnalytics(LoadDeliveryAnalytics event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminDeliveryAnalytics();
      emit(state.copyWith(isLoading: false, deliveryData: DeliveryAnalytics.fromJson(data)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadBarberAnalytics(LoadBarberAnalytics event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminBarberAnalytics();
      emit(state.copyWith(isLoading: false, barberData: BarberAnalytics.fromJson(data)));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadCommissionAnalytics(LoadCommissionAnalytics event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final data = await _adminRepository.getAdminCommissionTransactions(page: event.page, limit: 50);
      emit(state.copyWith(isLoading: false, commissionData: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onExportReport(ExportReport event, Emitter<AdminReportsState> emit) async {
    emit(state.copyWith(isExporting: true));
    try {
      emit(state.copyWith(isExporting: false, isExportSuccess: true));
    } catch (e) {
      emit(state.copyWith(isExporting: false, errorMessage: e.toString()));
    }
  }
}
