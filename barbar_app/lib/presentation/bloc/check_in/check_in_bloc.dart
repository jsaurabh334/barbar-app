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

  Future<void> _onLoadCheckInData(LoadCheckInData event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      final data = await _bookingRepository.getCallPermission(event.bookingId);
      final booking = BookingModel.fromJson(data);
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
      final data = await _bookingRepository.getCallPermission(event.bookingId);
      emit(CheckedInSuccess(BookingModel.fromJson(data)));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckInManual(CheckInManual event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      await _bookingRepository.checkIn(event.bookingId, 'manual', lat: event.lat, lng: event.lng);
      final data = await _bookingRepository.getCallPermission(event.bookingId);
      emit(CheckedInSuccess(BookingModel.fromJson(data)));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onImComing(ImComing event, Emitter<CheckInState> emit) async {
    emit(CheckInLoading());
    try {
      await _bookingRepository.imComing(event.bookingId);
      final data = await _bookingRepository.getCallPermission(event.bookingId);
      emit(ImComingSuccess(BookingModel.fromJson(data)));
    } catch (e) {
      emit(CheckInFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGetCallPermission(GetCallPermission event, Emitter<CheckInState> emit) async {
    try {
      final data = await _bookingRepository.getCallPermission(event.bookingId);
      final booking = BookingModel.fromJson(data);
      emit(CallPermissionLoaded(
        canCallShop: booking.canCallShop,
        canCallCustomer: booking.canCallCustomer,
        maskedShopPhone: booking.maskedShopPhone,
        maskedCustomerPhone: booking.maskedCustomerPhone,
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
