import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/driver_location_model.dart';

class LocationTrackingService {
  final _supabase = SupabaseConfig.client;
  StreamSubscription<Position>? _locationSubscription;
  RealtimeChannel? _realtimeChannel;

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<void> startTrackingDriver({
    required String driverId,
    String? orderId,
    required Function(Position) onLocationUpdate,
  }) async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      await stopTracking();

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) async {
        onLocationUpdate(position);

        await _supabase.from('driver_locations').insert({
          'driver_id': driverId,
          'order_id': orderId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      debugPrint('Error starting driver tracking: $e');
      rethrow;
    }
  }

  Stream<List<DriverLocationModel>> subscribeToDriverLocation({
    required String driverId,
    String? orderId,
  }) {
    try {
      final query = _supabase
          .from('driver_locations')
          .stream(primaryKey: ['id'])
          .eq('driver_id', driverId)
          .order('timestamp', ascending: false)
          .limit(1);

      return query.map((data) {
        return data
            .map((json) => DriverLocationModel.fromJson(json))
            .toList();
      });
    } catch (e) {
      debugPrint('Error subscribing to driver location: $e');
      return Stream.value([]);
    }
  }

  Future<DriverLocationModel?> getLatestDriverLocation({
    required String driverId,
    String? orderId,
  }) async {
    try {
      var query = _supabase
          .from('driver_locations')
          .select()
          .eq('driver_id', driverId)
          .order('timestamp', ascending: false)
          .limit(1);

      if (orderId != null) {
        query = query.eq('order_id', orderId);
      }

      final response = await query.maybeSingle();

      if (response == null) return null;

      return DriverLocationModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting latest driver location: $e');
      return null;
    }
  }

  Future<List<DriverLocationModel>> getDriverLocationHistory({
    required String driverId,
    String? orderId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      var query = _supabase
          .from('driver_locations')
          .select()
          .eq('driver_id', driverId)
          .order('timestamp', ascending: false);

      if (orderId != null) {
        query = query.eq('order_id', orderId);
      }

      if (startTime != null) {
        query = query.gte('timestamp', startTime.toIso8601String());
      }

      if (endTime != null) {
        query = query.lte('timestamp', endTime.toIso8601String());
      }

      final response = await query;

      return (response as List)
          .map((json) => DriverLocationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting driver location history: $e');
      return [];
    }
  }

  Future<void> stopTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  void dispose() {
    stopTracking();
  }

  Future<double> getDistanceToDriver({
    required double userLat,
    required double userLon,
    required String driverId,
  }) async {
    try {
      final driverLocation = await getLatestDriverLocation(driverId: driverId);
      if (driverLocation == null) return 0.0;

      final response = await _supabase.rpc('calculate_distance', params: {
        'lat1': userLat,
        'lon1': userLon,
        'lat2': driverLocation.latitude,
        'lon2': driverLocation.longitude,
      });

      return (response as num).toDouble();
    } catch (e) {
      debugPrint('Error getting distance to driver: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getEstimatedArrival({
    required double userLat,
    required double userLon,
    required String driverId,
  }) async {
    try {
      final distance = await getDistanceToDriver(
        userLat: userLat,
        userLon: userLon,
        driverId: driverId,
      );

      final driverLocation = await getLatestDriverLocation(driverId: driverId);
      if (driverLocation == null) {
        return {'distance': 0.0, 'eta_minutes': 0};
      }

      final averageSpeed = driverLocation.speed ?? 10.0;
      final speedKmh = (averageSpeed * 3.6).clamp(5.0, 60.0);
      final etaMinutes = ((distance / speedKmh) * 60).ceil();

      return {
        'distance': distance,
        'eta_minutes': etaMinutes,
        'speed_kmh': speedKmh,
      };
    } catch (e) {
      debugPrint('Error getting estimated arrival: $e');
      return {'distance': 0.0, 'eta_minutes': 0};
    }
  }
}
