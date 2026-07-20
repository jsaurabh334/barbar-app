import 'dart:async';
import '../../core/network/api_client.dart';
import '../../core/network/websocket_client.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../models/tracking/tracking_response.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;

  TrackingResponse? _cached;
  StreamController<TrackingResponse>? _controller;
  StreamSubscription<Map<String, dynamic>>? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _statusSub;
  StreamSubscription<Map<String, dynamic>>? _otpSub;
  StreamSubscription<bool>? _connectionSub;
  Timer? _fallbackTimer;
  String? _currentOrderId;
  bool _disposed = false;

  TrackingRepositoryImpl(this._apiClient, this._wsClient);

  @override
  Future<TrackingResponse> fetchTracking(String orderId) async {
    final response = await _apiClient.dio.get('/public/orders/$orderId/tracking');
    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>;
      _cached = TrackingResponse.fromJson(data);
      return _cached!;
    }
    throw Exception('Failed to fetch tracking');
  }

  @override
  Stream<TrackingResponse> trackingUpdates(String orderId) async* {
    _currentOrderId = orderId;
    _controller = StreamController<TrackingResponse>.broadcast();

    try {
      _cached = await fetchTracking(orderId);
      _controller!.add(_cached!);
    } catch (_) {}

    await _wsClient.connect();
    _wsClient.subscribeOrder(orderId);

    _locationSub = _wsClient.eventsByType('driver.location_updated').listen((event) {
      final payload = event['payload'] as Map<String, dynamic>? ?? event;
      _mergeLocationUpdate(payload);
    });

    _statusSub = _wsClient.eventsByType('order.status_changed').listen((event) {
      final payload = event['payload'] as Map<String, dynamic>? ?? event;
      _mergeStatusUpdate(payload);
    });

    _otpSub = _wsClient.eventsByType('delivery_otp_generated').listen((event) {
      final payload = event['payload'] as Map<String, dynamic>? ?? event;
      _mergeOtpUpdate(payload);
    });

    _connectionSub = _wsClient.connectionStatus.listen((connected) {
      if (!connected) {
        _startFallbackPolling();
      } else {
        _stopFallbackPolling();
        if (_currentOrderId != null) {
          _wsClient.subscribeOrder(_currentOrderId!);
        }
      }
    });

    yield* _controller!.stream;
  }

  void _mergeLocationUpdate(Map<String, dynamic> payload) {
    if (_cached == null || _controller == null || _controller!.isClosed) return;

    final driverData = payload['driver'] as Map<String, dynamic>?;
    final etaData = payload['eta'] as Map<String, dynamic>?;

    DriverInfo? updatedDriver;
    EtaInfo? updatedEta;

    if (driverData != null && _cached!.driver != null) {
      updatedDriver = _cached!.driver!.copyWith(
        latitude: (driverData['latitude'] as num?)?.toDouble(),
        longitude: (driverData['longitude'] as num?)?.toDouble(),
        bearing: (driverData['bearing'] as num?)?.toDouble(),
        speed: (driverData['speed'] as num?)?.toDouble(),
      );
    }

    if (etaData != null) {
      updatedEta = EtaInfo(
        minutes: (etaData['minutes'] as num?)?.toDouble() ?? 0,
        distanceKm: (etaData['distance_km'] as num?)?.toDouble() ?? 0,
      );
    }

    _cached = _cached!.copyWith(
      driver: updatedDriver,
      eta: updatedEta,
    );
    _controller!.add(_cached!);
  }

  void _mergeOtpUpdate(Map<String, dynamic> payload) {
    if (_cached == null || _controller == null || _controller!.isClosed) return;

    final otp = payload['delivery_otp'] as String?;
    final expiresIn = payload['expires_in_seconds'] as int?;

    _cached = _cached!.copyWith(
      deliveryOtp: otp,
      expiresInSeconds: expiresIn,
    );
    _controller!.add(_cached!);
  }

  void _mergeStatusUpdate(Map<String, dynamic> payload) {
    if (_cached == null || _controller == null || _controller!.isClosed) return;

    final newStatus = payload['status'] as String?;
    List<TimelineEntry>? timeline;

    if (payload['timeline'] != null) {
      timeline = (payload['timeline'] as List<dynamic>)
          .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _cached = _cached!.copyWith(
      status: newStatus,
      timeline: timeline,
    );
    _controller!.add(_cached!);
  }

  void _startFallbackPolling() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_currentOrderId == null || _disposed) return;
      try {
        final response = await _apiClient.dio.get('/public/orders/$_currentOrderId/tracking');
        if (response.statusCode == 200) {
          final data = response.data['data'] as Map<String, dynamic>;
          _cached = TrackingResponse.fromJson(data);
          if (_controller != null && !_controller!.isClosed) {
            _controller!.add(_cached!);
          }
        }
      } catch (_) {}
    });
  }

  void _stopFallbackPolling() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopFallbackPolling();
    _locationSub?.cancel();
    _statusSub?.cancel();
    _otpSub?.cancel();
    _connectionSub?.cancel();
    _controller?.close();
  }
}
