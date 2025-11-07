import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_operator/models/order_model.dart';
import 'package:swiftwash_operator/services/audio_ring_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get orders by status
  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    // Fix: Avoid complex index requirements by using simpler query
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit for performance
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          // Filter by status client-side to avoid index requirements
          return orders.where((order) => order.status == status).toList();
        });
  }

  // Get all orders with real-time updates
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit for performance
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final batch = _firestore.batch();

    // Update the order status
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'status': newStatus,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Add status change to order history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': newStatus,
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': 'operator', // TODO: Add actual operator ID
    });

    await batch.commit();
  }

  // Assign driver to order
  Future<void> assignDriverToOrder(String orderId, String driverId) async {
    // First get the order data to prepare for notification
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) throw Exception('Order not found');

    final orderData = orderDoc.data()!;
    final batch = _firestore.batch();

    // Update order with driver
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'driverId': driverId,
      'status': 'processing', // Change status when driver is assigned
      'assignedAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Update driver status
    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.update(driverRef, {
      'status': 'busy',
      'currentOrderId': orderId,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Add assignment to order history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': 'processing',
      'driverId': driverId,
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': 'operator',
      'action': 'assigned_to_driver',
    });

    await batch.commit();

    // Trigger driver assignment notification after successful assignment
    await triggerDriverAssignment(orderId, driverId, orderData);
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final querySnapshot = await _firestore.collection('orders').get();

    int totalOrders = 0;
    int todayOrders = 0;
    int completedToday = 0;
    int pendingOrders = 0;
    double totalRevenue = 0.0;
    double todayRevenue = 0.0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      totalOrders++;
      totalRevenue += (data['totalAmount'] ?? 0).toDouble();

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null && createdAt.isAfter(today)) {
        todayOrders++;
        todayRevenue += (data['totalAmount'] ?? 0).toDouble();
      }

      final status = data['status'] as String?;
      if (status == 'completed' &&
          createdAt != null &&
          createdAt.isAfter(today)) {
        completedToday++;
      }

      if (status == 'new' || status == 'processing') {
        pendingOrders++;
      }
    }

    return {
      'totalOrders': totalOrders,
      'todayOrders': todayOrders,
      'completedToday': completedToday,
      'pendingOrders': pendingOrders,
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
    };
  }

  // Search orders by order ID or customer name
  Future<List<OrderModel>> searchOrders(String query) async {
    // Fix: Use simple query and filter client-side to avoid index requirements
    final snapshot = await _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final allOrders = snapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();

    // Filter by order ID prefix match (case insensitive)
    final orderIdMatches = allOrders
        .where((order) => order.orderId.toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    if (orderIdMatches.isNotEmpty) {
      return orderIdMatches.take(20).toList(); // Limit results to 20
    }

    // If no order ID match, search in customer info
    final customerMatches = allOrders
        .where((order) {
          final customerInfo = order.customerInfo;
          final customerName = customerInfo != null && customerInfo['name'] != null
            ? customerInfo['name'].toString().toLowerCase()
            : '';
          return customerName.contains(query.toLowerCase());
        })
        .toList();

    return customerMatches.take(20).toList(); // Limit results to 20
  }

  // Bulk operations
  Future<void> bulkUpdateOrderStatus(
      List<String> orderIds, String newStatus) async {
    final batch = _firestore.batch();

    for (final orderId in orderIds) {
      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Add to status history
      final historyRef = orderRef.collection('statusHistory').doc();
      batch.set(historyRef, {
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': 'operator',
        'action': 'bulk_update',
      });
    }

    await batch.commit();
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    final batch = _firestore.batch();

    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'status': 'cancelled',
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Add to status history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': 'cancelled',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': 'operator',
      'action': 'cancelled',
    });

    await batch.commit();
  }

  // Update order priority
  Future<void> updateOrderPriority(String orderId, String priority) async {
    await _firestore.collection('orders').doc(orderId).update({
      'priority': priority,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Update detailed processing status
  Future<void> updateProcessingStatus(
    String orderId,
    String processingStatus, {
    String? description,
    String? notes,
    String? operatorId,
  }) async {
    final batch = _firestore.batch();

    // Update order with current processing status
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'currentProcessingStatus': processingStatus,
      'lastProcessingUpdate': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Add detailed processing status to processing history
    final processingHistoryRef = orderRef.collection('processingHistory').doc();

    final processingData = {
      'status': processingStatus,
      'timestamp': FieldValue.serverTimestamp(),
      'description': description ?? getProcessingStatusDescription(processingStatus),
      'operatorId': operatorId ?? 'system',
      'notes': notes,
    };

    // For critical statuses, also update the main status
    if (_shouldUpdateMainStatus(processingStatus)) {
      final newMainStatus = _getMainStatusForProcessingStatus(processingStatus);

      // Update main status
      batch.update(orderRef, {
        'status': newMainStatus,
        'mainStatusUpdatedFromProcessing': true,
      });

      // Add main status update to history
      final historyRef = orderRef.collection('statusHistory').doc();
      batch.set(historyRef, {
        'status': newMainStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': operatorId ?? 'system',
        'triggerSource': 'processing_status_update',
        'processingStatus': processingStatus,
      });

      processingData['triggeredMainStatusUpdate'] = true;
    }

    batch.set(processingHistoryRef, processingData);

    await batch.commit();
  }

  // Bulk update processing status
  Future<void> bulkUpdateProcessingStatus(
    List<String> orderIds,
    String processingStatus, {
    String? description,
    String? notes,
    String? operatorId,
  }) async {
    final batch = _firestore.batch();

    for (final orderId in orderIds) {
      final orderRef = _firestore.collection('orders').doc(orderId);

      // Update processing status
      batch.update(orderRef, {
        'currentProcessingStatus': processingStatus,
        'lastProcessingUpdate': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Add to processing history
      final processingHistoryRef = orderRef.collection('processingHistory').doc();
      batch.set(processingHistoryRef, {
        'status': processingStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'description': description ?? getProcessingStatusDescription(processingStatus),
        'operatorId': operatorId ?? 'system',
        'notes': notes,
        'bulkUpdate': true,
      });

      // Update main status if applicable
      if (_shouldUpdateMainStatus(processingStatus)) {
        final newMainStatus = _getMainStatusForProcessingStatus(processingStatus);
        batch.update(orderRef, {
          'status': newMainStatus,
        });

        // Add main status update to history
        final historyRef = orderRef.collection('statusHistory').doc();
        batch.set(historyRef, {
          'status': newMainStatus,
          'timestamp': FieldValue.serverTimestamp(),
          'changedBy': operatorId ?? 'system',
          'triggerSource': 'processing_status_bulk_update',
          'processingStatus': processingStatus,
        });
      }
    }

    await batch.commit();
  }

  // Get processing status history for an order
  Future<List<Map<String, dynamic>>> getProcessingHistory(String orderId) async {
    final snapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('processingHistory')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'timestamp': data['timestamp'] as Timestamp?,
      };
    }).toList();
  }

  // Get current processing status for an order
  Future<String?> getCurrentProcessingStatus(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>)['currentProcessingStatus'] as String?;
  }

  // Helper methods for status mapping
  String getProcessingStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'sorting':
        return 'Sorting clothes by type and color for optimal processing';
      case 'washing':
        return 'Washing in progress with appropriate water temperature and detergents';
      case 'drying':
        return 'Industrial drying to ensure clothes are dry and fresh';
      case 'ironing':
        return 'Steam ironing for crisp, professional appearance';
      case 'quality check':
        return 'Final inspection for freshness, stains, and quality assurance';
      case 'ready for delivery':
        return 'Quality check complete, packed and ready for delivery';
      case 'facilities maintenance':
        return 'Equipment maintenance and facility cleaning';
      default:
        return 'Order processing step';
    }
  }

  bool _shouldUpdateMainStatus(String processingStatus) {
    // Define which processing statuses should trigger main status updates
    const triggeringStatuses = [
      'sorting', // Processing started
      'washing', // Active washing
      'ready for delivery', // Processing complete, now in delivery preparation
      'arrived at facility', // Facility processing begins
    ];

    return triggeringStatuses.contains(processingStatus.toLowerCase());
  }

  String _getMainStatusForProcessingStatus(String processingStatus) {
    switch (processingStatus.toLowerCase()) {
      case 'sorting':
        return 'processing'; // Now in active processing phase
      case 'washing':
        return 'processing'; // Actively processing
      case 'ready for delivery':
        return 'completed'; // Processing complete, now in delivery preparation
      case 'arrived at facility':
        return 'processing'; // Facility processing begins
      default:
        return 'processing';
    }
  }

  /// Trigger ringing for new order notification (called when new order arrives)
  Future<void> triggerNewOrderNotification(String orderId, Map<String, dynamic> orderData) async {
    await AudioRingService.initialize();

    // Check if this is an urgent/priority order
    final isUrgent = orderData['priority'] == 'high' || orderData['urgent'] == true;

    if (isUrgent || orderData['type'] == 'express') {
      await AudioRingService.ringForOrder(
        orderId: orderId,
        orderData: orderData,
        onTimeout: () {
          print('New order notification timeout for: $orderId');
        },
      );
    }
  }

  /// Trigger ringing when driver is assigned to order
  Future<void> triggerDriverAssignment(String orderId, String driverId, Map<String, dynamic> orderData) async {
    await AudioRingService.initialize();

    // Send notification to specific driver via Firebase Functions/Admin SDK
    // For now, we'll rely on Firebase Cloud Messaging to send the notification
    // which will be handled by the driver's notification service

    print('Driver $driverId assigned to order $orderId - notification will be sent via FCM');
  }

  /// Listen for new orders and trigger notifications
  Stream<List<OrderModel>> getOrdersWithNotifications() {
    return getAllOrders().map((orders) {
      // Trigger notifications for new orders (this would be more sophisticated in production)
      // You'd typically compare with previously seen orders and trigger only for truly new ones
      final newOrders = orders.where((order) => order.status == 'new');

      for (final order in newOrders) {
        // In production, you'd check if notification was already sent for this order
        print('Detected new order: ${order.orderId}');

        // Simulate triggering notification for demo
        // In production: triggerNewOrderNotification(order.id, order.toFirestore());
      }

      return orders;
    });
  }
}
