import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../domain/repositories/notification_repository.dart';
import '../navigation/navigation_service.dart';
import '../../presentation/screens/notifications_screen.dart';
import '../../presentation/screens/wallet_screen.dart';
import '../../presentation/screens/vendor/vendor_order_detail_screen.dart';
import '../../presentation/screens/vendor/vendor_order_list_screen.dart';
import '../../presentation/screens/customer/customer_order_tracking_screen.dart';
import '../../presentation/screens/order_history_screen.dart';
import '../../presentation/screens/delivery/delivery_order_detail_screen.dart';
import '../../presentation/screens/delivery/delivery_offer_screen.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();
  LocalNotificationService.showNotification(message);
}

class FCMService {
  static FirebaseMessaging? _messaging;
  static NotificationRepository? _repository;

  static FirebaseMessaging get _instance => _messaging ??= FirebaseMessaging.instance;

  static Future<void> initialize(NotificationRepository repository) async {
    try {
      _repository = repository;
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _instance.onTokenRefresh.listen(_onTokenRefresh);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        LocalNotificationService.showNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        handleMessageAction(message);
      });

      try {
        RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage().timeout(const Duration(seconds: 3));
        if (initialMessage != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            handleMessageAction(initialMessage);
          });
        }
      } catch (_) {}

    } catch (e) {
      debugPrint("FCM init skipped: $e");
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _instance.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  static Future<void> registerDeviceToken() async {
    if (_repository == null) return;
    try {
      final token = await getToken();
      if (token != null) {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await _repository!.registerDeviceToken(token, platform);
        debugPrint('FCM token registered: $token');
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  static Future<void> unregisterDeviceToken() async {
    if (_repository == null) return;
    try {
      final token = await getToken();
      if (token != null) {
        await _repository!.unregisterDeviceToken(token);
        debugPrint('FCM token unregistered: $token');
      }
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  static Future<void> _onTokenRefresh(String token) async {
    debugPrint("FCM Token refreshed: $token");
    if (_repository == null) return;
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await _repository!.registerDeviceToken(token, platform);
      debugPrint('Refreshed FCM token registered');
    } catch (e) {
      debugPrint('Error registering refreshed FCM token: $e');
    }
  }

  static void handleMessageAction(RemoteMessage message) {
    final data = message.data;
    final action = data['action'] as String?;
    final entityId = data['entity_id'] as String?;

    debugPrint("Notification Action tapped: $action for entity $entityId");

    final nav = NavigationService.navigatorKey.currentState;
    if (nav == null) return;

    Widget screen;
    switch (action) {
      case 'OPEN_WALLET':
        screen = const WalletScreen();
        break;
      case 'OPEN_VENDOR_ORDER':
        if (entityId != null) {
          screen = VendorOrderDetailScreen(orderId: entityId);
        } else {
          screen = const VendorOrderListScreen(isPushed: true);
        }
        break;
      case 'OPEN_ORDER':
        if (entityId != null) {
          screen = CustomerOrderTrackingScreen(orderId: entityId);
        } else {
          screen = const OrderHistoryScreen();
        }
        break;
      case 'NEW_DELIVERY_AVAILABLE':
        if (entityId != null) {
          screen = DeliveryOfferScreen(orderId: entityId);
        } else {
          screen = const NotificationsScreen();
        }
        break;
      case 'OPEN_DELIVERY_ORDER':
        if (entityId != null) {
          screen = DeliveryOrderDetailScreen(orderId: entityId);
        } else {
          screen = const NotificationsScreen();
        }
        break;
      case 'OPEN_BOOKING':
      case 'OPEN_QUEUE':
      case 'OPEN_REVIEW':
      case 'OPEN_NOTIFICATIONS':
      default:
        screen = const NotificationsScreen();
        break;
    }

    nav.push(MaterialPageRoute(builder: (_) => screen));
  }
}
