import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/data/models/booking_model.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_bloc.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_event.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_state.dart';

import '../mocks/fake_booking_repository.dart';

BookingModel _makeBooking({
  String id = 'b1',
  String status = BookingModel.statusInProgress,
}) {
  return BookingModel(
    id: id,
    barberId: 'barber-1',
    customerId: 'customer-1',
    status: status,
    scheduledStart: '2026-07-28T10:00:00Z',
    scheduledEnd: '2026-07-28T11:00:00Z',
    queuePosition: 0,
    estimatedWaitMinutes: 0,
    finalPrice: 0,
    paymentStatus: 'pending',
    isHomeService: true,
    customerName: 'Test Customer',
    shopName: 'Test Shop',
  );
}

Future<List<BookingState>> _runBloc(BookingBloc bloc, BookingEvent event) async {
  final states = <BookingState>[];
  final sub = bloc.stream.listen(states.add);
  bloc.add(event);
  await Future.delayed(const Duration(milliseconds: 100));
  await sub.cancel();
  await bloc.close();
  return states;
}

BookingState _last(List<BookingState> states) => states.last;

void main() {
  group('BookingBloc - End OTP flow', () {
    test('RequestCompletion moves booking to awaiting_customer_confirmation', () async {
      final repo = FakeBookingRepository()..addBooking(_makeBooking());
      final bloc = BookingBloc(repo);

      final states = await _runBloc(bloc, RequestCompletion('b1'));

      expect(states.any((s) => s is CompletionOtpActionSuccess), isTrue);
      final loaded = _last(states);
      expect(loaded, isA<BookingsLoaded>());
      final bookings = (loaded as BookingsLoaded).bookings;
      expect(bookings.single.status, BookingModel.statusAwaitingCustomerConfirmation);
      expect(bookings.single.endOtpGeneratedAt, isNotNull);
    });

    test('VerifyCompletionOtp with correct OTP completes the booking', () async {
      final repo = FakeBookingRepository()
        ..addBooking(_makeBooking(status: BookingModel.statusAwaitingCustomerConfirmation))
        ..setValidOtp('123456');
      final bloc = BookingBloc(repo);

      final states = await _runBloc(bloc, VerifyCompletionOtp(bookingId: 'b1', otp: '123456'));

      expect(states.any((s) => s is BookingCompletedSuccess), isTrue);
      final loaded = _last(states);
      expect(loaded, isA<BookingsLoaded>());
      final bookings = (loaded as BookingsLoaded).bookings;
      expect(bookings.single.status, BookingModel.statusCompleted);
      expect(bookings.single.endOtpVerifiedAt, isNotNull);
    });

    test('VerifyCompletionOtp with wrong OTP emits failure', () async {
      final repo = FakeBookingRepository()
        ..addBooking(_makeBooking(status: BookingModel.statusAwaitingCustomerConfirmation))
        ..setValidOtp('123456');
      final bloc = BookingBloc(repo);

      final states = await _runBloc(bloc, VerifyCompletionOtp(bookingId: 'b1', otp: '000000'));

      expect(states.any((s) => s is BookingFailure), isTrue);
      expect((_last(states) as BookingFailure).error, contains('Invalid OTP'));
    });

    test('ResendCompletionOtp emits success without changing status', () async {
      final repo = FakeBookingRepository()
        ..addBooking(_makeBooking(status: BookingModel.statusAwaitingCustomerConfirmation));
      final bloc = BookingBloc(repo);

      final states = await _runBloc(bloc, ResendCompletionOtp('b1'));

      expect(states.any((s) => s is CompletionOtpActionSuccess), isTrue);
      final loaded = _last(states);
      expect(loaded, isA<BookingsLoaded>());
      expect((loaded as BookingsLoaded).bookings.single.status,
          BookingModel.statusAwaitingCustomerConfirmation);
    });

    test('ProblemStillExists moves booking back to in_progress', () async {
      final repo = FakeBookingRepository()
        ..addBooking(_makeBooking(status: BookingModel.statusAwaitingCustomerConfirmation));
      final bloc = BookingBloc(repo);

      final states = await _runBloc(bloc, ProblemStillExists('b1'));

      final loaded = _last(states);
      expect(loaded, isA<BookingsLoaded>());
      final bookings = (loaded as BookingsLoaded).bookings;
      expect(bookings.single.status, BookingModel.statusInProgress);
      expect(bookings.single.endOtpGeneratedAt, isNull);
      expect(bookings.single.endOtpVerifiedAt, isNull);
    });

    test('RegenerateCompletionOtp emits success for the barber', () async {
      final repo = FakeBookingRepository()
        ..addBooking(_makeBooking(status: BookingModel.statusAwaitingCustomerConfirmation));
      final bloc = BookingBloc(repo);

      final states = await _runBloc(bloc, RegenerateCompletionOtp('b1'));

      expect(states.any((s) => s is CompletionOtpActionSuccess), isTrue);
      final loaded = _last(states);
      expect(loaded, isA<BookingsLoaded>());
      expect((loaded as BookingsLoaded).bookings.single.endOtpGeneratedAt, isNotNull);
    });
  });
}
