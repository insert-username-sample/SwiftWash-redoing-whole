import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftwash_mobile/models/enhanced_order_model.dart';

class EnhancedOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's orders with real-time updates
  Stream<List<EnhancedOrderModel>> getUserOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedOrderModel.fromFirestore(doc))
            .toList());
  }

  // Get specific order with real-time updates
  Stream<EnhancedOrderModel?> getOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return EnhancedOrderModel.fromFirestore(doc);
        });
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Update order status
    final orderRef = _firestore.collection('orders').doc(orderId);
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
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': user.uid,
      'action': 'customer_cancelled',
    });

    await batch.commit();
  }

  // Get order status history
  Stream<List<OrderStatusHistory>> getOrderStatusHistory(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('statusHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderStatusHistory.fromFirestore(doc))
            .toList());
  }

  // Get processing history
  Stream<List<ProcessingUpdate>> getProcessingHistory(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('processingHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProcessingUpdate.fromFirestore(doc))
            .toList());
  }

  // Report issue
  Future<void> reportIssue(String orderId, String issueType, String description) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Update order with issue
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'status': 'issue_reported',
      'issueType': issueType,
      'issueDescription': description,
      'issueReportedAt': FieldValue.serverTimestamp(),
      'issueReportedBy': user.uid,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Add to status history
    final historyRef = orderRef.collection('statusHistory').doc();
    batch.set(historyRef, {
      'status': 'issue_reported',
      'issueType': issueType,
      'issueDescription': description,
      'timestamp': FieldValue.serverTimestamp(),
      'changedBy': user.uid,
      'action': 'issue_reported',
    });

    await batch.commit();
  }

  // Rate order
  Future<void> rateOrder(String orderId, int rating, String? review) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore.collection('orders').doc(orderId).update({
      'rating': rating,
      'review': review,
      'ratedAt': FieldValue.serverTimestamp(),
      'ratedBy': user.uid,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Reorder items
  Future<String> reorderItems(String originalOrderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get original order
    final originalOrder = await _firestore.collection('orders').doc(originalOrderId).get();
    if (!originalOrder.exists) throw Exception('Original order not found');

    final originalData = originalOrder.data()!;

    // Create new order with same items
    final newOrderRef = _firestore.collection('orders').doc();
    await newOrderRef.set({
      'orderId': await _generateOrderId(user.uid), // Use your existing order ID generation
      'userId': user.uid,
      'serviceName': originalData['serviceName'],
      'itemTotal': originalData['itemTotal'],
      'swiftCharge': originalData['swiftCharge'],
      'discount': 0, // Reset discount for reorder
      'finalTotal': originalData['itemTotal'] + originalData['swiftCharge'],
      'status': 'pending',
      'address': originalData['address'],
      'items': originalData['items'],
      'createdAt': FieldValue.serverTimestamp(),
      'isReorder': true,
      'originalOrderId': originalOrderId,
    });

    return newOrderRef.id;
  }

  // Generate order ID (use your existing function)
  Future<String> _generateOrderId(String userId) async {
    // Implement your existing order ID generation logic
    return 'SW${DateTime.now().millisecondsSinceEpoch}';
  }
}
