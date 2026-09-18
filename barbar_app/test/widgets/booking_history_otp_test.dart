import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/core/network/websocket_client.dart';
import 'package:barbar_app/data/models/booking_model.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_bloc.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_event.dart';
import 'package:barbar_app/presentation/bloc/check_in/check_in_bloc.dart';
import 'package:barbar_app/presentation/screens/booking_history_screen.dart';

import '../mocks/fake_auth_datasource.dart';
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

Widget _wrap(FakeBookingRepository repo) {
  final wsClient = WebSocketClient(localDataSource: FakeAuthLocalDataSource(token: 't'));
  return MultiBlocProvider(
    providers: [
      RepositoryProvider<WebSocketClient>.value(value: wsClient),
      BlocProvider<BookingBloc>(
        create: (_) => BookingBloc(repo)..add(FetchAllBookings()),
      ),
      BlocProvider<CheckInBloc>(
        create: (_) => CheckInBloc(repo, wsClient),
      ),
    ],
    child: const MaterialApp(
      home: BookingHistoryScreen(),
    ),
  );
}

void main() {
  group('BookingHistoryScreen - End OTP card', () {
    testWidgets('shows OTP card with resend and problem buttons for awaiting booking',
        (tester) async {
      final repo = FakeBookingRepository()..addBooking(_awaitingBooking());
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Completion'), findsOneWidget);
      expect(find.text('Service Completed?'), findsOneWidget);
      expect(find.text('RESEND OTP'), findsOneWidget);
      expect(find.text('PROBLEM STILL EXISTS'), findsOneWidget);
    });

    testWidgets('tapping RESEND OTP notifies the customer', (tester) async {
      final repo = FakeBookingRepository()..addBooking(_awaitingBooking());
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESEND OTP'));
      await tester.pumpAndSettle();

      expect(find.text('A new OTP has been sent to you'), findsOneWidget);
    });

    testWidgets('confirming Problem Still Exists moves booking back to in_progress',
        (tester) async {
      final repo = FakeBookingRepository()..addBooking(_awaitingBooking());
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PROBLEM STILL EXISTS'));
      await tester.pumpAndSettle();
      expect(find.text('Report Problem?'), findsOneWidget);

      await tester.tap(find.text('REPORT'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Completion'), findsNothing);
      expect(find.text('PROBLEM STILL EXISTS'), findsNothing);
      expect(find.text('IN PROGRESS'), findsOneWidget,
          reason: 'booking card should show in-progress state again');
    });
  });
}

