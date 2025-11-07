import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftwash_operator/models/enhanced_operator_order_model.dart';
import 'package:swiftwash_operator/models/order_status_model.dart';

class EnhancedOperatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all orders for operator management
  Stream<List<EnhancedOperatorOrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedOperatorOrderModel.fromFirestore(doc))
            .toList());
  }

  // Get orders by status
  Stream<List<EnhancedOperatorOrderModel>> getOrdersByStatus(OrderStatus status) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedOperatorOrderModel.fromFirestore(doc))
            .toList());
  }

  // Get urgent orders
  Stream<List<EnhancedOperatorOrderModel>> getUrgentOrders() {
    return _firestore
        .collection('orders')
        .where('priority', whereIn: ['urgent', 'high'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedOperatorOrderModel.fromFirestore(doc))
            .toList());
  }

  // Get orders needing attention
  Stream<List<EnhancedOperatorOrderModel>> getOrdersNeedingAttention() {
    final now = DateTime.now();
    final urgentStatuses = [
      'pending',
      'confirmed',
      'driver_assigned',
      'out_for_pickup',
      'reached_pickup_location',
      'out_for_delivery',
      'reached_delivery_location',
    ];

    return _firestore
        .collection('orders')
        .where('status', whereIn: urgentStatuses)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedOperatorOrderModel.fromFirestore(doc))
            .where((order) => order.needsAttention)
            .toList());
  }

  // Update order status with history tracking
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? reason,
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc(orderId);

    // Update order status
    batch.update(orderRef, {
      'status': newStatus.name,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
      if (notes != null) 'notes': notes,
    });

    // Add to status history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': newStatus.name,
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': user.uid,
      'changedByName': await _getOperatorName(user.uid),
      'reason': reason,
      'notes': notes,
      'action': 'operator_update',
    });

    // Send notification to customer
    await _sendStatusUpdateNotification(orderId, newStatus);

    await batch.commit();
  }

  // Update processing status
  Future<void> updateProcessingStatus(
    String orderId,
    OrderStatus processingStatus, {
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc(orderId);

    // Update processing status
    batch.update(orderRef, {
      'currentProcessingStatus': processingStatus.name,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });

    // Add to processing history
    final processingRef = orderRef.collection('processingHistory').doc();
    batch.set(processingRef, {
      'status': processingStatus.name,
      'description': processingStatus.description,
      'timestamp': FieldValue.serverTimestamp(),
      'operatorId': user.uid,
      'operatorName': await _getOperatorName(user.uid),
      'notes': notes,
    });

    await batch.commit();
  }

  // Assign driver to order
  Future<void> assignDriver(String orderId, String driverId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    // Get driver details
    final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
    if (!driverDoc.exists) throw Exception('Driver not found');

    final driverData = driverDoc.data()!;
    final driverName = driverData['name'] ?? 'Unknown Driver';
    final driverPhone = driverData['phone'] ?? '';

    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc(orderId);

    // Update order with driver info
    batch.update(orderRef, {
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'status': 'driver_assigned',
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });

    // Add to status history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': 'driver_assigned',
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': user.uid,
      'changedByName': await _getOperatorName(user.uid),
      'reason': 'Driver assigned: $driverName',
      'action': 'driver_assignment',
      'metadata': {
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
      },
    });

    // Update driver status
    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.update(driverRef, {
      'currentOrderId': orderId,
      'status': 'assigned',
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc(orderId);

    // Update order status
    batch.update(orderRef, {
      'status': 'cancelled',
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'cancelledBy': user.uid,
    });

    // Add to status history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': 'cancelled',
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': user.uid,
      'changedByName': await _getOperatorName(user.uid),
      'reason': reason,
      'action': 'operator_cancelled',
    });

    // Free up driver if assigned
    final orderDoc = await orderRef.get();
    final orderData = orderDoc.data();
    if (orderData?['driverId'] != null) {
      final driverRef = _firestore.collection('drivers').doc(orderData!['driverId']);
      batch.update(driverRef, {
        'currentOrderId': null,
        'status': 'available',
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Bulk update orders
  Future<void> bulkUpdateOrders(List<String> orderIds, OrderStatus newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    final batch = _firestore.batch();
    final operatorName = await _getOperatorName(user.uid);

    for (final orderId in orderIds) {
      final orderRef = _firestore.collection('orders').doc(orderId);

      // Update order status
      batch.update(orderRef, {
        'status': newStatus.name,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      // Add to status history
      final historyRef = orderRef.collection('statusHistory').doc();
      batch.set(historyRef, {
        'status': newStatus.name,
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': user.uid,
        'changedByName': operatorName,
        'reason': 'Bulk update by operator',
        'action': 'bulk_update',
      });
    }

    await batch.commit();
  }

  // Set order priority
  Future<void> setOrderPriority(String orderId, String priority) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    await _firestore.collection('orders').doc(orderId).update({
      'priority': priority,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });
  }

  // Add order notes
  Future<void> addOrderNotes(String orderId, String notes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Operator not authenticated');

    await _firestore.collection('orders').doc(orderId).update({
      'notes': notes,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final orders = await _firestore.collection('orders').get();

    int totalOrders = orders.docs.length;
    int todayOrders = 0;
    int pendingOrders = 0;
    int completedToday = 0;
    double todayRevenue = 0;
    double totalRevenue = 0;

    for (final doc in orders.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final status = data['status'] as String?;
      final finalTotal = (data['finalTotal'] ?? 0).toDouble();

      if (createdAt != null && createdAt.isAfter(today)) {
        todayOrders++;
        totalRevenue += finalTotal;
        todayRevenue += finalTotal;

        if (status == 'completed' || status == 'delivered') {
          completedToday++;
        }
      } else {
        totalRevenue += finalTotal;
      }

      if (status != 'completed' && status != 'delivered' && status != 'cancelled') {
        pendingOrders++;
      }
    }

    return {
      'totalOrders': totalOrders,
      'todayOrders': todayOrders,
      'pendingOrders': pendingOrders,
      'completedToday': completedToday,
      'todayRevenue': todayRevenue,
      'totalRevenue': totalRevenue,
    };
  }

  // Search orders
  Future<List<EnhancedOperatorOrderModel>> searchOrders(String query) async {
    if (query.length < 3) return [];

    final orders = await _firestore.collection('orders').get();

    return orders.docs
        .map((doc) => EnhancedOperatorOrderModel.fromFirestore(doc))
        .where((order) {
          return order.orderId.toLowerCase().contains(query.toLowerCase()) ||
                 order.customerName.toLowerCase().contains(query.toLowerCase()) ||
                 order.customerPhone.contains(query) ||
                 order.formattedAddress.toLowerCase().contains(query.toLowerCase());
        })
        .toList();
  }

  // Get available drivers
  Stream<List<Map<String, dynamic>>> getAvailableDrivers() {
    return _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // Helper methods
  Future<String> _getOperatorName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['name'] ?? data?['email'] ?? 'Operator';
      }
      return 'Operator';
    } catch (e) {
      return 'Operator';
    }
  }

  Future<void> _sendStatusUpdateNotification(String orderId, OrderStatus status) async {
    try {
      // Get order details
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return;

      final orderData = orderDoc.data()!;
      final userId = orderData['userId'] as String?;

      if (userId == null) return;

      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null) return;

      // Send notification (you can implement this using Firebase Cloud Functions)
      // For now, just log it
      print('Sending notification to $fcmToken: Order ${orderData['orderId']} status updated to ${status.displayName}');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
