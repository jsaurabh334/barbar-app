import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/constants.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

class WebSocketClient {
  final AuthLocalDataSource _localDataSource;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;

  WebSocketClient({AuthLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? AuthLocalDataSource();

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
      
      // We must catch errors on the ready future to prevent unhandled exceptions
      _channel!.ready.catchError((error) {
        _setConnectionState(false);
        _scheduleReconnect();
      });

      _setConnectionState(true);

      _channel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(message as String);
            _eventController.add(decoded);
          } catch (_) {
            // Suppress invalid JSON messages
          }
        },
        onError: (err) {
          _setConnectionState(false);
          _scheduleReconnect();
        },
        onDone: () {
          _setConnectionState(false);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _setConnectionState(false);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _setConnectionState(false);
  }

  void sendEvent(String type, Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      final message = jsonEncode({
        'type': type,
        'payload': payload,
      });
      _channel!.sink.add(message);
    }
  }

  void _setConnectionState(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionController.add(connected);
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
