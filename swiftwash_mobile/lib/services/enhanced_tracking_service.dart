import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:swiftwash_mobile/services/custom_marker_service.dart';
import 'package:swiftwash_mobile/models/order_status_model.dart';

class EnhancedTrackingService {
  static final EnhancedTrackingService _instance = EnhancedTrackingService._internal();
  factory EnhancedTrackingService() => _instance;
  EnhancedTrackingService._internal();

  final CustomMarkerService _markerService = CustomMarkerService();
  StreamSubscription? _driverSubscription;
  StreamSubscription? _orderSubscription;

  // Google Directions API key (replace with your actual key)
  static const String _directionsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Initialize the service
  Future<void> initialize() async {
    await _markerService.initializeMarkers();
  }

  // Get comprehensive tracking data for an order
  Stream<TrackingData> getOrderTracking(String orderId) async* {
    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists || orderDoc.data() == null) {
      throw Exception('Order not found');
    }

    final orderData = orderDoc.data()!;
    final driverId = orderData['driverId'] as String?;
    final status = orderData['status'] as String?;

    if (driverId == null) {
      throw Exception('No driver assigned');
    }

    // Get customer location from address
    final address = orderData['address'] as Map<String, dynamic>?;
    final customerLocation = await _getLocationFromAddress(address);

    // Get facility location (you can store this in Firebase or use a constant)
    const facilityLocation = LatLng(12.9770, 77.5960); // Replace with actual facility coordinates

    // Determine tracking phase based on order status
    TrackingPhase phase = _getTrackingPhase(status);

    // Stream driver location and calculate route
    final driverLocationStream = _getDriverLocationStream(driverId);

    await for (final driverLocation in driverLocationStream) {
      LatLng destination;
      String routeDescription;

      switch (phase) {
        case TrackingPhase.pickup:
          destination = customerLocation;
          routeDescription = 'Driver en route to pickup location';
          break;
        case TrackingPhase.toFacility:
          destination = facilityLocation;
          routeDescription = 'Driver en route to facility';
          break;
        case TrackingPhase.toDelivery:
          destination = customerLocation;
          routeDescription = 'Driver en route for delivery';
          break;
        case TrackingPhase.completed:
          destination = customerLocation;
          routeDescription = 'Delivery completed';
          break;
      }

      // Calculate route using Google Directions API
      final route = await _calculateRoute(driverLocation, destination);

      // Calculate distance and ETA
      final distance = _calculateDistance(driverLocation, destination);
      final eta = _calculateETA(distance, route);

      yield TrackingData(
        driverLocation: driverLocation,
        customerLocation: customerLocation,
        facilityLocation: facilityLocation,
        destinationLocation: destination,
        routePoints: route,
        distance: distance,
        estimatedArrival: eta,
        phase: phase,
        status: routeDescription,
        orderId: orderId,
        driverId: driverId,
      );
    }
  }

  // Get real-time driver location from Firebase
  Stream<LatLng> _getDriverLocationStream(String driverId) {
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
              controller.add(LatLng(location.latitude, location.longitude));
            }
          }
        });

    return controller.stream;
  }

  // Calculate route using Google Directions API
  Future<List<LatLng>> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'key=$_directionsApiKey'
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final legs = route['legs'] as List;

        List<LatLng> points = [];
        for (final leg in legs) {
          final steps = leg['steps'] as List;
          for (final step in steps) {
            final polyline = step['polyline']['points'];
            points.addAll(_decodePolyline(polyline));
          }
        }
        return points;
      }
    } catch (e) {
      print('Error calculating route: $e');
    }

    // Fallback to straight line if API fails
    return _generateStraightLineRoute(origin, destination);
  }

  // Decode Google polyline
  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Generate straight line route as fallback
  List<LatLng> _generateStraightLineRoute(LatLng start, LatLng end) {
    List<LatLng> points = [];
    const int steps = 20;

    for (int i = 0; i <= steps; i++) {
      final progress = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * progress;
      final lng = start.longitude + (end.longitude - start.longitude) * progress;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  // Get location from address (you can integrate with geocoding service)
  Future<LatLng> _getLocationFromAddress(Map<String, dynamic>? address) async {
    // For now, return a default location
    // In production, use geocoding to convert address to coordinates
    return const LatLng(12.9716, 77.5946);
  }

  // Determine tracking phase from order status
  TrackingPhase _getTrackingPhase(String? status) {
    switch (status) {
      case 'out_for_pickup':
      case 'reached_pickup_location':
        return TrackingPhase.pickup;
      case 'picked_up':
      case 'transit_to_facility':
      case 'reached_facility':
        return TrackingPhase.toFacility;
      case 'out_for_delivery':
      case 'reached_delivery_location':
        return TrackingPhase.toDelivery;
      case 'delivered':
      case 'completed':
        return TrackingPhase.completed;
      default:
        return TrackingPhase.pickup;
    }
  }

  // Calculate distance between two points
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLon = _degreesToRadians(end.longitude - start.longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) *
        math.cos(_degreesToRadians(end.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Calculate estimated time of arrival
  String _calculateETA(double distanceInKm, List<LatLng> route) {
    // Consider route complexity and traffic
    const double averageSpeed = 25.0; // km/h (considering city traffic)
    final estimatedMinutes = (distanceInKm / averageSpeed) * 60;

    if (estimatedMinutes < 2) {
      return 'Arriving now';
    } else if (estimatedMinutes < 60) {
      return '${estimatedMinutes.round()} mins';
    } else {
      final hours = (estimatedMinutes / 60).floor();
      final mins = (estimatedMinutes % 60).round();
      return '${hours}h ${mins}m';
    }
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

  void dispose() {
    _driverSubscription?.cancel();
    _orderSubscription?.cancel();
  }
}

// Enhanced tracking data model
class TrackingData {
  final LatLng driverLocation;
  final LatLng customerLocation;
  final LatLng facilityLocation;
  final LatLng destinationLocation;
  final List<LatLng> routePoints;
  final double distance;
  final String estimatedArrival;
  final TrackingPhase phase;
  final String status;
  final String orderId;
  final String driverId;

  TrackingData({
    required this.driverLocation,
    required this.customerLocation,
    required this.facilityLocation,
    required this.destinationLocation,
    required this.routePoints,
    required this.distance,
    required this.estimatedArrival,
    required this.phase,
    required this.status,
    required this.orderId,
    required this.driverId,
  });

  // Generate markers for map display
  Set<Marker> getMarkers() {
    final markerService = CustomMarkerService();

    Set<Marker> markers = {};

    // Driver marker (use scooter icon for movement, person icon when stationary)
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: driverLocation,
        icon: phase == TrackingPhase.completed ? markerService.driverIcon : markerService.scooterIcon,
        infoWindow: InfoWindow(
          title: 'Driver',
          snippet: 'ETA: $estimatedArrival',
        ),
        anchor: const Offset(0.5, 0.5),
      ),
    );

    // Customer location marker
    markers.add(
      Marker(
        markerId: const MarkerId('customer'),
        position: customerLocation,
        icon: markerService.customerIcon,
        infoWindow: const InfoWindow(
          title: 'Customer Location',
          snippet: 'Pickup/Delivery Address',
        ),
      ),
    );

    // Facility marker (only show if in transit phases)
    if (phase == TrackingPhase.toFacility || phase == TrackingPhase.toDelivery) {
      markers.add(
        Marker(
          markerId: const MarkerId('facility'),
          position: facilityLocation,
          icon: markerService.facilityIcon,
          infoWindow: const InfoWindow(
            title: 'SwiftWash Facility',
            snippet: 'Processing Center',
          ),
        ),
      );
    }

    return markers;
  }

  // Generate polyline for route display
  Set<Polyline> getPolyline() {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: _getRouteColor(),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        patterns: _getRoutePattern(),
      ),
    };
  }

  // Get route color based on phase
  Color _getRouteColor() {
    switch (phase) {
      case TrackingPhase.pickup:
        return Colors.blue;
      case TrackingPhase.toFacility:
        return Colors.orange;
      case TrackingPhase.toDelivery:
        return Colors.green;
      case TrackingPhase.completed:
        return Colors.grey;
    }
  }

  // Get route pattern (solid or dashed)
  List<PatternItem> _getRoutePattern() {
    if (phase == TrackingPhase.completed) {
      return [PatternItem.dash(20), PatternItem.gap(10)];
    }
    return [];
  }
}

enum TrackingPhase {
  pickup,
  toFacility,
  toDelivery,
  completed,
}
