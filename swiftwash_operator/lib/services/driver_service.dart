import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_operator/models/driver_model.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all drivers with real-time updates
  Stream<List<DriverModel>> getAllDrivers() {
    return _firestore
        .collection('drivers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DriverModel.fromFirestore(doc)).toList());
  }

  // Get available drivers
  Stream<List<DriverModel>> getAvailableDrivers() {
    return _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'available')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DriverModel.fromFirestore(doc)).toList());
  }

  // Get driver by ID
  Future<DriverModel?> getDriverById(String driverId) async {
    final doc = await _firestore.collection('drivers').doc(driverId).get();
    if (doc.exists) {
      return DriverModel.fromFirestore(doc);
    }
    return null;
  }

  // Update driver status
  Future<void> updateDriverStatus(String driverId, String status) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'status': status,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Update driver location
  Future<void> updateDriverLocation(
      String driverId, GeoPoint location) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'currentLocation': location,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Add new driver
  Future<void> addDriver(DriverModel driver) async {
    await _firestore.collection('drivers').doc(driver.id).set(driver.toMap());
  }

  // Update driver profile
  Future<void> updateDriverProfile(String driverId, Map<String, dynamic> updates) async {
    updates['lastUpdated'] = FieldValue.serverTimestamp();
    await _firestore.collection('drivers').doc(driverId).update(updates);
  }

  // Remove driver from order (unassign)
  Future<void> unassignDriverFromOrder(String driverId) async {
    final batch = _firestore.batch();

    // Get current driver data
    final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
    if (driverDoc.exists) {
      final driverData = driverDoc.data()!;
      final currentOrderId = driverData['currentOrderId'] as String?;

      if (currentOrderId != null) {
        // Update driver's order reference
        batch.update(_firestore.collection('drivers').doc(driverId), {
          'currentOrderId': FieldValue.delete(),
          'status': 'available',
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Update order if it exists
        final orderRef = _firestore.collection('orders').doc(currentOrderId);
        batch.update(orderRef, {
          'driverId': FieldValue.delete(),
          'status': 'new', // Reset to new status
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  // Get drivers nearby a location (within certain radius)
  Future<List<DriverModel>> getNearbyDrivers(GeoPoint center, double radiusInKm) async {
    // Note: This is a simplified version. In production, you'd want to use
    // GeoFirestore or similar for proper geospatial queries
    final querySnapshot = await _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'available')
        .get();

    final drivers = querySnapshot.docs
        .map((doc) => DriverModel.fromFirestore(doc))
        .where((driver) {
          if (driver.currentLocation == null) return false;
          // Calculate distance (simplified - use haversine formula in production)
          final distance = _calculateDistance(
            center.latitude,
            center.longitude,
            driver.currentLocation!.latitude,
            driver.currentLocation!.longitude,
          );
          return distance <= radiusInKm;
        })
        .toList();

    return drivers;
  }

  // Get driver statistics
  Future<Map<String, dynamic>> getDriverStats() async {
    final querySnapshot = await _firestore.collection('drivers').get();

    int totalDrivers = querySnapshot.docs.length;
    int availableDrivers = 0;
    int busyDrivers = 0;
    int offlineDrivers = 0;
    double averageRating = 0.0;
    int totalRatings = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String?;
      final rating = (data['rating'] ?? 0).toDouble();

      switch (status) {
        case 'available':
          availableDrivers++;
          break;
        case 'busy':
          busyDrivers++;
          break;
        case 'offline':
        default:
          offlineDrivers++;
          break;
      }

      averageRating += rating;
      totalRatings++;
    }

    if (totalRatings > 0) {
      averageRating /= totalRatings;
    }

    return {
      'totalDrivers': totalDrivers,
      'availableDrivers': availableDrivers,
      'busyDrivers': busyDrivers,
      'offlineDrivers': offlineDrivers,
      'averageRating': averageRating,
    };
  }

  // Search drivers
  Future<List<DriverModel>> searchDrivers(String query) async {
    final querySnapshot = await _firestore.collection('drivers').get();

    return querySnapshot.docs
        .map((doc) => DriverModel.fromFirestore(doc))
        .where((driver) =>
            driver.name.toLowerCase().contains(query.toLowerCase()) ||
            driver.phone.contains(query) ||
            (driver.vehicleNumber?.contains(query) ?? false))
        .take(20)
        .toList();
  }

  // Update driver rating
  Future<void> updateDriverRating(String driverId, double newRating) async {
    final driverRef = _firestore.collection('drivers').doc(driverId);
    final driverDoc = await driverRef.get();

    if (driverDoc.exists) {
      final currentData = driverDoc.data()!;
      final currentRating = (currentData['rating'] ?? 0).toDouble();
      final totalOrders = (currentData['totalOrders'] ?? 0) + 1;

      // Calculate new average rating
      final updatedRating = ((currentRating * (totalOrders - 1)) + newRating) / totalOrders;

      await driverRef.update({
        'rating': updatedRating,
        'totalOrders': totalOrders,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // Calculate distance between two points (simplified Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = _haversine(dLat) +
        _haversine(dLon) * _haversine(lat1) * _haversine(lat2);
    final double c = 2 * _haversine(a);

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  double _haversine(double value) {
    return value * value;
  }
}
