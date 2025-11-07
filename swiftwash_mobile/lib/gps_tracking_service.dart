import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

// Tracking Phases - Move enum outside class
enum TrackingPhase {
  pickup,           // Driver to customer location
  toFacility,       // Customer to facility
  toDelivery,       // Facility to customer
  completed         // Tracking completed
}

// GPS Tracking Service for Real-time Driver Location Tracking
class GPSTrackingService {
  static final GPSTrackingService _instance = GPSTrackingService._internal();
  factory GPSTrackingService() => _instance;
  GPSTrackingService._internal();

  StreamSubscription? _driverSubscription;
  StreamSubscription? _routeSubscription;
  LatLng? _currentDriverLocation;
  List<LatLng> _currentRoute = [];

  // Get real-time driver location stream
  Stream<LatLng> getDriverLocation(String driverId) {
    final StreamController<LatLng> controller = StreamController<LatLng>();

    _driverSubscription?.cancel();
    _driverSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final location = data['currentLocation'] as GeoPoint?;
            if (location != null) {
              _currentDriverLocation = LatLng(location.latitude, location.longitude);
              controller.add(_currentDriverLocation!);
            }
          }
        });

    return controller.stream;
  }

  // Get pickup phase tracking - Driver to customer
  Stream<TrackingData> getPickupPhaseTracking(String orderId, String driverId) async* {
    final StreamController<TrackingData> controller = StreamController<TrackingData>();

    try {
      // Get customer location
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!orderDoc.exists || orderDoc.data() == null) {
        controller.close();
        return;
      }

      final orderData = orderDoc.data()!;
      final customerAddress = orderData['address'] as Map<String, dynamic>?;
      if (customerAddress == null) {
        controller.close();
        return;
      }

      // For now, use simulated coordinates - replace with actual geocoding
      final customerLocation = const LatLng(12.9716, 77.5946); // Bangalore coordinates

      // Stream driver location
      final driverLocationStream = getDriverLocation(driverId);

      await for (final driverLocation in driverLocationStream) {
        final distance = _calculateDistance(driverLocation, customerLocation);
        final estimatedArrival = _calculateEstimatedArrival(distance);

        // Get or simulate route
        final route = await _getOrCalculateRoute(orderId, TrackingPhase.pickup, driverLocation, customerLocation);

        final trackingData = TrackingData(
          driverLocation: driverLocation,
          destinationLocation: customerLocation,
          routePoints: route,
          distance: distance,
          estimatedArrival: estimatedArrival,
          phase: TrackingPhase.pickup,
          status: 'Driver en route to pickup',
        );

        controller.add(trackingData);
      }
    } catch (e) {
      controller.addError(e);
    }
  }

  // Get transit phase tracking - Customer to facility
  Stream<TrackingData> getTransitPhaseTracking(String orderId, String driverId) async* {
    final StreamController<TrackingData> controller = StreamController<TrackingData>();

    try {
      // Facility location - replace with actual facility coordinates
      const facilityLocation = LatLng(12.9770, 77.5960); // Facility coordinates

      // Stream driver location
      final driverLocationStream = getDriverLocation(driverId);

      await for (final driverLocation in driverLocationStream) {
        final distance = _calculateDistance(driverLocation, facilityLocation);
        final estimatedArrival = _calculateEstimatedArrival(distance);

        // Get or simulate route
        final route = await _getOrCalculateRoute(orderId, TrackingPhase.toFacility, driverLocation, facilityLocation);

        final trackingData = TrackingData(
          driverLocation: driverLocation,
          destinationLocation: facilityLocation,
          routePoints: route,
          distance: distance,
          estimatedArrival: estimatedArrival,
          phase: TrackingPhase.toFacility,
          status: 'Transit to facility',
        );

        controller.add(trackingData);
      }
    } catch (e) {
      controller.addError(e);
    }
  }

  // Get delivery phase tracking - Facility to customer
  Stream<TrackingData> getDeliveryPhaseTracking(String orderId, String driverId) async* {
    final StreamController<TrackingData> controller = StreamController<TrackingData>();

    try {
      // Get customer location (same as pickup)
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!orderDoc.exists || orderDoc.data() == null) {
        controller.close();
        return;
      }

      final orderData = orderDoc.data()!;
      final customerAddress = orderData['address'] as Map<String, dynamic>?;
      if (customerAddress == null) {
        controller.close();
        return;
      }

      const customerLocation = LatLng(12.9716, 77.5946); // Customer coordinates
      final driverLocationStream = getDriverLocation(driverId);

      await for (final driverLocation in driverLocationStream) {
        final distance = _calculateDistance(driverLocation, customerLocation);
        final estimatedArrival = _calculateEstimatedArrival(distance);

        final route = await _getOrCalculateRoute(orderId, TrackingPhase.toDelivery, driverLocation, customerLocation);

        final trackingData = TrackingData(
          driverLocation: driverLocation,
          destinationLocation: customerLocation,
          routePoints: route,
          distance: distance,
          estimatedArrival: estimatedArrival,
          phase: TrackingPhase.toDelivery,
          status: 'Out for delivery',
        );

        controller.add(trackingData);
      }
    } catch (e) {
      controller.addError(e);
    }
  }

  // Get stored route or calculate new one
  Future<List<LatLng>> _getOrCalculateRoute(String orderId, TrackingPhase phase, LatLng start, LatLng end) async {
    // Try to get existing route from Firebase
    try {
      final routeDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('routes')
          .doc(phase.toString())
          .get();

      if (routeDoc.exists && routeDoc.data() != null) {
        final data = routeDoc.data()!;
        final points = data['points'] as List<dynamic>;
        return points.map<LatLng>((point) =>
          LatLng(point['latitude'], point['longitude'])).toList();
      }
    } catch (e) {
      // Route not found, continue to generate new one
    }

    // Generate new route (simplified for now)
    return _generateRoutePoints(start, end);
  }

  // Generate route points for visualization
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final List<LatLng> points = [];
    const int steps = 20;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * progress;
      final lng = start.longitude + (end.longitude - start.longitude) * progress;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLon = _degreesToRadians(end.longitude - start.longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) * math.cos(_degreesToRadians(end.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(1 - a), a);
    return earthRadius * c;
  }

  // Estimate arrival time (assuming 30 km/h average speed)
  String _calculateEstimatedArrival(double distanceInKm) {
    const double averageSpeed = 30.0; // km/h
    final estimatedMinutes = (distanceInKm / averageSpeed) * 60;

    if (estimatedMinutes < 2) {
      return 'Arriving soon';
    } else if (estimatedMinutes < 60) {
      return '${estimatedMinutes.round()} mins';
    } else {
      final hours = (estimatedMinutes / 60).floor();
      final mins = (estimatedMinutes % 60).round();
      return '${hours}h ${mins}m';
    }
  }

  // Utility function for degrees to radians
  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
  static const double pi = 3.141592653589793;

  // Cleanup resources
  void dispose() {
    _driverSubscription?.cancel();
    _routeSubscription?.cancel();
  }
}

// Tracking Data Model
class TrackingData {
  final LatLng driverLocation;
  final LatLng destinationLocation;
  final List<LatLng> routePoints;
  final double distance;
  final String estimatedArrival;
  final TrackingPhase phase;
  final String status;

  TrackingData({
    required this.driverLocation,
    required this.destinationLocation,
    required this.routePoints,
    required this.distance,
    required this.estimatedArrival,
    required this.phase,
    required this.status,
  });

  // Generate markers for map display
  Set<Marker> getMarkers() {
    return {
      Marker(
        markerId: const MarkerId('driver'),
        position: driverLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Driver'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: _getDestinationTitle()),
      ),
    };
  }

  // Generate polyline for route display
  Set<Polyline> getPolyline() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  String _getDestinationTitle() {
    switch (phase) {
      case TrackingPhase.pickup:
        return 'Pickup Location';
      case TrackingPhase.toFacility:
        return 'Facility';
      case TrackingPhase.toDelivery:
        return 'Delivery Location';
      case TrackingPhase.completed:
        return 'Completed';
      default:
        return 'Destination';
    }
  }
}

// Extension methods for LatLng calculations
extension LatLngExtension on double {
  double get cos => Math.cos(this);
  double get sin => Math.sin(this);
  double sqrt() => Math.sqrt(this);
  double atan2(double other) => Math.atan2(this, other);
}

// Math utilities
class Math {
  static double cos(double radians) => math.cos(radians);
  static double sin(double radians) => math.sin(radians);
  static double atan2(double y, double x) => math.atan2(y, x);
  static double sqrt(double value) => math.sqrt(value);
}

double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
