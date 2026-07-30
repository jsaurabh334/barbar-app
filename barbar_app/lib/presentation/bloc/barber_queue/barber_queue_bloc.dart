import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/websocket_client.dart';
import '../../../data/models/booking_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'barber_queue_event.dart';
import 'barber_queue_state.dart';

class BarberQueueBloc extends Bloc<BarberQueueEvent, BarberQueueState> {
  final BookingRepository _bookingRepository;
  final WebSocketClient _wsClient;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  BarberQueueBloc(this._bookingRepository, this._wsClient) : super(BarberQueueInitial()) {
    on<LoadTodayQueue>(_onLoadTodayQueue);
    on<LoadTodayQueueRefresh>(_onLoadTodayQueueRefresh);
    on<FilterByStaff>(_onFilterByStaff);
    on<SkipCustomer>(_onSkipCustomer);
    on<StartService>(_onStartService);
    on<CompleteService>(_onCompleteService);
    on<MarkNoShow>(_onMarkNoShow);
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTodayQueue(LoadTodayQueue event, Emitter<BarberQueueState> emit) async {
    emit(BarberQueueLoading());
    await _fetchQueue(event.staffId, emit);
  }

  Future<void> _onLoadTodayQueueRefresh(LoadTodayQueueRefresh event, Emitter<BarberQueueState> emit) async {
    await _fetchQueue(event.staffId, emit);
  }

  Future<void> _onFilterByStaff(FilterByStaff event, Emitter<BarberQueueState> emit) async {
    emit(BarberQueueLoading());
    await _fetchQueue(event.staffId, emit);
  }

  Future<void> _fetchQueue(String? staffId, Emitter<BarberQueueState> emit) async {
    try {
      final data = await _bookingRepository.getTodayQueue(staffId: staffId);

      List<BookingModel> parseList(dynamic raw) {
        if (raw is List) {
          return raw.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      }

      List<BookingModel> serving = parseList(data['serving']);
      List<BookingModel> next = parseList(data['next']);
      List<BookingModel> waiting = parseList(data['waiting']);
      List<BookingModel> late = parseList(data['late']);
      List<BookingModel> upcoming = parseList(data['upcoming']);

      if (data['bookings'] != null && data['bookings'] is List) {
        final allBookings = parseList(data['bookings']);
        serving = allBookings.where((b) => b.status == 'in_progress').toList();
        next = allBookings.where((b) => b.status == 'next').toList();
        waiting = allBookings.where((b) => b.status == 'checked_in' || b.status == 'waiting').toList();
        late = allBookings.where((b) => b.isLate && (b.status == 'confirmed' || b.status == 'checked_in' || b.status == 'waiting')).toList();
        upcoming = allBookings.where((b) => b.status == 'confirmed' && !b.isLate).toList();
      }

      final staffList = (data['staff'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final shopName = (data['shop_name'] as String?) ?? '';
      final shopAddress = (data['shop_address'] as String?) ?? '';

      _listenForUpdates(staffId);
      emit(TodayQueueLoaded(
        serving: serving,
        next: next,
        waiting: waiting,
        late: late,
        upcoming: upcoming,
        activeStaffId: staffId,
        availableStaff: staffList,
        shopName: shopName,
        shopAddress: shopAddress,
      ));
    } catch (e) {
      emit(BarberQueueFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSkipCustomer(SkipCustomer event, Emitter<BarberQueueState> emit) async {
    try {
      await _bookingRepository.skipCustomer(event.bookingId);
      final current = state;
      if (current is TodayQueueLoaded) {
        add(LoadTodayQueueRefresh(staffId: current.activeStaffId));
      }
      emit(BarberQueueActionSuccess('Customer skipped'));
    } catch (e) {
      emit(BarberQueueFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onStartService(StartService event, Emitter<BarberQueueState> emit) async {
    try {
      await _bookingRepository.startService(event.bookingId);
      final current = state;
      if (current is TodayQueueLoaded) {
        add(LoadTodayQueueRefresh(staffId: current.activeStaffId));
      }
      emit(BarberQueueActionSuccess('Service started'));
    } catch (e) {
      emit(BarberQueueFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCompleteService(CompleteService event, Emitter<BarberQueueState> emit) async {
    try {
      await _bookingRepository.completeService(event.bookingId);
      final current = state;
      if (current is TodayQueueLoaded) {
        add(LoadTodayQueueRefresh(staffId: current.activeStaffId));
      }
      emit(BarberQueueActionSuccess('Service completed'));
    } catch (e) {
      emit(BarberQueueFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onMarkNoShow(MarkNoShow event, Emitter<BarberQueueState> emit) async {
    try {
      await _bookingRepository.markNoShow(event.bookingId);
      final current = state;
      if (current is TodayQueueLoaded) {
        add(LoadTodayQueueRefresh(staffId: current.activeStaffId));
      }
      emit(BarberQueueActionSuccess('Marked as no-show'));
    } catch (e) {
      emit(BarberQueueFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _listenForUpdates(String? staffId) {
    _wsSubscription?.cancel();
    _wsSubscription = _wsClient.eventsByType('QueueUpdate').listen((event) {
      final current = state;
      if (current is TodayQueueLoaded) {
        add(LoadTodayQueueRefresh(staffId: current.activeStaffId));
      }
    });
  }
}
