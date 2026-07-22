part of 'admin_settlements_bloc.dart';

abstract class AdminSettlementsEvent extends Equatable {
  const AdminSettlementsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettlements extends AdminSettlementsEvent {
  final int page;
  final bool isLoadMore;
  final String? status;
  final String? vendorId;
  final String? dateFrom;
  final String? dateTo;
  final double? minAmount;
  final double? maxAmount;

  const LoadSettlements({
    this.page = 1,
    this.isLoadMore = false,
    this.status,
    this.vendorId,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
  });

  @override
  List<Object?> get props => [page, isLoadMore, status, vendorId, dateFrom, dateTo, minAmount, maxAmount];
}

class LoadSettlementDetail extends AdminSettlementsEvent {
  final String id;
  const LoadSettlementDetail(this.id);
  @override
  List<Object?> get props => [id];
}

class ProcessSettlement extends AdminSettlementsEvent {
  final String id;
  final String status;
  final String? adminNotes;
  final String? utrNumber;

  const ProcessSettlement({
    required this.id,
    required this.status,
    this.adminNotes,
    this.utrNumber,
  });

  @override
  List<Object?> get props => [id, status, adminNotes, utrNumber];
}

class BulkProcessSettlements extends AdminSettlementsEvent {
  final List<String> ids;
  final String status;
  final String? utrNumber;

  const BulkProcessSettlements({
    required this.ids,
    required this.status,
    this.utrNumber,
  });

  @override
  List<Object?> get props => [ids, status, utrNumber];
}
