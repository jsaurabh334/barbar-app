import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/data/models/booking_model.dart';

void main() {
  group('BookingModel - new fields', () {
    test('should parse queue_assigned_at from JSON', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'confirmed',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 3,
        'estimated_wait_minutes': 15,
        'final_price': 30.0,
        'payment_status': 'unpaid',
        'queue_assigned_at': '2026-07-28T09:30:00Z',
        'is_late': true,
        'late_at': '2026-07-28T10:05:00Z',
        'grace_extended_until': '2026-07-28T10:20:00Z',
        'im_coming_at': '2026-07-28T10:02:00Z',
        'can_call_shop': true,
        'can_call_customer': false,
        'shop_phone': '12******90',
        'customer_phone': '98******10',
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.queueAssignedAt, '2026-07-28T09:30:00Z');
      expect(booking.isLate, true);
      expect(booking.lateAt, '2026-07-28T10:05:00Z');
      expect(booking.graceExtendedUntil, '2026-07-28T10:20:00Z');
      expect(booking.imComingAt, '2026-07-28T10:02:00Z');
      expect(booking.canCallShop, true);
      expect(booking.canCallCustomer, false);
      expect(booking.maskedShopPhone, '12******90');
      expect(booking.maskedCustomerPhone, '98******10');
    });

    test('should default new fields when absent from JSON', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'confirmed',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 0,
        'estimated_wait_minutes': 0,
        'final_price': 0.0,
        'payment_status': 'pending',
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.queueAssignedAt, isNull);
      expect(booking.isLate, false);
      expect(booking.lateAt, isNull);
      expect(booking.graceExtendedUntil, isNull);
      expect(booking.imComingAt, isNull);
      expect(booking.canCallShop, false);
      expect(booking.canCallCustomer, false);
      expect(booking.maskedShopPhone, isNull);
      expect(booking.maskedCustomerPhone, isNull);
    });

    test('should not include canCall/masked fields in toJson', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'confirmed',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 0,
        'estimated_wait_minutes': 0,
        'final_price': 0.0,
        'payment_status': 'pending',
      };

      final booking = BookingModel.fromJson(json);
      final output = booking.toJson();
      expect(output['can_call_shop'], isNull);
      expect(output['can_call_customer'], isNull);
      expect(output['shop_phone'], isNull);
      expect(output['customer_phone'], isNull);
    });

    test('copyWith should update new fields', () {
      final base = BookingModel(
        id: 'b1',
        barberId: 'bar-1',
        customerId: 'c1',
        status: 'confirmed',
        scheduledStart: '2026-07-28T10:00:00Z',
        scheduledEnd: '2026-07-28T11:00:00Z',
        queuePosition: 0,
        estimatedWaitMinutes: 0,
        finalPrice: 0,
        paymentStatus: 'pending',
        isLate: false,
      );

      final modified = base.copyWith(
        queueAssignedAt: '2026-07-28T09:30:00Z',
        isLate: true,
        lateAt: '2026-07-28T10:05:00Z',
        graceExtendedUntil: '2026-07-28T10:20:00Z',
        imComingAt: '2026-07-28T10:02:00Z',
      );

      expect(modified.queueAssignedAt, '2026-07-28T09:30:00Z');
      expect(modified.isLate, true);
      expect(modified.lateAt, '2026-07-28T10:05:00Z');
      expect(modified.graceExtendedUntil, '2026-07-28T10:20:00Z');
      expect(modified.imComingAt, '2026-07-28T10:02:00Z');
      expect(base.isLate, false, reason: 'original should be unchanged');
    });

    test('should handle services list in JSON', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'confirmed',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 1,
        'estimated_wait_minutes': 5,
        'final_price': 50.0,
        'payment_status': 'paid',
        'services': [
          {'id': 'svc-1', 'name': 'Haircut', 'price': 30.0, 'duration_minutes': 30, 'quantity': 1},
          {'id': 'svc-2', 'name': 'Shave', 'price': 20.0, 'duration_minutes': 20, 'quantity': 1},
        ],
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.services.length, 2);
      expect(booking.services[0].name, 'Haircut');
      expect(booking.services[1].price, 20.0);
    });
  });

  group('BookingModel - end OTP fields', () {
    test('should parse end_otp_generated_at / end_otp_verified_at from JSON', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'awaiting_customer_confirmation',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 0,
        'estimated_wait_minutes': 0,
        'final_price': 0.0,
        'payment_status': 'pending',
        'is_home_service': true,
        'end_otp_generated_at': '2026-07-28T11:00:00Z',
        'end_otp_verified_at': null,
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.status, BookingModel.statusAwaitingCustomerConfirmation);
      expect(booking.endOtpGeneratedAt, '2026-07-28T11:00:00Z');
      expect(booking.endOtpVerifiedAt, isNull);
      expect(booking.isAwaitingCustomerConfirmation, isTrue);
      expect(booking.isCompletedBooking, isFalse);
    });

    test('should default end OTP fields when absent', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'in_progress',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 0,
        'estimated_wait_minutes': 0,
        'final_price': 0.0,
        'payment_status': 'pending',
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.endOtpGeneratedAt, isNull);
      expect(booking.endOtpVerifiedAt, isNull);
      expect(booking.isAwaitingCustomerConfirmation, isFalse);
    });

    test('should parse end_otp_verified_at when booking completed', () {
      final json = {
        'id': 'booking-1',
        'barber_id': 'barber-1',
        'customer_id': 'customer-1',
        'status': 'completed',
        'scheduled_start': '2026-07-28T10:00:00Z',
        'scheduled_end': '2026-07-28T11:00:00Z',
        'queue_position': 0,
        'estimated_wait_minutes': 0,
        'final_price': 0.0,
        'payment_status': 'paid',
        'end_otp_verified_at': '2026-07-28T11:00:00Z',
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.status, BookingModel.statusCompleted);
      expect(booking.endOtpVerifiedAt, '2026-07-28T11:00:00Z');
      expect(booking.isCompletedBooking, isTrue);
    });

    test('copyWith should update end OTP fields without mutating original', () {
      final base = BookingModel(
        id: 'b1',
        barberId: 'bar-1',
        customerId: 'c1',
        status: BookingModel.statusInProgress,
        scheduledStart: '2026-07-28T10:00:00Z',
        scheduledEnd: '2026-07-28T11:00:00Z',
        queuePosition: 0,
        estimatedWaitMinutes: 0,
        finalPrice: 0,
        paymentStatus: 'pending',
        isHomeService: true,
      );

      final modified = base.copyWith(
        status: BookingModel.statusCompleted,
        endOtpGeneratedAt: '2026-07-28T10:55:00Z',
        endOtpVerifiedAt: '2026-07-28T11:00:00Z',
      );

      expect(modified.status, BookingModel.statusCompleted);
      expect(modified.endOtpGeneratedAt, '2026-07-28T10:55:00Z');
      expect(modified.endOtpVerifiedAt, '2026-07-28T11:00:00Z');
      expect(base.status, BookingModel.statusInProgress, reason: 'original should be unchanged');
      expect(base.endOtpVerifiedAt, isNull);
    });

    test('toJson should include end OTP fields', () {
      final booking = BookingModel(
        id: 'b1',
        barberId: 'bar-1',
        customerId: 'c1',
        status: BookingModel.statusAwaitingCustomerConfirmation,
        scheduledStart: '2026-07-28T10:00:00Z',
        scheduledEnd: '2026-07-28T11:00:00Z',
        queuePosition: 0,
        estimatedWaitMinutes: 0,
        finalPrice: 0,
        paymentStatus: 'pending',
        endOtpGeneratedAt: '2026-07-28T10:55:00Z',
      );

      final output = booking.toJson();
      expect(output['end_otp_generated_at'], '2026-07-28T10:55:00Z');
      expect(output['end_otp_verified_at'], isNull);
    });
  });
}
