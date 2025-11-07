import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio ringing service for urgent notifications (orders/driver assignments)
class AudioRingService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Timer? _ringTimer;
  static bool _isRinging = false;
  static const String _ringtonePath = 'SwiftWash.mp3';
  static const Duration _ringDuration = Duration(seconds: 30); // Ring for 30 seconds
  static const int _maxRings = 3; // Maximum ring cycles

  static const String _settingsKey = 'audio_ring_settings';
  static bool _isEnabled = true;
  static double _volume = 1.0;

  /// Initialize audio service
  static Future<void> initialize() async {
    try {
      // Initialize audio player
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_volume);

      // Initialize notifications for background handling
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);

      // Load settings
      await _loadSettings();

      debugPrint('AudioRingService initialized');
    } catch (e) {
      debugPrint('Failed to initialize AudioRingService: $e');
    }
  }

  /// Ring for order notification (Operator app)
  static Future<void> ringForOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
    Function? onTimeout,
  }) async {
    if (!_isEnabled || _isRinging) return;

    await _startRinging(
      title: '🚨 NEW ORDER ALERT!',
      body: 'Order #$orderId - ${orderData['serviceType'] ?? 'Service'}',
      soundSource: _ringtonePath,
      onTimeout: onTimeout,
    );
  }

  /// Ring for driver assignment (Driver app)
  static Future<void> ringForAssignment({
    required String orderId,
    required Map<String, dynamic> orderData,
    required Function(bool accepted) onResponse,
  }) async {
    if (!_isEnabled || _isRinging) return;

    await _startRinging(
      title: '🚗 DRIVER ASSIGNMENT!',
      body: 'New order assigned - ${orderData['pickupAddress'] ?? 'Pickup location'}',
      soundSource: _ringtonePath,
      showAcceptDenyButtons: true,
      onAccept: () => onResponse(true),
      onDeny: () => onResponse(false),
    );
  }

  /// Start ringing with custom parameters
  static Future<void> _startRinging({
    required String title,
    required String body,
    required String soundSource,
    bool showAcceptDenyButtons = false,
    Function? onTimeout,
    Function? onAccept,
    Function? onDeny,
  }) async {
    try {
      _isRinging = true;

      // Show high-priority notification
      await _showRingingNotification(
        title: title,
        body: body,
        showAcceptDenyButtons: showAcceptDenyButtons,
        onAccept: onAccept,
        onDeny: onDeny,
      );

      // Start audio playback
      await _playRingtone(soundSource);

      // Set timeout
      _ringTimer = Timer(_ringDuration, () async {
        await _stopRinging();
        onTimeout?.call();

        // If assignment was denied or timed out, trigger reassignment
        if (showAcceptDenyButtons && onDeny != null) {
          onDeny();
        }
      });

    } catch (e) {
      debugPrint('Failed to start ringing: $e');
      _isRinging = false;
    }
  }

  /// Stop ringing
  static Future<void> stopRinging() async {
    await _stopRinging();
  }

  static Future<void> _stopRinging() async {
    try {
      _ringTimer?.cancel();
      _ringTimer = null;

      await _audioPlayer.stop();
      await _notifications.cancel(999); // Cancel ringing notification

      _isRinging = false;

      debugPrint('Ringing stopped');
    } catch (e) {
      debugPrint('Failed to stop ringing: $e');
    }
  }

  /// Play ringtone
  static Future<void> _playRingtone(String soundPath) async {
    try {
      // Use AssetSource for the MP3 file
      await _audioPlayer.play(AssetSource(soundPath));
      await _audioPlayer.setVolume(_volume);

      // Repeat for multiple rings if needed
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    } catch (e) {
      debugPrint('Failed to play ringtone: $e');

      // Fallback to system sound if custom ringtone fails
      await _audioPlayer.play(AssetSource('audio/notification.mp3'));
    }
  }

  /// Show ringing notification with accept/deny actions
  static Future<void> _showRingingNotification({
    required String title,
    required String body,
    bool showAcceptDenyButtons = false,
    Function? onAccept,
    Function? onDeny,
  }) async {
    try {
      // For Android, create full-screen intent that can wake device and launch app
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'urgent_alerts',
        'Urgent Alerts',
        channelDescription: 'Critical notifications requiring immediate attention',
        importance: Importance.max,
        priority: Priority.max,
        sound: const RawResourceAndroidNotificationSound('notification'),
        ongoing: true, // Cannot be dismissed
        autoCancel: false,
        fullScreenIntent: true, // Shows on lock screen, wakes device
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]), // Strong vibration
        ledColor: const Color(0xFFFF0000),
        ledOnMs: 1000,
        ledOffMs: 500,
        actions: showAcceptDenyButtons ? [
          const AndroidNotificationAction(
            'ACCEPT_ORDER',
            'ACCEPT',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            contextual: true,
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'DENY_ORDER',
            'DENY',
            icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            contextual: true,
            showsUserInterface: true,
          ),
        ] : null,
        additionalFlags: Int32List.fromList([
          0x00000020, // FLAG_SHOW_LIGHTS
          0x00000010, // FLAG_ONGOING_EVENT
          0x00000080, // FLAG_INSISTENT (repeat sound until dismissed)
        ]),
      );

      DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.mp3',
        interruptionLevel: InterruptionLevel.critical, // Highest priority
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show high-priority notification that can launch app from background
      await _notifications.show(
        999, // Unique ID for ringing notifications
        title,
        body,
        details,
        payload: showAcceptDenyButtons ? 'assignment_alert' : 'order_alert',
      );

    } catch (e) {
      debugPrint('Failed to show ringing notification: $e');
    }
  }

  /// Check and request system alert window permission (for Android)
  static Future<bool> checkSystemAlertPermission() async {
    try {
      // This would be implemented with platform channels to check
      // Settings.canDrawOverlays() permission
      // For now, return true and handle on Android side
      return true;
    } catch (e) {
      debugPrint('Failed to check system alert permission: $e');
      return false;
    }
  }

  /// Request system alert window permission
  static Future<void> requestSystemAlertPermission() async {
    try {
      // Platform channel call to request permission
      // Intent to settings page for draw over apps permission
      debugPrint('System alert permission requested');
    } catch (e) {
      debugPrint('Failed to request system alert permission: $e');
    }
  }

  /// Handle notification action taps (Accept/Deny)
  static Future<void> handleNotificationAction(String action) async {
    switch (action) {
      case 'ACCEPT_ORDER':
        await _stopRinging();
        // This will be handled by the callback
        break;
      case 'DENY_ORDER':
        await _stopRinging();
        // This will be handled by the callback
        break;
    }
  }

  /// Settings management
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _saveSettings();
  }

  static Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    await _saveSettings();
  }

  static bool get isEnabled => _isEnabled;
  static double get volume => _volume;
  static bool get isRinging => _isRinging;

  static Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString(_settingsKey);

      if (settings != null) {
        final data = Map<String, dynamic>.from(
          settings.split(',').fold<Map<String, String>>({}, (map, pair) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              map[parts[0]] = parts[1];
            }
            return map;
          })
        );

        _isEnabled = data['enabled'] == 'true';
        _volume = double.tryParse(data['volume'] ?? '1.0') ?? 1.0;
      }
    } catch (e) {
      debugPrint('Failed to load audio settings: $e');
    }
  }

  static Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = 'enabled:$_isEnabled,volume:$_volume';
      await prefs.setString(_settingsKey, settings);
    } catch (e) {
      debugPrint('Failed to save audio settings: $e');
    }
  }

  /// Cleanup resources - MUST be called when app closes
  static Future<void> disposeAll() async {
    try {
      // Cancel any pending timers
      _ringTimer?.cancel();
      _ringTimer = null;

      // Stop audio and notifications
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
      await _notifications.cancelAll();

      // Reset static state
      _isRinging = false;
      _isEnabled = false;
      _volume = 1.0;

      debugPrint('AudioRingService: All resources disposed');
    } catch (e) {
      debugPrint('Error disposing AudioRingService: $e');
    }
  }

  /// Test ringtone with proper cleanup
  static Future<void> testRingtone() async {
    if (_isRinging) return;

    try {
      await _playRingtone(_ringtonePath);

      // Stop after 3 seconds with proper cleanup
      Timer(const Duration(seconds: 3), () async {
        try {
          await _audioPlayer.stop();
        } catch (e) {
          debugPrint('Error stopping test ringtone: $e');
        }
      });
    } catch (e) {
      debugPrint('Error testing ringtone: $e');
    }
  }

  /// Reset service state (for app lifecycle management)
  static void reset() {
    _isRinging = false;
    _ringTimer?.cancel();
    _ringTimer = null;
  }

  /// Emergency cleanup - force stop everything
  static Future<void> forceCleanup() async {
    try {
      // Cancel timers
      _ringTimer?.cancel();
      _ringTimer = null;

      // Stop everything immediately
      await Future.wait([
        _audioPlayer.stop(),
        _notifications.cancelAll(),
      ]);

      _isRinging = false;

      debugPrint('AudioRingService: Emergency cleanup completed');
    } catch (e) {
      debugPrint('Error in force cleanup: $e');
    }
  }
}
