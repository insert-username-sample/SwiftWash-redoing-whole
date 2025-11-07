import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_admin/models/admin_user_model.dart';
import 'package:swiftwash_admin/models/store_model.dart';
import 'dart:math';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Collection references
  CollectionReference get _adminsCollection => _firestore.collection('admins');
  CollectionReference get _storesCollection => _firestore.collection('stores');

  // Generate secure admin password
  String _generateAdminPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    return String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }

  // Create new admin user
  Future<AdminUserModel> createAdmin({
    required String username,
    required String name,
    required String phone,
    required AdminRole role,
    List<String>? managedStoreIds,
    String? profileImageUrl,
  }) async {
    // Check if admin with this username already exists
    final existingAdmin = await _adminsCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (existingAdmin.docs.isNotEmpty) {
      throw Exception('Admin with this username already exists');
    }

    final now = DateTime.now();
    final adminData = {
      'username': username,
      'name': name,
      'phone': phone,
      'role': role.index,
      'status': AdminStatus.active.index,
      'managedStoreIds': managedStoreIds ?? [],
      'createdAt': Timestamp.fromDate(now),
      'permissions': _getDefaultPermissions(role),
      'isEmailVerified': false,
      'isPhoneVerified': false,
      'profileImageUrl': profileImageUrl,
    };

    final docRef = await _adminsCollection.add(adminData);
    final doc = await docRef.get();
    return AdminUserModel.fromFirestore(doc);
  }

  // Get default permissions based on role
  Map<String, dynamic> _getDefaultPermissions(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return {
          'manageAdmins': true,
          'manageStores': true,
          'manageOperators': true,
          'viewAllData': true,
          'manageSettings': true,
          'viewReports': true,
          'manageSupport': true,
        };
      case AdminRole.storeAdmin:
        return {
          'manageAdmins': false,
          'manageStores': true,
          'manageOperators': true,
          'viewAllData': false,
          'manageSettings': true,
          'viewReports': true,
          'manageSupport': false,
        };
      case AdminRole.supportAdmin:
        return {
          'manageAdmins': false,
          'manageStores': false,
          'manageOperators': false,
          'viewAllData': false,
          'manageSettings': false,
          'viewReports': false,
          'manageSupport': true,
        };
    }
  }

  // Authenticate admin
  Future<AdminUserModel?> authenticateAdmin(String username, String password) async {
    // In a real app, you'd hash the password and compare
    // For now, we'll use a simple check (this should be improved)
    final snapshot = await _adminsCollection
        .where('username', isEqualTo: username)
        .where('status', isEqualTo: AdminStatus.active.index)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final admin = AdminUserModel.fromFirestore(snapshot.docs.first);

    // Update last login
    await _adminsCollection.doc(admin.id).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return admin;
  }

  // Get all admins
  Stream<List<AdminUserModel>> getAllAdmins() {
    return _adminsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdminUserModel.fromFirestore(doc)).toList());
  }

  // Get admins by role
  Stream<List<AdminUserModel>> getAdminsByRole(AdminRole role) {
    return _adminsCollection
        .where('role', isEqualTo: role.index)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdminUserModel.fromFirestore(doc)).toList());
  }

  // Get admin by ID
  Future<AdminUserModel?> getAdminById(String adminId) async {
    final doc = await _adminsCollection.doc(adminId).get();
    if (doc.exists) {
      return AdminUserModel.fromFirestore(doc);
    }
    return null;
  }

  // Update admin
  Future<void> updateAdmin(AdminUserModel admin) async {
    await _adminsCollection.doc(admin.id).update({
      ...admin.toFirestore(),
    });
  }

  // Update admin status
  Future<void> updateAdminStatus(String adminId, AdminStatus status) async {
    await _adminsCollection.doc(adminId).update({
      'status': status.index,
    });
  }

  // Delete admin
  Future<void> deleteAdmin(String adminId) async {
    await _adminsCollection.doc(adminId).delete();
  }

  // Assign stores to admin
  Future<void> assignStoresToAdmin(String adminId, List<String> storeIds) async {
    await _adminsCollection.doc(adminId).update({
      'managedStoreIds': storeIds,
    });
  }

  // Get admin dashboard stats
  Future<Map<String, dynamic>> getAdminDashboardStats(String adminId) async {
    final admin = await getAdminById(adminId);
    if (admin == null) {
      throw Exception('Admin not found');
    }

    Map<String, dynamic> stats = {
      'totalAdmins': 0,
      'totalStores': 0,
      'activeStores': 0,
      'totalOperators': 0,
      'totalOrders': 0,
    };

    if (admin.isSuperAdmin) {
      // Super admin can see all stats
      final adminsSnapshot = await _adminsCollection.get();
      final storesSnapshot = await _storesCollection.get();
      final operatorsSnapshot = await _firestore.collection('operators').get();
      final ordersSnapshot = await _firestore.collection('orders').get();

      stats['totalAdmins'] = adminsSnapshot.docs.length;
      stats['totalStores'] = storesSnapshot.docs.length;
      stats['activeStores'] = storesSnapshot.docs
          .where((doc) => doc.data()['status'] == 0) // StoreStatus.active.index
          .length;
      stats['totalOperators'] = operatorsSnapshot.docs.length;
      stats['totalOrders'] = ordersSnapshot.docs.length;
    } else {
      // Regular admin can only see their managed stores
      final storesSnapshot = await _storesCollection
          .where(FieldPath.documentId, whereIn: admin.managedStoreIds)
          .get();

      stats['totalStores'] = storesSnapshot.docs.length;
      stats['activeStores'] = storesSnapshot.docs
          .where((doc) => doc.data()['status'] == 0)
          .length;

      // Get operators for managed stores
      int totalOperators = 0;
      for (final storeDoc in storesSnapshot.docs) {
        final store = StoreModel.fromFirestore(storeDoc);
        totalOperators += store.operatorIds.length;
      }

      stats['totalOperators'] = totalOperators;
    }

    return stats;
  }

  // Search admins
  Future<List<AdminUserModel>> searchAdmins(String query) async {
    final snapshot = await _adminsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) => AdminUserModel.fromFirestore(doc)).toList();
  }

  // Reset admin password
  Future<String> resetAdminPassword(String adminId) async {
    final newPassword = _generateAdminPassword();
    await _adminsCollection.doc(adminId).update({
      'passwordResetRequired': true,
      'tempPassword': newPassword,
    });
    return newPassword;
  }

  // Verify admin email
  Future<void> verifyAdminEmail(String adminId) async {
    await _adminsCollection.doc(adminId).update({
      'isEmailVerified': true,
    });
  }

  // Verify admin phone
  Future<void> verifyAdminPhone(String adminId) async {
    await _adminsCollection.doc(adminId).update({
      'isPhoneVerified': true,
    });
  }

  // Get admin permissions
  Future<Map<String, dynamic>> getAdminPermissions(String adminId) async {
    final admin = await getAdminById(adminId);
    if (admin != null) {
      return admin.permissions;
    }
    return {};
  }

  // Update admin permissions
  Future<void> updateAdminPermissions(String adminId, Map<String, dynamic> permissions) async {
    await _adminsCollection.doc(adminId).update({
      'permissions': permissions,
    });
  }
}