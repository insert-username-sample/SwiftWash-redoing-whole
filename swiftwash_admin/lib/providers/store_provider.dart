import 'package:flutter/foundation.dart';
import 'package:swiftwash_admin/models/store_model.dart';
import 'package:swiftwash_admin/services/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();

  List<StoreModel> _stores = [];
  bool _isLoading = false;
  String? _error;

  List<StoreModel> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all stores
  Stream<List<StoreModel>> getAllStores() {
    return _storeService.getAllStores();
  }

  // Get stores by status
  Stream<List<StoreModel>> getStoresByStatus(StoreStatus status) {
    return _storeService.getStoresByStatus(status);
  }

  // Create new store
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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final store = await _storeService.createStore(
        storeName: storeName,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        location: location,
        description: description,
        logoUrl: logoUrl,
      );

      _isLoading = false;
      notifyListeners();

      return store;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update store
  Future<void> updateStore(StoreModel store) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _storeService.updateStore(store);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update store status
  Future<void> updateStoreStatus(String storeId, StoreStatus status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _storeService.updateStoreStatus(storeId, status);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete store
  Future<void> deleteStore(String storeId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _storeService.deleteStore(storeId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Add operator to store
  Future<void> addOperatorToStore(String storeId, String operatorId) async {
    try {
      await _storeService.addOperatorToStore(storeId, operatorId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Remove operator from store
  Future<void> removeOperatorFromStore(String storeId, String operatorId) async {
    try {
      await _storeService.removeOperatorFromStore(storeId, operatorId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStats(String storeId) async {
    try {
      return await _storeService.getStoreStats(storeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Search stores
  Future<List<StoreModel>> searchStores(String query) async {
    try {
      return await _storeService.searchStores(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Validate admin credentials
  Future<StoreModel?> validateAdminCredentials(String storeCode, String username, String password) async {
    try {
      return await _storeService.validateAdminCredentials(storeCode, username, password);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get admin dashboard stats
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      return await _storeService.getAdminDashboardStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Reset admin password
  Future<String> resetAdminPassword(String storeId) async {
    try {
      return await _storeService.resetAdminPassword(storeId);
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