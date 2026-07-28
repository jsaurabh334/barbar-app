import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/presentation/bloc/check_in/check_in_state.dart';
import 'package:barbar_app/data/models/booking_model.dart';

BookingModel _makeBooking({String id = 'b1', String status = 'confirmed'}) {
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
  );
}

void main() {
  group('CheckInState', () {
    group('CheckInInitial', () {
      test('should have empty props', () {
        expect(CheckInInitial().props, []);
      });
    });

    group('CheckInLoading', () {
      test('should have empty props', () {
        expect(CheckInLoading().props, []);
      });
    });

    group('CheckInDataLoaded', () {
      test('should have booking in props', () {
        final booking = _makeBooking();
        expect(CheckInDataLoaded(booking).props, [booking]);
      });
    });

    group('CheckedInSuccess', () {
      test('should have booking in props', () {
        final booking = _makeBooking(status: 'checked_in');
        expect(CheckedInSuccess(booking).props, [booking]);
      });
    });

    group('ImComingSuccess', () {
      test('should have booking in props', () {
        final booking = _makeBooking();
        expect(ImComingSuccess(booking).props, [booking]);
      });
    });

    group('CallPermissionLoaded', () {
      test('should have correct props', () {
        const state = CallPermissionLoaded(
          canCallShop: true,
          canCallCustomer: false,
          maskedShopPhone: '12******90',
          maskedCustomerPhone: '98******10',
        );
        expect(state.props, [true, false, '12******90', '98******10']);
      });

      test('should be equatable', () {
        const s1 = CallPermissionLoaded(canCallShop: true, canCallCustomer: false);
        const s2 = CallPermissionLoaded(canCallShop: true, canCallCustomer: false);
        const s3 = CallPermissionLoaded(canCallShop: false, canCallCustomer: false);
        expect(s1, s2);
        expect(s1, isNot(s3));
      });
    });

    group('CheckInFailure', () {
      test('should have error in props', () {
        const state = CheckInFailure('Something went wrong');
        expect(state.props, ['Something went wrong']);
      });

      test('should be equatable', () {
        expect(const CheckInFailure('error'), const CheckInFailure('error'));
        expect(const CheckInFailure('error'), isNot(const CheckInFailure('different')));
      });
    });
  });
}
