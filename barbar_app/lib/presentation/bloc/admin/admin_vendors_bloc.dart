import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';
import 'package:barbar_app/data/models/vendor_model.dart';

// --- Events ---
abstract class AdminVendorsEvent extends Equatable {
  const AdminVendorsEvent();
  @override
  List<Object?> get props => [];
}

class LoadVendors extends AdminVendorsEvent {
  final int page;
  final String? searchQuery;

  const LoadVendors({this.page = 1, this.searchQuery});

  @override
  List<Object?> get props => [page, searchQuery];
}

class ApproveVendor extends AdminVendorsEvent {
  final String vendorId;
  const ApproveVendor(this.vendorId);

  @override
  List<Object?> get props => [vendorId];
}

class SuspendVendor extends AdminVendorsEvent {
  final String vendorId;
  const SuspendVendor(this.vendorId);

  @override
  List<Object?> get props => [vendorId];
}

class RejectVendor extends AdminVendorsEvent {
  final String vendorId;
  final String? remarks;
  const RejectVendor(this.vendorId, {this.remarks});

  @override
  List<Object?> get props => [vendorId, remarks];
}

class ReactivateVendor extends AdminVendorsEvent {
  final String vendorId;
  const ReactivateVendor(this.vendorId);

  @override
  List<Object?> get props => [vendorId];
}

class ToggleVendorFeatured extends AdminVendorsEvent {
  final String vendorId;
  final bool isFeatured;
  const ToggleVendorFeatured(this.vendorId, this.isFeatured);

  @override
  List<Object?> get props => [vendorId, isFeatured];
}

// --- States ---
abstract class AdminVendorsState extends Equatable {
  const AdminVendorsState();
  @override
  List<Object?> get props => [];
}

class AdminVendorsInitial extends AdminVendorsState {}

class AdminVendorsLoading extends AdminVendorsState {}

class AdminVendorsLoaded extends AdminVendorsState {
  final List<VendorModel> vendors;
  final int currentPage;
  final bool hasReachedMax;

  const AdminVendorsLoaded({
    required this.vendors,
    required this.currentPage,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [vendors, currentPage, hasReachedMax];
}

class AdminVendorsError extends AdminVendorsState {
  final String message;
  const AdminVendorsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminVendorsActionSuccess extends AdminVendorsState {
  final String message;
  const AdminVendorsActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AdminVendorsBloc extends Bloc<AdminVendorsEvent, AdminVendorsState> {
  final AdminRepository adminRepository;

  AdminVendorsBloc({required this.adminRepository}) : super(AdminVendorsInitial()) {
    on<LoadVendors>(_onLoadVendors);
    on<ApproveVendor>(_onApproveVendor);
    on<RejectVendor>(_onRejectVendor);
    on<SuspendVendor>(_onSuspendVendor);
    on<ReactivateVendor>(_onReactivateVendor);
    on<ToggleVendorFeatured>(_onToggleVendorFeatured);
  }

  Future<void> _onLoadVendors(LoadVendors event, Emitter<AdminVendorsState> emit) async {
    if (event.page == 1) {
      emit(AdminVendorsLoading());
    }
    try {
      final vendors = await adminRepository.getVendors(page: event.page, search: event.searchQuery);
      
      if (state is AdminVendorsLoaded && event.page > 1) {
        final currentState = state as AdminVendorsLoaded;
        emit(AdminVendorsLoaded(
          vendors: currentState.vendors + vendors,
          currentPage: event.page,
          hasReachedMax: vendors.isEmpty || vendors.length < 20,
        ));
      } else {
        emit(AdminVendorsLoaded(
          vendors: vendors,
          currentPage: event.page,
          hasReachedMax: vendors.isEmpty || vendors.length < 20,
        ));
      }
    } catch (e) {
      emit(AdminVendorsError(e.toString()));
    }
  }

  Future<void> _onApproveVendor(ApproveVendor event, Emitter<AdminVendorsState> emit) async {
    await _updateVendorStatus(event.vendorId, 'approved', emit);
  }

  Future<void> _onRejectVendor(RejectVendor event, Emitter<AdminVendorsState> emit) async {
    try {
      await adminRepository.rejectVendor(event.vendorId, remarks: event.remarks);
      emit(const AdminVendorsActionSuccess('Vendor rejected'));
      add(const LoadVendors());
    } catch (e) {
      emit(AdminVendorsError(e.toString()));
    }
  }

  Future<void> _onSuspendVendor(SuspendVendor event, Emitter<AdminVendorsState> emit) async {
    await _updateVendorStatus(event.vendorId, 'suspended', emit);
  }

  Future<void> _onReactivateVendor(ReactivateVendor event, Emitter<AdminVendorsState> emit) async {
    try {
      await adminRepository.reactivateVendor(event.vendorId);
      emit(const AdminVendorsActionSuccess('Vendor reactivated'));
      add(const LoadVendors());
    } catch (e) {
      emit(AdminVendorsError(e.toString()));
    }
  }

  Future<void> _onToggleVendorFeatured(ToggleVendorFeatured event, Emitter<AdminVendorsState> emit) async {
    try {
      // Use the features/toggle endpoint for is_featured
      await adminRepository.toggleVendorFeature(vendorId: event.vendorId, isFeatured: event.isFeatured);
      final statusText = event.isFeatured ? 'featured' : 'unfeatured';
      emit(AdminVendorsActionSuccess('Vendor $statusText'));
      add(const LoadVendors());
    } catch (e) {
      emit(AdminVendorsError(e.toString()));
    }
  }

  Future<void> _updateVendorStatus(String vendorId, String status, Emitter<AdminVendorsState> emit) async {
    if (state is AdminVendorsLoaded) {
      final currentState = state as AdminVendorsLoaded;
      try {
        if (status == 'approved') {
          await adminRepository.approveVendor(vendorId);
        } else {
          await adminRepository.suspendVendor(vendorId);
        }
        
        final updatedVendors = currentState.vendors.map((v) {
          if (v.id == vendorId) {
            return v.copyWith(status: status);
          }
          return v;
        }).toList();

        emit(AdminVendorsLoaded(
          vendors: updatedVendors,
          currentPage: currentState.currentPage,
          hasReachedMax: currentState.hasReachedMax,
        ));
      } catch (e) {
        emit(AdminVendorsError('Failed to update vendor: $e'));
        emit(currentState);
      }
    }
  }
}
