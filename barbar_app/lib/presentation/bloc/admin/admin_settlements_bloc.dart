import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/data/models/settlement_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

part 'admin_settlements_event.dart';
part 'admin_settlements_state.dart';

class AdminSettlementsBloc extends Bloc<AdminSettlementsEvent, AdminSettlementsState> {
  final AdminRepository _adminRepository;

  AdminSettlementsBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(AdminSettlementsInitial()) {
    on<LoadSettlements>(_onLoadSettlements);
    on<LoadSettlementDetail>(_onLoadSettlementDetail);
    on<ProcessSettlement>(_onProcessSettlement);
    on<BulkProcessSettlements>(_onBulkProcessSettlements);
  }

  Future<void> _onLoadSettlements(LoadSettlements event, Emitter<AdminSettlementsState> emit) async {
    if (!event.isLoadMore) emit(AdminSettlementsLoading());
    try {
      final data = await _adminRepository.getAdminSettlements(
        page: event.page,
        limit: 20,
        status: event.status,
        vendorId: event.vendorId,
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
      );
      final dynamic rawData = data['data'];
      final List<dynamic> items = rawData is List ? rawData : (rawData is Map ? (rawData['items'] ?? []) : []);
      final settlements = items.map((j) => SettlementModel.fromJson(j as Map<String, dynamic>)).toList();
      final pagination = (data['meta'] ?? data['pagination']) as Map<String, dynamic>? ?? {};
      final total = (pagination['total'] as num?)?.toInt() ?? settlements.length;
      emit(AdminSettlementsLoaded(
        settlements: settlements,
        currentPage: event.page,
        hasReachedMax: settlements.length < 20 || (event.page * 20) >= total,
        total: total,
      ));
    } catch (e) {
      emit(AdminSettlementsError(e.toString()));
    }
  }

  Future<void> _onLoadSettlementDetail(LoadSettlementDetail event, Emitter<AdminSettlementsState> emit) async {
    emit(AdminSettlementDetailLoading());
    try {
      final data = await _adminRepository.getAdminSettlementDetail(event.id);
      final settlement = SettlementModel.fromJson(data);
      emit(AdminSettlementDetailLoaded(settlement));
    } catch (e) {
      emit(AdminSettlementsError(e.toString()));
    }
  }

  Future<void> _onProcessSettlement(ProcessSettlement event, Emitter<AdminSettlementsState> emit) async {
    try {
      await _adminRepository.processAdminSettlement(event.id, event.status, adminNotes: event.adminNotes, utrNumber: event.utrNumber);
      emit(AdminSettlementActionSuccess('Settlement ${event.status} successfully'));
    } catch (e) {
      emit(AdminSettlementsError(e.toString()));
    }
  }

  Future<void> _onBulkProcessSettlements(BulkProcessSettlements event, Emitter<AdminSettlementsState> emit) async {
    try {
      final result = await _adminRepository.bulkProcessAdminSettlements(event.ids, event.status, utrNumber: event.utrNumber);
      final msg = result['message'] as String? ?? 'Bulk process completed';
      emit(AdminSettlementActionSuccess(msg));
    } catch (e) {
      emit(AdminSettlementsError(e.toString()));
    }
  }
}
