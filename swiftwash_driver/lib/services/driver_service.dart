import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:swiftwash_driver/models/driver_profile_model.dart';
import 'dart:io';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or get driver profile
  Future<DriverProfileModel?> getDriverProfile(String userId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(userId).get();
      if (doc.exists) {
        return DriverProfileModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting driver profile: $e');
      return null;
    }
  }

  // Create new driver profile
  Future<DriverProfileModel> createDriverProfile({
    required String phoneNumber,
    String? email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final driverProfile = DriverProfileModel(
      id: user.uid,
      userId: user.uid,
      phoneNumber: phoneNumber,
      email: email,
      status: DriverStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('drivers').doc(user.uid).set(driverProfile.toFirestore());
    return driverProfile;
  }

  // Update personal information
  Future<void> updatePersonalInfo({
    required String fullName,
    required String dateOfBirth,
    required String gender,
    required String address,
    required String city,
    required String pincode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('drivers').doc(user.uid).update({
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'city': city,
      'pincode': pincode,
    });
  }

  // Upload document to Firebase Storage
  Future<String> uploadDocument(File file, String documentType, String userId) async {
    try {
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('drivers/$userId/documents/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  // Update documents
  Future<void> updateDocuments({
    String? profilePhotoUrl,
    String? idProofUrl,
    String? idProofType,
    String? idProofNumber,
    String? drivingLicenseUrl,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (profilePhotoUrl != null) updates['profilePhotoUrl'] = profilePhotoUrl;
    if (idProofUrl != null) updates['idProofUrl'] = idProofUrl;
    if (idProofType != null) updates['idProofType'] = idProofType;
    if (idProofNumber != null) updates['idProofNumber'] = idProofNumber;
    if (drivingLicenseUrl != null) updates['drivingLicenseUrl'] = drivingLicenseUrl;
    if (drivingLicenseNumber != null) updates['drivingLicenseNumber'] = drivingLicenseNumber;
    if (drivingLicenseExpiry != null) updates['drivingLicenseExpiry'] = Timestamp.fromDate(drivingLicenseExpiry);

    await _firestore.collection('drivers').doc(user.uid).update(updates);
  }

  // Update vehicle information
  Future<void> updateVehicleInfo({
    required VehicleType vehicleType,
    required String vehicleModel,
    required String vehicleNumber,
    required String vehicleColor,
    String? vehiclePhotoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('drivers').doc(user.uid).update({
      'vehicleType': vehicleType.name,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'vehicleColor': vehicleColor,
      'vehiclePhotoUrl': vehiclePhotoUrl,
    });
  }

  // Update bank details
  Future<void> updateBankDetails({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('drivers').doc(user.uid).update({
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
    });
  }

  // Update emergency contact
  Future<void> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('drivers').doc(user.uid).update({
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    });
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('drivers').doc(user.uid).update({
      'isOnline': isOnline,
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update current location
  Future<void> updateCurrentLocation(GeoPoint location, {double? heading, double? speed}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{
      'currentLocation': location,
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    };

    if (heading != null) updates['heading'] = heading;
    if (speed != null) updates['speed'] = speed;

    await _firestore.collection('drivers').doc(user.uid).update(updates);
  }

  // Accept order
  Future<void> acceptOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Update driver status
    batch.update(_firestore.collection('drivers').doc(user.uid), {
      'currentOrderId': orderId,
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    });

    // Update order status
    batch.update(_firestore.collection('orders').doc(orderId), {
      'status': 'driver_assigned',
      'driverId': user.uid,
      'assignedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Update order status
    batch.update(_firestore.collection('orders').doc(orderId), {
      'status': status,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
      'updatedBy': user.uid,
    });

    // If order completed, clear current order and update performance metrics
    if (status == 'delivered' || status == 'completed') {
      batch.update(_firestore.collection('drivers').doc(user.uid), {
        'currentOrderId': null,
        'totalOrders': FieldValue.increment(1),
        'completedOrders': FieldValue.increment(1),
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    await batch.commit();
  }

  // Get available orders for driver
  Stream<List<Map<String, dynamic>>> getAvailableOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'ready_for_delivery')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Get current order
  Future<Map<String, dynamic>?> getCurrentOrder() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
    final driverData = driverDoc.data();
    final currentOrderId = driverData?['currentOrderId'];

    if (currentOrderId == null) return null;

    final orderDoc = await _firestore.collection('orders').doc(currentOrderId).get();
    if (!orderDoc.exists) return null;

    return {
      'id': orderDoc.id,
      ...orderDoc.data()!,
    };
  }

  // Get earnings history
  Future<List<Map<String, dynamic>>> getEarningsHistory({int limit = 50}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final orders = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.uid)
        .where('status', whereIn: ['delivered', 'completed'])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return orders.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
  }

  // Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
    final driverData = driverDoc.data();

    if (driverData == null) throw Exception('Driver profile not found');

    final totalOrders = driverData['totalOrders'] ?? 0;
    final completedOrders = driverData['completedOrders'] ?? 0;
    final rating = (driverData['rating'] ?? 0).toDouble();
    final totalRatings = driverData['totalRatings'] ?? 0;
    final earnings = (driverData['earnings'] ?? 0).toDouble();

    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'completionRate': totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0,
      'rating': rating,
      'totalRatings': totalRatings,
      'earnings': earnings,
      'averageRating': totalRatings > 0 ? rating / totalRatings : 0.0,
    };
  }

  // Submit rating for customer
  Future<void> rateCustomer(String orderId, double rating, String? feedback) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('orders').doc(orderId).update({
      'driverRating': rating,
      'driverFeedback': feedback,
      'ratedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Report issue with order
  Future<void> reportIssue(String orderId, String issueType, String description) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('orders').doc(orderId).collection('issues').add({
      'reportedBy': user.uid,
      'issueType': issueType,
      'description': description,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'status': 'pending',
    });
  }

  // Get notifications
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get support tickets
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final tickets = await _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return tickets.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
  }

  // Create support ticket
  Future<void> createSupportTicket(String subject, String description, String category) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('support_tickets').add({
      'userId': user.uid,
      'userType': 'driver',
      'subject': subject,
      'description': description,
      'category': category,
      'status': 'open',
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete account (soft delete)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('drivers').doc(user.uid).update({
      'status': DriverStatus.suspended.name,
      'isDeleted': true,
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Listen to driver profile changes
  Stream<DriverProfileModel?> getDriverProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('drivers')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return DriverProfileModel.fromFirestore(doc);
          }
          return null;
        });
  }

  // Check if driver can work today (based on documents and status)
  Future<bool> canWorkToday() async {
    final profile = await getDriverProfile(_auth.currentUser?.uid ?? '');
    if (profile == null) return false;

    return profile.status == DriverStatus.active &&
           profile.isProfileComplete &&
           profile.isDocumentsVerified;
  }

  // Get today's earnings
  Future<double> getTodaysEarnings() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final orders = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: user.uid)
        .where('status', whereIn: ['delivered', 'completed'])
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    double total = 0.0;
    for (final doc in orders.docs) {
      final data = doc.data();
      total += (data['driverEarnings'] ?? 0).toDouble();
    }

    return total;
  }

  // Reset today's earnings (called at midnight)
  Future<void> resetTodaysEarnings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('drivers').doc(user.uid).update({
      'todaysEarnings': 0.0,
    });
  }
}
