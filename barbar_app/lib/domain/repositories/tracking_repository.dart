import 'dart:async';
import '../../data/models/tracking/tracking_response.dart';

abstract class TrackingRepository {
  Future<TrackingResponse> fetchTracking(String orderId);
  Stream<TrackingResponse> trackingUpdates(String orderId);
  void dispose();
}
