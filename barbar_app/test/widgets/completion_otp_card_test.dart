import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/data/models/booking_model.dart';
import 'package:barbar_app/presentation/bloc/booking/booking_bloc.dart';
import 'package:barbar_app/presentation/widgets/completion_otp_card.dart';

import '../mocks/fake_booking_repository.dart';

BookingModel _awaitingBooking() => BookingModel(
      id: 'booking-card-1234',
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

void main() {
  group('CompletionOtpCard', () {
    testWidgets('renders OTP, share, resend and problem actions', (tester) async {
      final repo = FakeBookingRepository()..addBooking(_awaitingBooking());
      final bloc = BookingBloc(repo);
      await tester.pumpWidget(
        BlocProvider<BookingBloc>(
          create: (_) => bloc,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompletionOtpCard(
                  booking: _awaitingBooking(),
                  otp: '483921',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Service Completed?'), findsOneWidget);
      expect(find.text('483921'), findsOneWidget);
      expect(find.text('Share OTP'), findsOneWidget);
      expect(find.text('RESEND OTP'), findsOneWidget);
      expect(find.text('PROBLEM STILL EXISTS'), findsOneWidget);
    });

    testWidgets('shows waiting message when OTP not yet received', (tester) async {
      final repo = FakeBookingRepository()..addBooking(_awaitingBooking());
      final bloc = BookingBloc(repo);
      await tester.pumpWidget(
        BlocProvider<BookingBloc>(
          create: (_) => bloc,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CompletionOtpCard(booking: _awaitingBooking()),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('OTP is on its way'), findsOneWidget);
      expect(find.text('Share OTP'), findsNothing);
    });
  });
}
