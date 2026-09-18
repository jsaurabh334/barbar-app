import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'fcm_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local notification tapped: ${response.payload}');
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final message = RemoteMessage(data: data.cast<String, String>());
            FCMService.handleMessageAction(message);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );
  }

  static void showNotification(RemoteMessage message, {int? badgeCount}) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      int? finalBadge = badgeCount;
      if (finalBadge == null) {
        if (message.data['badge'] != null) {
          finalBadge = int.tryParse(message.data['badge'].toString());
        } else if (message.notification?.apple?.badge != null) {
          finalBadge = int.tryParse(message.notification!.apple!.badge!);
        }
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        number: finalBadge,
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: finalBadge,
      );

      final NotificationDetails notificationDetails =
          NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: message.notification?.title ?? message.data['title'],
        body: message.notification?.body ?? message.data['body'],
        notificationDetails: notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint("Error showing local notification: $e");
    }
  }
}
