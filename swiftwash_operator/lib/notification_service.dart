import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:swiftwash_operator/services/audio_ring_service.dart';

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

    // Check if this is an urgent new order notification
    if (_isNewOrderMessage(message)) {
      await _handleNewOrderNotification(message);
    } else {
      // Show regular notification
      await _showRegularNotification(message);
    }
  }

  /// Handle background message opened
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened from background: ${message.data}');

    // Handle navigation based on message type
    if (message.data['type'] == 'new_order') {
      // Navigate to order details if needed
      // This would typically trigger navigation
    }
  }

  /// Handle background message
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message: ${message.data}');

    // For urgent notifications, trigger ringing even in background
    if (_isNewOrderMessage(message)) {
      // Extract order data from message
      final orderData = message.data;
      final orderId = orderData['orderId'] ?? 'unknown';

      await AudioRingService.initialize();

      await AudioRingService.ringForOrder(
        orderId: orderId,
        orderData: orderData,
        onTimeout: () {
          print('Order ring timed out: $orderId');
        },
      );
    }
  }

  /// Check if message is for new order
  static bool _isNewOrderMessage(RemoteMessage message) {
    return message.data['type'] == 'new_order' ||
           message.data['urgent'] == 'true';
  }

  /// Handle new order notification with ringing
  Future<void> _handleNewOrderNotification(RemoteMessage message) async {
    final orderData = message.data;
    final orderId = orderData['orderId'] ?? 'unknown';

    await AudioRingService.ringForOrder(
      orderId: orderId,
      orderData: orderData,
      onTimeout: () {
        print('Order notification timeout for: $orderId');
      },
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
      if (data['type'] == 'new_order') {
        // Navigate to order details screen
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
      'This is a test notification from SwiftWash Operator',
      details,
    );
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await AudioRingService.disposeAll();
  }
}
