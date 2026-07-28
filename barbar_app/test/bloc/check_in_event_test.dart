import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/presentation/bloc/check_in/check_in_event.dart';

void main() {
  group('CheckInEvent', () {
    group('LoadCheckInData', () {
      test('should have correct props', () {
        expect(const LoadCheckInData('booking-1').props, ['booking-1']);
      });

      test('should be equatable', () {
        expect(const LoadCheckInData('booking-1'), const LoadCheckInData('booking-1'));
        expect(const LoadCheckInData('booking-1'), isNot(const LoadCheckInData('booking-2')));
      });
    });

    group('CheckInWithQr', () {
      test('should have correct props', () {
        expect(const CheckInWithQr(bookingId: 'booking-1', token: 'qr-token').props, ['booking-1', 'qr-token']);
      });

      test('should be equatable', () {
        expect(const CheckInWithQr(bookingId: 'b1', token: 't1'), const CheckInWithQr(bookingId: 'b1', token: 't1'));
        expect(const CheckInWithQr(bookingId: 'b1', token: 't1'), isNot(const CheckInWithQr(bookingId: 'b1', token: 't2')));
      });
    });

    group('CheckInManual', () {
      test('should have correct props with lat/lng', () {
        expect(const CheckInManual(bookingId: 'b1', lat: 12.34, lng: 56.78).props, ['b1', 12.34, 56.78]);
      });

      test('should have correct props without lat/lng', () {
        expect(const CheckInManual(bookingId: 'b1').props, ['b1', null, null]);
      });

      test('should be equatable', () {
        expect(const CheckInManual(bookingId: 'b1'), isNot(const CheckInManual(bookingId: 'b2')));
      });
    });

    group('ImComing', () {
      test('should have correct props', () {
        expect(const ImComing('booking-1').props, ['booking-1']);
      });

      test('should be equatable', () {
        expect(const ImComing('b1'), const ImComing('b1'));
        expect(const ImComing('b1'), isNot(const ImComing('b2')));
      });
    });

    group('GetCallPermission', () {
      test('should have correct props', () {
        expect(const GetCallPermission('booking-1').props, ['booking-1']);
      });
    });

    group('ResetCheckIn', () {
      test('should have empty props', () {
        expect(ResetCheckIn().props, []);
      });

      test('should be equatable', () {
        expect(ResetCheckIn(), ResetCheckIn());
      });
    });
  });
}
