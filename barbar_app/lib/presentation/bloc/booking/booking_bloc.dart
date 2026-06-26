import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  BookingBloc(this._bookingRepository) : super(BookingInitial()) {
    on<FetchServices>(_onFetchServices);
    on<CreateBooking>(_onCreateBooking);
    on<CheckQueuePosition>(_onCheckQueuePosition);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<StreamQueuePositionUpdate>(_onStreamQueuePositionUpdate);
    on<FetchAllBookings>(_onFetchAllBookings);
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

  Future<void> _onCreateBooking(CreateBooking event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final booking = await _bookingRepository.createBooking(
        barberId: event.barberId,
        serviceIds: event.serviceIds,
        scheduledStart: event.scheduledStart,
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

  Future<void> _onUpdateBookingStatus(UpdateBookingStatus event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      await _bookingRepository.updateBookingStatus(event.bookingId, event.status);
      final bookings = await _bookingRepository.getAllBookings();
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
}
