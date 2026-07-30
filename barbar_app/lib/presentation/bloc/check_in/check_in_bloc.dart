import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/websocket_client.dart';
import '../../../data/models/booking_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'check_in_event.dart';
import 'check_in_state.dart';

class CheckInBloc extends Bloc<CheckInEvent, CheckInState> {
  final BookingRepository _bookingRepository;
  final WebSocketClient _wsClient;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  CheckInBloc(this._bookingRepository, this._wsClient) : super(CheckInInitial()) {
    on<LoadCheckInData>(_onLoadCheckInData);
    on<CheckInWithQr>(_onCheckInWithQr);
    on<CheckInManual>(_onCheckInManual);
    on<ImComing>(_onImComing);
    on<GetCallPermission>(_onGetCallPermission);
    on<ResetCheckIn>(_onReset);
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<BookingModel> _fetchBookingWithPermission(String bookingId) async {
    final booking = await _bookingRepository.getBookingById(bookingId);
    try {
      final callData = await _bookingRepository.getCallPermission(bookingId);
      return booking.copyWith(
        canCallShop: callData['can_call_shop'] as bool? ?? false,
        canCallCustomer: callData['can_call_customer'] as bool? ?? false,
        maskedShopPhone: callData['shop_phone'] as String?,
        maskedCustomerPhone: callData['customer_phone'] as String?,
      );
    } catch (_) {
      return booking;
    }
  }

  Future<void> _onLoadCheckInData(LoadCheckInData event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      final booking = await _fetchBookingWithPermission(event.bookingId);
      _listenForUpdates(booking.id);
      emit(CheckInDataLoaded(booking));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckInWithQr(CheckInWithQr event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      await _bookingRepository.checkIn(event.bookingId, 'qr', token: event.token);
      final booking = await _fetchBookingWithPermission(event.bookingId);
      emit(CheckedInSuccess(booking));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckInManual(CheckInManual event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      await _bookingRepository.checkIn(event.bookingId, 'manual', lat: event.lat, lng: event.lng);
      final booking = await _fetchBookingWithPermission(event.bookingId);
      emit(CheckedInSuccess(booking));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onImComing(ImComing event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      await _bookingRepository.imComing(event.bookingId);
      final booking = await _fetchBookingWithPermission(event.bookingId);
      emit(ImComingSuccess(booking));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGetCallPermission(GetCallPermission event, Emitter<CheckInState> emit) async {
    try {
      final data = await _bookingRepository.getCallPermission(event.bookingId);
      emit(CallPermissionLoaded(
        canCallShop: data['can_call_shop'] as bool? ?? false,
        canCallCustomer: data['can_call_customer'] as bool? ?? false,
        maskedShopPhone: data['shop_phone'] as String?,
        maskedCustomerPhone: data['customer_phone'] as String?,
      ));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onReset(ResetCheckIn event, Emitter<CheckInState> emit) {
    _wsSubscription?.cancel();
    emit(CheckInInitial());
  }

  void _listenForUpdates(String bookingId) {
    _wsSubscription?.cancel();
    _wsSubscription = _wsClient.eventsByType('BookingUpdate').listen((event) {
      final payload = event['payload'] as Map<String, dynamic>?;
      if (payload != null && payload['id'] == bookingId) {
        final current = state;
        if (current is CheckInDataLoaded || current is CheckedInSuccess || current is ImComingSuccess) {
          add(LoadCheckInData(bookingId));
        }
      }
    });
  }
}
