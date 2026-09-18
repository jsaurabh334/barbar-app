import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/data/models/booking_model.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_bloc.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_state.dart';
import 'package:barbar_app/presentation/screens/barber/booking_detail_screen.dart';

import '../mocks/fake_booking_repository.dart';

BookingModel _awaitingBooking() => BookingModel(
      id: 'booking-b1-1234',
      barberId: 'barber-1',
      customerId: 'customer-1',
      status: BookingModel.statusAwaitingCustomerConfirmation,
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

Widget _wrap(BookingBloc bloc, BookingModel booking) {
  return BlocProvider<BookingBloc>(
    create: (_) => bloc,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BarberBookingDetailScreen(booking: booking),
                ),
              ),
              child: const Text('open-detail'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openDetail(WidgetTester tester) async {
  await tester.tap(find.text('open-detail'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _scrollToVerify(WidgetTester tester) async {
  await tester.ensureVisible(find.text('VERIFY OTP'));
  await tester.pump();
}

void main() {
  group('BarberBookingDetailScreen - End OTP', () {
    testWidgets('shows OTP verification section for awaiting confirmation',
        (tester) async {
      final repo = FakeBookingRepository()..addBooking(_awaitingBooking());
      final bloc = BookingBloc(repo);
      await tester.pumpWidget(_wrap(bloc, _awaitingBooking()));
      await _openDetail(tester);

      expect(find.text('Customer Confirmation'), findsOneWidget);
      expect(find.text('VERIFY OTP'), findsOneWidget);
      expect(find.text('REGENERATE OTP'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('verify with correct OTP completes and pops', (tester) async {
      final repo = FakeBookingRepository()
        ..addBooking(_awaitingBooking())
        ..setValidOtp('123456');
      final bloc = BookingBloc(repo);
      await tester.pumpWidget(_wrap(bloc, _awaitingBooking()));
      await _openDetail(tester);

      await tester.enterText(find.byType(TextField), '123456');
      await _scrollToVerify(tester);
      await tester.tap(find.text('VERIFY OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(bloc.state, isA<BookingsLoaded>());
      final loaded = bloc.state as BookingsLoaded;
      expect(loaded.bookings.single.status, BookingModel.statusCompleted);
      expect(find.text('open-detail'), findsOneWidget,
          reason: 'screen should pop back to the dashboard launcher');
      expect(find.text('Service completed \u2014 customer approved'), findsOneWidget);
    });

    testWidgets('verify with wrong OTP keeps screen open with failure state',
        (tester) async {
      final repo = FakeBookingRepository()
        ..addBooking(_awaitingBooking())
        ..setValidOtp('123456');
      final bloc = BookingBloc(repo);
      await tester.pumpWidget(_wrap(bloc, _awaitingBooking()));
      await _openDetail(tester);

      await tester.enterText(find.byType(TextField), '000000');
      await _scrollToVerify(tester);
      await tester.tap(find.text('VERIFY OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(bloc.state, isA<BookingFailure>());
      expect((bloc.state as BookingFailure).error, contains('Invalid OTP'));
      expect(find.text('VERIFY OTP'), findsOneWidget,
          reason: 'screen should stay open so the barber can retry');
    });
  });
}
