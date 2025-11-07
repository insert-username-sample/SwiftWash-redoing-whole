import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_admin/models/store_model.dart';
import 'package:swiftwash_admin/models/admin_user_model.dart';
import 'dart:math';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Collection references
  CollectionReference get _storesCollection => _firestore.collection('stores');
  CollectionReference get _adminsCollection => _firestore.collection('admins');

  // Generate unique store code
  String _generateStoreCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }

  // Generate secure admin password
  String _generateAdminPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }

  // Generate unique admin username
  String _generateAdminUsername(String storeName) {
    final baseName = storeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final suffix = _random.nextInt(999).toString().padLeft(3, '0');
    return '${baseName}_admin_$suffix';
  }

  // Create new store with admin credentials
  Future<StoreModel> createStore({
    required String storeName,
    required String ownerName,
    required String ownerPhone,
    required String ownerEmail,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required Map<String, dynamic> location,
    String? description,
    String? logoUrl,
  }) async {
    // Check if store code already exists
    String storeCode;
    bool codeExists = true;
    int attempts = 0;

    do {
      storeCode = _generateStoreCode();
      final existingStore = await _storesCollection
          .where('storeCode', isEqualTo: storeCode)
          .limit(1)
          .get();

      codeExists = existingStore.docs.isNotEmpty;
      attempts++;
    } while (codeExists && attempts < 10);

    if (codeExists) {
      throw Exception('Unable to generate unique store code');
    }

    // Generate admin credentials
    final adminUsername = _generateAdminUsername(storeName);
    final adminPassword = _generateAdminPassword();

    // Create store document
    final storeData = {
      'storeName': storeName,
      'storeCode': storeCode,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerEmail': ownerEmail,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'location': location,
      'status': StoreStatus.pending.index,
      'adminUsername': adminUsername,
      'adminPassword': adminPassword,
      'createdAt': FieldValue.serverTimestamp(),
      'operatorIds': [],
      'settings': {
        'maxOrdersPerDay': 50,
        'operatingHours': {
          'start': '09:00',
          'end': '21:00',
        },
        'services': ['wash', 'dry_clean', 'iron'],
        'autoAssignOrders': true,
      },
      'description': description,
      'logoUrl': logoUrl,
    };

    final docRef = await _storesCollection.add(storeData);
    final doc = await docRef.get();
    return StoreModel.fromFirestore(doc);
  }

  // Get all stores
  Stream<List<StoreModel>> getAllStores() {
    return _storesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList());
  }

  // Get stores by status
  Stream<List<StoreModel>> getStoresByStatus(StoreStatus status) {
    return _storesCollection
        .where('status', isEqualTo: status.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList());
  }

  // Get store by ID
  Future<StoreModel?> getStoreById(String storeId) async {
    final doc = await _storesCollection.doc(storeId).get();
    if (doc.exists) {
      return StoreModel.fromFirestore(doc);
    }
    return null;
  }

  // Get store by code
  Future<StoreModel?> getStoreByCode(String storeCode) async {
    final snapshot = await _storesCollection
        .where('storeCode', isEqualTo: storeCode)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return StoreModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Update store
  Future<void> updateStore(StoreModel store) async {
    await _storesCollection.doc(store.id).update({
      ...store.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update store status
  Future<void> updateStoreStatus(String storeId, StoreStatus status) async {
    await _storesCollection.doc(storeId).update({
      'status': status.index,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete store
  Future<void> deleteStore(String storeId) async {
    await _storesCollection.doc(storeId).delete();
  }

  // Add operator to store
  Future<void> addOperatorToStore(String storeId, String operatorId) async {
    final store = await getStoreById(storeId);
    if (store != null && !store.operatorIds.contains(operatorId)) {
      final updatedOperatorIds = [...store.operatorIds, operatorId];
      await _storesCollection.doc(storeId).update({
        'operatorIds': updatedOperatorIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Remove operator from store
  Future<void> removeOperatorFromStore(String storeId, String operatorId) async {
    final store = await getStoreById(storeId);
    if (store != null && store.operatorIds.contains(operatorId)) {
      final updatedOperatorIds = store.operatorIds.where((id) => id != operatorId).toList();
      await _storesCollection.doc(storeId).update({
        'operatorIds': updatedOperatorIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String storeId) async {
    final store = await getStoreById(storeId);
    if (store == null) {
      throw Exception('Store not found');
    }

    // Get orders count for this store
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .get();

    final totalOrders = ordersSnapshot.docs.length;
    final completedOrders = ordersSnapshot.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .length;
    final pendingOrders = ordersSnapshot.docs
        .where((doc) => doc.data()['status'] == 'pending')
        .length;

    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'operators': store.operatorIds.length,
      'status': store.status.displayName,
      'createdAt': store.createdAt,
    };
  }

  // Search stores
  Future<List<StoreModel>> searchStores(String query) async {
    final snapshot = await _storesCollection
        .where('storeName', isGreaterThanOrEqualTo: query)
        .where('storeName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
  }

  // Validate admin credentials
  Future<StoreModel?> validateAdminCredentials(String storeCode, String username, String password) async {
    final store = await getStoreByCode(storeCode);
    if (store != null &&
        store.adminUsername == username &&
        store.adminPassword == password) {
      return store;
    }
    return null;
  }

  // Get admin dashboard stats
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final storesSnapshot = await _storesCollection.get();
    final operatorsSnapshot = await _firestore.collection('operators').get();
    final ordersSnapshot = await _firestore.collection('orders').get();

    final totalStores = storesSnapshot.docs.length;
    final activeStores = storesSnapshot.docs
        .where((doc) => doc.data()['status'] == StoreStatus.active.index)
        .length;
    final totalOperators = operatorsSnapshot.docs.length;
    final totalOrders = ordersSnapshot.docs.length;
    final completedOrders = ordersSnapshot.docs
        .where((doc) => doc.data()['status'] == 'completed')
        .length;

    return {
      'totalStores': totalStores,
      'activeStores': activeStores,
      'totalOperators': totalOperators,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingStores': storesSnapshot.docs
          .where((doc) => doc.data()['status'] == StoreStatus.pending.index)
          .length,
    };
  }
}