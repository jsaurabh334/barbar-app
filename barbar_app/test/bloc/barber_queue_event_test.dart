import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/presentation/bloc/barber_queue/barber_queue_event.dart';

void main() {
  group('BarberQueueEvent', () {
    group('LoadTodayQueue', () {
      test('should have correct props without staffId', () {
        expect(const LoadTodayQueue().props, [null]);
      });

      test('should have correct props with staffId', () {
        expect(const LoadTodayQueue(staffId: 'staff-1').props, ['staff-1']);
      });

      test('should be equatable', () {
        expect(const LoadTodayQueue(), const LoadTodayQueue());
        expect(const LoadTodayQueue(staffId: 's1'), const LoadTodayQueue(staffId: 's1'));
        expect(const LoadTodayQueue(staffId: 's1'), isNot(const LoadTodayQueue(staffId: 's2')));
        expect(const LoadTodayQueue(staffId: 's1'), isNot(const LoadTodayQueue()));
      });
    });

    group('LoadTodayQueueRefresh', () {
      test('should have correct props', () {
        expect(const LoadTodayQueueRefresh().props, [null]);
        expect(const LoadTodayQueueRefresh(staffId: 's1').props, ['s1']);
      });
    });

    group('FilterByStaff', () {
      test('should have correct props with null', () {
        expect(const FilterByStaff(null).props, [null]);
      });

      test('should have correct props with staffId', () {
        expect(const FilterByStaff('staff-1').props, ['staff-1']);
      });

      test('should be equatable', () {
        expect(const FilterByStaff('s1'), const FilterByStaff('s1'));
        expect(const FilterByStaff(null), const FilterByStaff(null));
        expect(const FilterByStaff('s1'), isNot(const FilterByStaff('s2')));
        expect(const FilterByStaff('s1'), isNot(const FilterByStaff(null)));
      });
    });

    group('SkipCustomer', () {
      test('should have correct props', () {
        expect(const SkipCustomer('booking-1').props, ['booking-1']);
      });
    });

    group('StartService', () {
      test('should have correct props', () {
        expect(const StartService('booking-1').props, ['booking-1']);
      });
    });

    group('CompleteService', () {
      test('should have correct props', () {
        expect(const CompleteService('booking-1').props, ['booking-1']);
      });
    });

    group('MarkNoShow', () {
      test('should have correct props', () {
        expect(const MarkNoShow('booking-1').props, ['booking-1']);
      });
    });
  });
}
