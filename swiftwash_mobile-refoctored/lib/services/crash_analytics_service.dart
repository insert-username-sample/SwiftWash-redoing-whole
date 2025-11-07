import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise-grade crash reporting and analytics service
class CrashAnalyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static bool _isInitialized = false;

  /// Initialize crash reporting and analytics
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = _crashlytics.recordFlutterFatalError;

      // Handle Flutter framework errors
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      // Set user properties for better analytics
      await _setUserProperties();

      _isInitialized = true;
      debugPrint('CrashAnalyticsService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize CrashAnalyticsService: $e');
    }
  }

  /// Set user properties for analytics
  static Future<void> _setUserProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userPhone = prefs.getString('userPhone');

      if (userId != null) {
        await _analytics.setUserId(id: userId);
        await _crashlytics.setUserIdentifier(userId);
      }

      if (userPhone != null) {
        await _analytics.setUserProperty(name: 'phone', value: userPhone);
        await _crashlytics.setCustomKey('user_phone', userPhone);
      }

      // Set app version
      await _crashlytics.setCustomKey('app_version', '1.0.0');
      await _analytics.setUserProperty(name: 'app_version', '1.0.0');

    } catch (e) {
      debugPrint('Failed to set user properties: $e');
    }
  }

  /// Update user information when user logs in
  static Future<void> setUserInfo({
    required String userId,
    String? phone,
    String? name,
    String? email,
  }) async {
    try {
      // Analytics
      await _analytics.setUserId(id: userId);

      if (phone != null) {
        await _analytics.setUserProperty(name: 'phone', value: phone);
      }
      if (name != null) {
        await _analytics.setUserProperty(name: 'name', value: name);
      }
      if (email != null) {
        await _analytics.setUserProperty(name: 'email', value: email);
      }

      // Crashlytics
      await _crashlytics.setUserIdentifier(userId);

      if (phone != null) {
        await _crashlytics.setCustomKey('user_phone', phone);
      }
      if (name != null) {
        await _crashlytics.setCustomKey('user_name', name);
      }
      if (email != null) {
        await _crashlytics.setCustomKey('user_email', email);
      }

      // Store in preferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      if (phone != null) await prefs.setString('userPhone', phone);
      if (name != null) await prefs.setString('userName', name);

    } catch (e) {
      debugPrint('Failed to set user info: $e');
    }
  }

  /// Clear user information on logout
  static Future<void> clearUserInfo() async {
    try {
      await _analytics.setUserId(id: null);
      await _crashlytics.setUserIdentifier('');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userPhone');
      await prefs.remove('userName');

    } catch (e) {
      debugPrint('Failed to clear user info: $e');
    }
  }

  /// Log custom events for analytics
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Failed to log event: $e');
    }
  }

  /// Log screen views
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Log order events
  static Future<void> logOrderEvent({
    required String eventType,
    required String orderId,
    double? amount,
    String? serviceType,
    String? paymentMethod,
  }) async {
    final parameters = <String, dynamic>{
      'order_id': orderId,
      'event_type': eventType,
    };

    if (amount != null) parameters['value'] = amount;
    if (serviceType != null) parameters['service_type'] = serviceType;
    if (paymentMethod != null) parameters['payment_method'] = paymentMethod;

    await logEvent(name: 'order_${eventType}', parameters: parameters);
  }

  /// Log user journey events
  static Future<void> logUserJourney({
    required String step,
    String? fromScreen,
    String? toScreen,
    Map<String, dynamic>? additionalData,
  }) async {
    final parameters = <String, dynamic>{
      'step': step,
      'journey_type': 'user_flow',
    };

    if (fromScreen != null) parameters['from_screen'] = fromScreen;
    if (toScreen != null) parameters['to_screen'] = toScreen;
    if (additionalData != null) parameters.addAll(additionalData);

    await logEvent(name: 'user_journey', parameters: parameters);
  }

  /// Log performance metrics
  static Future<void> logPerformance({
    required String metric,
    required int value,
    String? unit = 'ms',
    Map<String, dynamic>? additionalData,
  }) async {
    final parameters = <String, dynamic>{
      'metric': metric,
      'value': value,
      'unit': unit,
    };

    if (additionalData != null) parameters.addAll(additionalData);

    await logEvent(name: 'performance_metric', parameters: parameters);
  }

  /// Log errors (non-fatal)
  static Future<void> logError({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log to Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: context,
        information: additionalData?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      );

      // Log to Analytics
      final parameters = <String, dynamic>{
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'has_stack_trace': stackTrace != null,
      };

      if (context != null) parameters['context'] = context;
      if (additionalData != null) parameters.addAll(additionalData);

      await logEvent(name: 'error_occurred', parameters: parameters);

    } catch (e) {
      debugPrint('Failed to log error: $e');
    }
  }

  /// Log app lifecycle events
  static Future<void> logAppLifecycle({
    required String event,
    Map<String, dynamic>? additionalData,
  }) async {
    final parameters = <String, dynamic>{
      'lifecycle_event': event,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (additionalData != null) parameters.addAll(additionalData);

    await logEvent(name: 'app_lifecycle', parameters: parameters);
  }

  /// Enable/disable analytics collection
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Failed to set analytics enabled: $e');
    }
  }

  /// Enable/disable crash reporting
  static Future<void> setCrashReportingEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Failed to set crash reporting enabled: $e');
    }
  }

  /// Get analytics instance for advanced usage
  static FirebaseAnalytics get analytics => _analytics;

  /// Get crashlytics instance for advanced usage
  static FirebaseCrashlytics get crashlytics => _crashlytics;
}
