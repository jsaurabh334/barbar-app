import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  BookingBloc(this._bookingRepository) : super(BookingInitial()) {
    on<FetchServices>(_onFetchServices);
    on<FetchAvailableSlots>(_onFetchAvailableSlots);
    on<CreateBooking>(_onCreateBooking);
    on<CheckQueuePosition>(_onCheckQueuePosition);
    on<CancelBooking>(_onCancelBooking);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<StreamQueuePositionUpdate>(_onStreamQueuePositionUpdate);
    on<FetchAllBookings>(_onFetchAllBookings);
    on<FetchBarberBookings>(_onFetchBarberBookings);
    on<PayBooking>(_onPayBooking);
    on<FetchHomeServiceRequests>(_onFetchHomeServiceRequests);
    on<AcceptHomeServiceRequest>(_onAcceptHomeServiceRequest);
    on<RejectHomeServiceRequest>(_onRejectHomeServiceRequest);
  }

  Future<void> _onFetchServices(FetchServices event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final services = await _bookingRepository.getServices(event.barberId);
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchAvailableSlots(FetchAvailableSlots event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final slots = await _bookingRepository.getAvailableSlots(event.barberId, event.date);
      emit(AvailableSlotsLoaded(slots));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateBooking(CreateBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final booking = await _bookingRepository.createBooking(
        barberId: event.barberId,
        serviceIds: event.serviceIds,
        scheduledStart: event.scheduledStart,
        staffId: event.staffId,
        isHomeService: event.isHomeService,
        homeServiceAddressId: event.homeServiceAddressId,
      );
      emit(BookingCreatedSuccess(booking));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCheckQueuePosition(CheckQueuePosition event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final data = await _bookingRepository.getQueuePosition(event.bookingId);
      emit(QueuePositionLoaded(
        currentPosition: data['current_position'] as int,
        peopleAhead: data['people_ahead'] as int,
        estimatedWaitMin: data['estimated_wait_min'] as int,
      ));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancelBooking(CancelBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.cancelBooking(event.bookingId, reason: event.reason);
      final bookings = await _bookingRepository.getAllBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateBookingStatus(UpdateBookingStatus event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.updateBookingStatus(event.bookingId, event.status);
      final bookings = await _bookingRepository.getBarberBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onStreamQueuePositionUpdate(StreamQueuePositionUpdate event, Emitter<BookingState> emit) {
    emit(QueuePositionLoaded(
      currentPosition: event.newPosition,
      peopleAhead: event.newPosition > 0 ? event.newPosition - 1 : 0,
      estimatedWaitMin: event.estimatedWaitMin,
      remainingTime: event.remainingTime,
      currentlyServing: event.currentlyServing,
    ));
  }

  Future<void> _onFetchAllBookings(FetchAllBookings event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final bookings = await _bookingRepository.getAllBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchBarberBookings(FetchBarberBookings event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final bookings = await _bookingRepository.getBarberBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPayBooking(PayBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.payBooking(event.bookingId, event.method, event.status, event.reference);
      final bookings = await _bookingRepository.getAllBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchHomeServiceRequests(FetchHomeServiceRequests event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final requests = await _bookingRepository.getHomeServiceRequests();
      emit(BookingsLoaded(requests));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAcceptHomeServiceRequest(AcceptHomeServiceRequest event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.acceptHomeService(event.bookingId);
      final requests = await _bookingRepository.getHomeServiceRequests();
      emit(BookingsLoaded(requests));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRejectHomeServiceRequest(RejectHomeServiceRequest event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.rejectHomeService(event.bookingId, event.reason);
      final requests = await _bookingRepository.getHomeServiceRequests();
      emit(BookingsLoaded(requests));
    } catch (e) {
      emit(BookingFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
