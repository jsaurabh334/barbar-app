import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:barbar_app/data/models/settlement_model.dart';
import 'package:barbar_app/domain/repositories/admin_repository.dart';

part 'admin_wallet_event.dart';
part 'admin_wallet_state.dart';

class AdminWalletBloc extends Bloc<AdminWalletEvent, AdminWalletState> {
  final AdminRepository _adminRepository;

  AdminWalletBloc({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(AdminWalletInitial()) {
    on<LoadAdminWallets>(_onLoadAdminWallets);
    on<LoadAdminWalletDetail>(_onLoadAdminWalletDetail);
    on<CreditAdminWallet>(_onCreditAdminWallet);
    on<DebitAdminWallet>(_onDebitAdminWallet);
    on<ToggleAdminWalletFreeze>(_onToggleAdminWalletFreeze);
  }

  Future<void> _onLoadAdminWallets(LoadAdminWallets event, Emitter<AdminWalletState> emit) async {
    emit(AdminWalletLoading());
    try {
      final data = await _adminRepository.getAdminWallets(
        page: event.page,
        limit: 20,
        type: event.type,
        isActive: event.isActive,
      );
      final dynamic rawData = data['data'];
      final List<dynamic> items = rawData is List ? rawData : (rawData is Map ? (rawData['items'] ?? []) : []);
      final wallets = items.map((j) => WalletAdminModel.fromJson(j as Map<String, dynamic>)).toList();
      final pagination = (data['meta'] ?? data['pagination']) as Map<String, dynamic>? ?? {};
      final total = (pagination['total'] as num?)?.toInt() ?? wallets.length;
      emit(AdminWalletLoaded(
        wallets: wallets,
        currentPage: event.page,
        hasReachedMax: wallets.length < 20 || (event.page * 20) >= total,
        total: total,
      ));
    } catch (e) {
      emit(AdminWalletError(e.toString()));
    }
  }

  Future<void> _onLoadAdminWalletDetail(LoadAdminWalletDetail event, Emitter<AdminWalletState> emit) async {
    emit(AdminWalletDetailLoading());
    try {
      final data = await _adminRepository.getAdminWalletDetail(event.id);
      final wallet = WalletAdminModel.fromJson(data['wallet'] as Map<String, dynamic>);
      final transactions = (data['transactions'] as List<dynamic>?)
              ?.map((j) => Map<String, dynamic>.from(j as Map))
              .toList() ?? [];
      emit(AdminWalletDetailLoaded(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(AdminWalletError(e.toString()));
    }
  }

  Future<void> _onCreditAdminWallet(CreditAdminWallet event, Emitter<AdminWalletState> emit) async {
    try {
      await _adminRepository.creditAdminWallet(event.id, event.amount, description: event.description);
      emit(AdminWalletActionSuccess('Wallet credited with ${event.amount}'));
    } catch (e) {
      emit(AdminWalletError(e.toString()));
    }
  }

  Future<void> _onDebitAdminWallet(DebitAdminWallet event, Emitter<AdminWalletState> emit) async {
    try {
      await _adminRepository.debitAdminWallet(event.id, event.amount, description: event.description);
      emit(AdminWalletActionSuccess('Wallet debited with ${event.amount}'));
    } catch (e) {
      emit(AdminWalletError(e.toString()));
    }
  }

  Future<void> _onToggleAdminWalletFreeze(ToggleAdminWalletFreeze event, Emitter<AdminWalletState> emit) async {
    try {
      await _adminRepository.toggleAdminWalletFreeze(event.id);
      emit(AdminWalletActionSuccess('Wallet freeze status toggled'));
    } catch (e) {
      emit(AdminWalletError(e.toString()));
    }
  }
}
