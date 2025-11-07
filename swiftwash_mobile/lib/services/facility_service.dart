import 'dart:convert';
import 'package:shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Facility management service for multi-city operations
class FacilityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _facilitiesKey = 'facilities_data';

  // Predefined facilities
  static const List<Map<String, dynamic>> _defaultFacilities = [
    {
      'id': 'pune_main',
      'name': 'Pune Central',
      'city': 'Pune',
      'latitude': 18.5204,
      'longitude': 73.8567,
      'address': 'Central Pune Facility',
      'phone': '+91-9876543210',
      'isOperational': true,
      'operatingHours': '6:00 AM - 10:00 PM',
      'serviceRadius': 25.0, // km
    },
    {
      'id': 'nagpur_main',
      'name': 'Nagpur Central',
      'city': 'Nagpur',
      'latitude': 21.1458,
      'longitude': 79.0882,
      'address': 'Central Nagpur Facility',
      'phone': '+91-9876543211',
      'isOperational': true,
      'operatingHours': '6:00 AM - 10:00 PM',
      'serviceRadius': 25.0, // km
    },
  ];

  /// Get all facilities
  static Future<List<Map<String, dynamic>>> getFacilities() async {
    try {
      final facilities = await _getFacilitiesFromCache();
      if (facilities.isNotEmpty) {
        return facilities;
      }

      // Fallback to default facilities
      return _defaultFacilities;
    } catch (e) {
      debugPrint('Error getting facilities: $e');
      return _defaultFacilities;
    }
  }

  /// Get operational facilities only
  static Future<List<Map<String, dynamic>>> getOperationalFacilities() async {
    final facilities = await getFacilities();
    return facilities.where((facility) => facility['isOperational'] == true).toList();
  }

  /// Find closest operational facility to a location
  static Future<Map<String, dynamic>?> findClosestFacility(
    double latitude,
    double longitude,
  ) async {
    final facilities = await getOperationalFacilities();

    if (facilities.isEmpty) return null;

    Map<String, dynamic>? closestFacility;
    double closestDistance = double.infinity;

    for (final facility in facilities) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        facility['latitude'] as double,
        facility['longitude'] as double,
      );

      if (distance < closestDistance && distance <= (facility['serviceRadius'] as double? ?? 25.0)) {
        closestDistance = distance;
        closestFacility = facility;
      }
    }

    return closestFacility;
  }

  /// Check if location is within service area
  static Future<bool> isLocationServiced(double latitude, double longitude) async {
    final facility = await findClosestFacility(latitude, longitude);
    return facility != null;
  }

  /// Get facility for a specific city
  static Future<Map<String, dynamic>?> getFacilityForCity(String city) async {
    final facilities = await getOperationalFacilities();
    return facilities.firstWhere(
      (facility) => facility['city'].toString().toLowerCase() == city.toLowerCase(),
      orElse: () => {},
    );
  }

  /// Update facility operational status
  static Future<void> updateFacilityStatus(String facilityId, bool isOperational) async {
    try {
      await _firestore.collection('facilities').doc(facilityId).update({
        'isOperational': isOperational,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update local cache
      await _updateFacilityInCache(facilityId, {'isOperational': isOperational});

    } catch (e) {
      debugPrint('Error updating facility status: $e');
    }
  }

  /// Get coming soon message for unsupported cities
  static String getComingSoonMessage(String cityName) {
    return '''
🌟 Exciting News from SwiftWash!

We're thrilled to see interest from $cityName! 🚀

SwiftWash is rapidly expanding across India, and $cityName is definitely on our radar. We're working hard to bring our premium laundry services to your city soon.

📅 Expected Launch: Coming Soon!
✨ What to expect: Same-day service, premium quality, real-time tracking

Stay tuned for updates! We'll notify you as soon as we launch in $cityName.

In the meantime, you can still place orders from our operational cities:
• Pune Central
• Nagpur Central

Thank you for your patience and support! 🙏
    ''';
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Cache management
  static Future<List<Map<String, dynamic>>> _getFacilitiesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facilitiesJson = prefs.getString(_facilitiesKey);

      if (facilitiesJson != null) {
        final facilities = jsonDecode(facilitiesJson) as List;
        return facilities.map((f) => f as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error getting facilities from cache: $e');
    }

    return [];
  }

  static Future<void> _updateFacilityInCache(String facilityId, Map<String, dynamic> updates) async {
    try {
      final facilities = await _getFacilitiesFromCache();
      final index = facilities.indexWhere((f) => f['id'] == facilityId);

      if (index != -1) {
        facilities[index].addAll(updates);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_facilitiesKey, jsonEncode(facilities));
      }
    } catch (e) {
      debugPrint('Error updating facility in cache: $e');
    }
  }

  /// Get facility statistics
  static Future<Map<String, dynamic>> getFacilityStats() async {
    final facilities = await getFacilities();
    final operational = facilities.where((f) => f['isOperational'] == true).length;

    return {
      'totalFacilities': facilities.length,
      'operationalFacilities': operational,
      'offlineFacilities': facilities.length - operational,
      'citiesCovered': facilities.map((f) => f['city']).toSet().length,
    };
  }
}
