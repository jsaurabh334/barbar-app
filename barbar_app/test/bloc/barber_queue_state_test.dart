import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/presentation/bloc/barber_queue/barber_queue_state.dart';
import 'package:barbar_app/data/models/booking_model.dart';

final _serving = BookingModel(
  id: 's1',
  barberId: 'barber-1',
  customerId: 'c1',
  status: 'in_progress',
  scheduledStart: '2026-07-28T10:00:00Z',
  scheduledEnd: '2026-07-28T11:00:00Z',
  queuePosition: 1,
  estimatedWaitMinutes: 10,
  finalPrice: 30,
  paymentStatus: 'unpaid',
);

final _waiting = BookingModel(
  id: 'w1',
  barberId: 'barber-1',
  customerId: 'c2',
  status: 'waiting',
  scheduledStart: '2026-07-28T10:00:00Z',
  scheduledEnd: '2026-07-28T11:00:00Z',
  queuePosition: 2,
  estimatedWaitMinutes: 30,
  finalPrice: 25,
  paymentStatus: 'unpaid',
);

void main() {
  group('BarberQueueState', () {
    group('BarberQueueInitial', () {
      test('should have empty props', () {
        expect(BarberQueueInitial().props, []);
      });
    });

    group('BarberQueueLoading', () {
      test('should have empty props', () {
        expect(BarberQueueLoading().props, []);
      });
    });

    group('TodayQueueLoaded', () {
      test('should have correct default props', () {
        const state = TodayQueueLoaded();
        expect(state.serving, []);
        expect(state.next, []);
        expect(state.waiting, []);
        expect(state.late, []);
        expect(state.upcoming, []);
        expect(state.activeStaffId, null);
        expect(state.availableStaff, []);
      });

      test('should include all sections in props', () {
        final state = TodayQueueLoaded(
          serving: [_serving],
          waiting: [_waiting],
          activeStaffId: 's1',
        );
        expect(state.serving.contains(_serving), true);
        expect(state.waiting.contains(_waiting), true);
        expect(state.activeStaffId, 's1');
      });

      test('copyWith should update only specified fields', () {
        const state = TodayQueueLoaded();
        final modified = state.copyWith(activeStaffId: 'staff-1');
        expect(modified.activeStaffId, 'staff-1');
        expect(modified.serving, []);
        expect(modified.waiting, []);
      });
    });

    group('BarberQueueActionSuccess', () {
      test('should have message in props', () {
        const state = BarberQueueActionSuccess('Customer skipped');
        expect(state.props, ['Customer skipped']);
      });
    });

    group('BarberQueueFailure', () {
      test('should have error in props', () {
        const state = BarberQueueFailure('Queue error');
        expect(state.props, ['Queue error']);
      });
    });
  });
}
