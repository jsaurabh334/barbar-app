import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import '../constants/constants.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

class WebSocketClient {
  final AuthLocalDataSource _localDataSource;
  final Dio _dio;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  Timer? _heartbeatTimer;
  DateTime _lastEventTimestamp = DateTime.now().subtract(const Duration(hours: 1));

  WebSocketClient({AuthLocalDataSource? localDataSource, Dio? dio})
      : _localDataSource = localDataSource ?? AuthLocalDataSource(),
        _dio = dio ?? Dio();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;
    _shouldReconnect = true;

    final token = await _localDataSource.getAccessToken();
    if (token == null) {
      _setConnectionState(false);
      _scheduleReconnect();
      return;
    }

    final wsUri = Uri.parse('${AppConfig.wsBaseUrl}?token=$token');

    try {
      _channel = WebSocketChannel.connect(wsUri);

      _channel!.ready.catchError((error) {
        _setConnectionState(false);
        _scheduleReconnect();
      });

      _setConnectionState(true);
      _reconnectAttempt = 0;

      _startHeartbeat();

      _channel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(message as String);
            if (decoded['type'] == 'pong') return;
            _eventController.add(decoded);
          } catch (_) {}
        },
        onError: (err) {
          _stopHeartbeat();
          _setConnectionState(false);
          _scheduleReconnect();
        },
        onDone: () {
          _stopHeartbeat();
          _setConnectionState(false);
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _setConnectionState(false);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _setConnectionState(false);
  }

  void subscribeOrder(String orderId) {
    sendRawEvent('subscribe_order', orderId);
  }

  Stream<Map<String, dynamic>> eventsByType(String type) {
    return _eventController.stream.where((event) {
      final eventType = event['type'] as String?;
      if (eventType == type) return true;
      final payloadEvent = event['payload'] is Map
          ? (event['payload'] as Map)['event'] as String?
          : null;
      return payloadEvent == type;
    });
  }

  void sendEvent(String type, Map<String, dynamic> payload) {
    sendRawEvent(type, payload);
  }

  void sendRawEvent(String type, dynamic payload) {
    if (_channel != null && _isConnected) {
      final message = jsonEncode({
        'type': type,
        'payload': payload,
      });
      _channel!.sink.add(message);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendRawEvent('ping', null);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _syncMissedEvents() async {
    try {
      final since = _lastEventTimestamp.toIso8601String();
      final response = await _dio.get('/ws/sync', queryParameters: {'since': since});
      if (response.statusCode == 200 && response.data['events'] != null) {
        final events = response.data['events'] as List;
        for (final event in events) {
          _eventController.add(event as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    _lastEventTimestamp = DateTime.now();
  }

  void _setConnectionState(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionController.add(connected);
      if (connected) {
        _syncMissedEvents();
      }
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    final delay = Duration(seconds: _calculateBackoff());
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  int _calculateBackoff() {
    const base = 1;
    const max = 60;
    final delay = base * (1 << (_reconnectAttempt - 1));
    return delay > max ? max : delay;
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
