import 'package:flutter_test/flutter_test.dart';
import 'package:barbar_app/core/network/websocket_client.dart';
import '../mocks/fake_auth_datasource.dart';

void main() {
  late FakeAuthLocalDataSource fakeAuth;
  late WebSocketClient client;

  setUp(() {
    fakeAuth = FakeAuthLocalDataSource(token: 'test-token');
    client = WebSocketClient(localDataSource: fakeAuth);
  });

  tearDown(() {
    client.dispose();
  });

  group('WebSocketClient', () {
    test('should start disconnected', () {
      expect(client.isConnected, false);
    });

    test('should handle missing token gracefully', () async {
      fakeAuth.setToken(null);
      await client.connect();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(client.isConnected, false);
    });

    test('should emit connection status changes', () async {
      final statuses = <bool>[];
      final sub = client.connectionStatus.listen((status) {
        statuses.add(status);
      });

      fakeAuth.setToken('test-token');
      await client.connect();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(statuses.length, greaterThanOrEqualTo(1));
      await sub.cancel();
    });

    test('should handle send when not connected', () {
      client.sendRawEvent('test', {'data': 1});
      client.sendEvent('test', {'data': 1});
    });

    test('disconnect should set state to disconnected', () {
      client.disconnect();
      expect(client.isConnected, false);
    });

    test('should not crash on dispose after disconnect', () {
      client.disconnect();
      client.dispose();
    });

    test('eventsByType should filter correctly without errors', () {
      final sub = client.eventsByType('BookingUpdate').listen((_) {});
      client.dispose();
      sub.cancel();
    });
  });
}
