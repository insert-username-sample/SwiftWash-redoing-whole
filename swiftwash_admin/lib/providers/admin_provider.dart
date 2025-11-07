import 'package:flutter/foundation.dart';
import 'package:swiftwash_admin/models/admin_user_model.dart';
import 'package:swiftwash_admin/services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  AdminUserModel? _currentAdmin;
  List<AdminUserModel> _admins = [];
  bool _isLoading = false;
  String? _error;

  AdminUserModel? get currentAdmin => _currentAdmin;
  List<AdminUserModel> get admins => _admins;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all admins
  Stream<List<AdminUserModel>> getAllAdmins() {
    return _adminService.getAllAdmins();
  }

  // Get admins by role
  Stream<List<AdminUserModel>> getAdminsByRole(AdminRole role) {
    return _adminService.getAdminsByRole(role);
  }

  // Get admins by status
  Stream<List<AdminUserModel>> getAdminsByStatus(AdminStatus status) {
    return _adminService.getAdminsByStatus(status);
  }

  // Create new admin
  Future<AdminUserModel> createAdmin({
    required String name,
    required String username,
    required String phone,
    required AdminRole role,
    String? storeId,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final admin = await _adminService.createAdmin(
        name: name,
        username: username,
        phone: phone,
        role: role,
        storeId: storeId,
        permissions: permissions,
      );

      _isLoading = false;
      notifyListeners();

      return admin;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update admin
  Future<void> updateAdmin(AdminUserModel admin) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _adminService.updateAdmin(admin);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update admin status
  Future<void> updateAdminStatus(String adminId, AdminStatus status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _adminService.updateAdminStatus(adminId, status);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete admin
  Future<void> deleteAdmin(String adminId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _adminService.deleteAdmin(adminId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Authenticate admin
  Future<AdminUserModel?> authenticateAdmin(String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final admin = await _adminService.authenticateAdmin(username, password);

      if (admin != null) {
        _currentAdmin = admin;
      }

      _isLoading = false;
      notifyListeners();

      return admin;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out current admin
  void signOut() {
    _currentAdmin = null;
    _error = null;
    notifyListeners();
  }

  // Check if current admin has permission
  bool hasPermission(String permission) {
    if (_currentAdmin == null) return false;

    final permissions = _currentAdmin!.permissions ?? {};
    return permissions[permission] == true;
  }

  // Check if current admin has role
  bool hasRole(AdminRole role) {
    return _currentAdmin?.role == role;
  }

  // Check if current admin is super admin
  bool get isSuperAdmin {
    return _currentAdmin?.role == AdminRole.superAdmin;
  }

  // Check if current admin is store admin
  bool get isStoreAdmin {
    return _currentAdmin?.role == AdminRole.storeAdmin;
  }

  // Check if current admin is support admin
  bool get isSupportAdmin {
    return _currentAdmin?.role == AdminRole.supportAdmin;
  }

  // Get admin dashboard stats
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      return await _adminService.getAdminDashboardStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get admin activity logs
  Stream<List<Map<String, dynamic>>> getAdminActivityLogs(String adminId) {
    return _adminService.getAdminActivityLogs(adminId);
  }

  // Log admin activity
  Future<void> logAdminActivity(String adminId, String action, Map<String, dynamic> details) async {
    try {
      await _adminService.logAdminActivity(adminId, action, details);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Reset admin password
  Future<String> resetAdminPassword(String adminId) async {
    try {
      return await _adminService.resetAdminPassword(adminId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update admin permissions
  Future<void> updateAdminPermissions(String adminId, Map<String, dynamic> permissions) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _adminService.updateAdminPermissions(adminId, permissions);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Search admins
  Future<List<AdminUserModel>> searchAdmins(String query) async {
    try {
      return await _adminService.searchAdmins(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get admin by store
  Stream<List<AdminUserModel>> getAdminsByStore(String storeId) {
    return _adminService.getAdminsByStore(storeId);
  }

  // Assign admin to store
  Future<void> assignAdminToStore(String adminId, String storeId) async {
    try {
      await _adminService.assignAdminToStore(adminId, storeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Remove admin from store
  Future<void> removeAdminFromStore(String adminId, String storeId) async {
    try {
      await _adminService.removeAdminFromStore(adminId, storeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  void refresh() {
    notifyListeners();
  }
}
