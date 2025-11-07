import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _subscriptions => _firestore.collection('subscriptions');

  // Get current user's subscription
  Future<SubscriptionModel?> getCurrentSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot = await _subscriptions
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['active', 'trial'])
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return SubscriptionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      return null;
    } catch (e) {
      print('Error getting current subscription: $e');
      return null;
    }
  }

  // Create new subscription
  Future<SubscriptionModel?> createSubscription({
    required SubscriptionPlan plan,
    required String paymentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final endDate = now.add(Duration(days: plan.durationDays));

      final subscription = SubscriptionModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        planName: plan.name,
        status: 'active',
        startDate: now,
        endDate: endDate,
        amount: plan.price,
        currency: plan.currency,
        paymentId: paymentId,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _subscriptions.add(subscription.toMap());
      final doc = await docRef.get();

      return SubscriptionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  // Renew subscription
  Future<SubscriptionModel?> renewSubscription({
    required String subscriptionId,
    required SubscriptionPlan plan,
    required String paymentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final currentDoc = await _subscriptions.doc(subscriptionId).get();

      if (!currentDoc.exists) return null;

      final currentSubscription = SubscriptionModel.fromMap(
        currentDoc.data() as Map<String, dynamic>,
        currentDoc.id,
      );

      // Extend the end date
      final newEndDate = currentSubscription.endDate.add(Duration(days: plan.durationDays));

      await _subscriptions.doc(subscriptionId).update({
        'planName': plan.name,
        'endDate': Timestamp.fromDate(newEndDate),
        'amount': plan.price,
        'paymentId': paymentId,
        'updatedAt': Timestamp.fromDate(now),
      });

      final updatedDoc = await _subscriptions.doc(subscriptionId).get();
      return SubscriptionModel.fromMap(
        updatedDoc.data() as Map<String, dynamic>,
        updatedDoc.id,
      );
    } catch (e) {
      print('Error renewing subscription: $e');
      return null;
    }
  }

  // Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _subscriptions.doc(subscriptionId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  // Get subscription history
  Future<List<SubscriptionModel>> getSubscriptionHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _subscriptions
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return SubscriptionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  // Check if user has active premium
  Future<bool> hasActivePremium() async {
    final subscription = await getCurrentSubscription();
    return subscription?.isActive ?? false;
  }
}