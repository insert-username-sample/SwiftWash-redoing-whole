import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background location service manager for driver app
class BackgroundLocationService {
  static const MethodChannel _platform =
      MethodChannel('com.example.swiftwash_driver/location_service');

  static const EventChannel _locationEventChannel =
      EventChannel('com.example.swiftwash_driver/location_updates');

  static StreamSubscription? _locationSubscription;
  static StreamController<Map<String, dynamic>>? _locationController;

  static String? _currentDriverId;
  static bool _isOnline = false;

  /// Initialize the background location service
  static Future<void> initialize(String driverId) async {
    _currentDriverId = driverId;

    try {
      // Load previous online status
      final prefs = await SharedPreferences.getInstance();
      _isOnline = prefs.getBool('driver_online_status') ?? false;

      // Set up location stream from native side
      _locationController = StreamController<Map<String, dynamic>>.broadcast();
      _locationSubscription = _locationEventChannel.receiveBroadcastStream().listen(
        _handleLocationUpdate,
        onError: (error) {
          debugPrint('Location stream error: $error');
        },
      );

      // Start service if driver was online
      if (_isOnline && _currentDriverId != null) {
        await startLocationService();
      }

    } catch (e) {
      debugPrint('Failed to initialize background location service: $e');
    }
  }

  /// Start the background location service
  static Future<bool> startLocationService() async {
    if (_currentDriverId == null) return false;

    try {
      _isOnline = true;

      // Save online status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driver_online_status', true);
      await prefs.setString('driver_id', _currentDriverId!);
      await prefs.setBool('was_online', true);

      // Start Android foreground service
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('startLocationService', {
          'driverId': _currentDriverId,
          'isOnline': true,
        });

        // Update Firestore status
        await _updateDriverStatus(true);

        debugPrint('Background location service started');
        return result == true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to start location service: $e');
      return false;
    }
  }

  /// Stop the background location service
  static Future<bool> stopLocationService() async {
    try {
      _isOnline = false;

      // Save offline status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driver_online_status', false);
      await prefs.setBool('was_online', false);

      // Stop Android foreground service
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('stopLocationService');

        // Update Firestore status
        await _updateDriverStatus(false);

        debugPrint('Background location service stopped');
        return result == true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to stop location service: $e');
      return false;
    }
  }

  /// Get current online status
  static bool get isOnline => _isOnline;

  /// Handle location updates from native side
  static void _handleLocationUpdate(dynamic data) {
    try {
      if (data is Map) {
        final locationData = Map<String, dynamic>.from(data);

        // Add additional metadata
        locationData['receivedAt'] = DateTime.now().millisecondsSinceEpoch;
        locationData['driverId'] = _currentDriverId;
        locationData['isOnline'] = _isOnline;

        // Broadcast to any listeners
        _locationController?.add(locationData);

        // Update Firestore location
        _updateDriverLocation(locationData);

        debugPrint('Location update received: ${locationData['latitude']}, ${locationData['longitude']}');
      }
    } catch (e) {
      debugPrint('Failed to handle location update: $e');
    }
  }

  /// Listen to location updates
  static Stream<Map<String, dynamic>> get locationStream {
    return _locationController?.stream ?? const Stream.empty();
  }

  /// Update driver status in Firestore
  static Future<void> _updateDriverStatus(bool isOnline) async {
    if (_currentDriverId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentDriverId)
          .update({
            'isOnline': isOnline,
            'lastStatusChange': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Failed to update driver status: $e');
    }
  }

  /// Update driver location in Firestore
  static Future<void> _updateDriverLocation(Map<String, dynamic> locationData) async {
    if (_currentDriverId == null || !_isOnline) return;

    try {
      // Update current location
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentDriverId)
          .update({
            'currentLocation': locationData,
            'lastLocationUpdate': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Failed to update driver location: $e');
    }
  }

  /// Check if location service is running
  static Future<bool> isServiceRunning() async {
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('isLocationServiceRunning');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to check service status: $e');
      return false;
    }
  }

  /// Request background location permission
  static Future<bool> requestBackgroundLocationPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('requestBackgroundLocationPermission');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to request background location permission: $e');
      return false;
    }
  }

  /// Request system alert window permission (for notifications)
  static Future<bool> requestSystemAlertPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('requestSystemAlertPermission');
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to request system alert permission: $e');
      return false;
    }
  }

  /// Get service statistics
  static Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final isRunning = await isServiceRunning();
      final prefs = await SharedPreferences.getInstance();

      return {
        'isServiceRunning': isRunning,
        'isDriverOnline': _isOnline,
        'driverId': _currentDriverId,
        'lastOnlineTime': prefs.getInt('lastOnlineTime'),
        'locationUpdatesCount': prefs.getInt('locationUpdatesCount') ?? 0,
      };
    } catch (e) {
      debugPrint('Failed to get service stats: $e');
      return {};
    }
  }

  /// Cleanup resources
  static Future<void> dispose() async {
    await _locationSubscription?.cancel();
    await _locationController?.close();
    await stopLocationService();
  }

  /// Update driver ID (for login/logout scenarios)
  static Future<void> updateDriverId(String driverId) async {
    _currentDriverId = driverId;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_id', driverId);
  }
}
