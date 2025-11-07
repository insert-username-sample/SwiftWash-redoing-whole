import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnhancedOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> generateSmartOrderId({
    required String orderType,
    bool isUrgent = false,
    bool isReferred = false,
    bool isStudent = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call Firebase function for order ID generation
      final result = await _functions.httpsCallable('generateSmartOrderId').call({
        'userId': user.uid,
        'orderType': orderType,
        'isUrgent': isUrgent,
        'isReferred': isReferred,
        'isStudent': isStudent,
      });

      if (result.data['success']) {
        return result.data['orderId'];
      } else {
        throw Exception('Failed to generate order ID');
      }
    } catch (e) {
      print('Error generating smart order ID: $e');
      throw Exception('Order ID generation failed: $e');
    }
  }

  Future<Map<String, dynamic>> saveOrderWithSmartId({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      // Save order with the generated smart ID
      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...orderData,
      });

      return {
        'success': true,
        'orderId': orderId,
      };
    } catch (e) {
      throw Exception('Failed to save order: $e');
    }
  }
}
