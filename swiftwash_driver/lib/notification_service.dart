import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:swiftwash_driver/services/audio_ring_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize Firebase Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initialize AudioRingService
    await AudioRingService.initialize();

    // Initialize local notifications for additional functionality
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings,
        onDidReceiveNotificationResponse: _onNotificationTapped);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is launched from terminated state
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Handle foreground messages - shows notification and rings if urgent
  void _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }

    // Check if this is an urgent driver assignment notification
    if (_isDriverAssignmentMessage(message)) {
      await _handleDriverAssignmentNotification(message);
    } else {
      // Show regular notification
      await _showRegularNotification(message);
    }
  }

  /// Handle background message opened
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened from background: ${message.data}');

    // Handle navigation based on message type
    if (message.data['type'] == 'driver_assignment') {
      // Navigate to assignment screen if needed
      // This would typically trigger navigation
    }
  }

  /// Handle background message
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message: ${message.data}');

    // For urgent driver assignment notifications, trigger ringing even in background
    if (_isDriverAssignmentMessage(message)) {
      // Extract assignment data from message
      final orderData = message.data;
      final orderId = orderData['orderId'] ?? 'unknown';

      await AudioRingService.initialize();

      await AudioRingService.ringForAssignment(
        orderId: orderId,
        orderData: orderData,
        onResponse: (accepted) {
          print('Driver responded to assignment: $accepted for order: $orderId');
          // Here you would typically call an API to accept/decline the assignment
        },
      );
    }
  }

  /// Check if message is for driver assignment
  static bool _isDriverAssignmentMessage(RemoteMessage message) {
    return message.data['type'] == 'driver_assignment' ||
           message.data['urgent'] == 'true';
  }

  /// Handle driver assignment notification with ringing and actions
  Future<void> _handleDriverAssignmentNotification(RemoteMessage message) async {
    final orderData = message.data;
    final orderId = orderData['orderId'] ?? 'unknown';

    await AudioRingService.ringForAssignment(
      orderId: orderId,
      orderData: orderData,
      onResponse: (accepted) async {
        print('Driver responded: ${accepted ? "ACCEPTED" : "DECLINED"} for order: $orderId');

        try {
          // Show response notification
          await _showAssignmentResponseNotification(accepted, orderId);

          // Here you would call your assignment API
          // await driverService.respondToAssignment(orderId, accepted);

        } catch (e) {
          print('Error responding to assignment: $e');
        }
      },
    );
  }

  /// Show assignment response notification
  Future<void> _showAssignmentResponseNotification(bool accepted, String orderId) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'assignment_response',
      'Assignment Responses',
      channelDescription: 'Notifications for assignment accept/decline responses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound('notification'),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = accepted ? '✅ Assignment Accepted' : '❌ Assignment Declined';
    final body = accepted
        ? 'You accepted order #$orderId'
        : 'You declined order #$orderId';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Show regular notification (non-urgent)
  Future<void> _showRegularNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'Regular app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound('notification'),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    // Handle actions based on payload
    if (response.payload != null) {
      final data = _parsePayload(response.payload!);
      if (data['type'] == 'driver_assignment') {
        // Navigate to assignment screen
        // This would typically trigger navigation
      }
    }

    // Handle action responses (if any)
    if (response.actionId != null) {
      AudioRingService.handleNotificationAction(response.actionId!);
    }
  }

  /// Parse notification payload
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      return Map<String, dynamic>.from(
        payload.split(',').fold<Map<String, String>>({}, (map, pair) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            map[parts[0].trim()] = parts[1].trim();
          }
          return map;
        })
      );
    } catch (e) {
      return {};
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      sound: RawResourceAndroidNotificationSound('notification'),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      'Test Notification',
      'This is a test notification from SwiftWash Driver',
      details,
    );
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await AudioRingService.disposeAll();
  }
}
