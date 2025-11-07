import 'package:flutter/foundation.dart';
import 'package:swiftwash_operator/models/operator_model.dart';
import 'package:swiftwash_operator/services/operator_service.dart';

class OperatorProvider with ChangeNotifier {
  final OperatorService _operatorService = OperatorService();

  OperatorModel? _currentOperator;
  List<OperatorModel> _operators = [];
  bool _isLoading = false;
  String? _error;

  OperatorModel? get currentOperator => _currentOperator;
  List<OperatorModel> get operators => _operators;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all operators
  Stream<List<OperatorModel>> getAllOperators() {
    return _operatorService.getAllOperators();
  }

  // Get operators by role
  Stream<List<OperatorModel>> getOperatorsByRole(OperatorRole role) {
    return _operatorService.getOperatorsByRole(role);
  }

  // Get operators by status
  Stream<List<OperatorModel>> getOperatorsByStatus(OperatorStatus status) {
    return _operatorService.getOperatorsByStatus(status);
  }

  // Get operators by store
  Stream<List<OperatorModel>> getOperatorsByStore(String storeId) {
    return _operatorService.getOperatorsByStore(storeId);
  }

  // Get operator management screen (for super operators)
  // Note: This method is deprecated - use navigation instead
  // Widget getOperatorManagementScreen() {
  //   return const OperatorManagementScreen();
  // }

  // Get current operator
  Future<OperatorModel?> getCurrentOperator() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentOperator = await _operatorService.getCurrentOperator();

      _isLoading = false;
      notifyListeners();

      return _currentOperator;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get operator by ID
  Future<OperatorModel?> getOperatorById(String operatorId) async {
    try {
      return await _operatorService.getOperatorById(operatorId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get operator by phone
  Future<OperatorModel?> getOperatorByPhone(String phoneNumber) async {
    try {
      return await _operatorService.getOperatorByPhone(phoneNumber);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Create new operator
  Future<OperatorModel> createOperator({
    required String phoneNumber,
    required String name,
    required String email,
    required OperatorRole role,
    String? storeId,
    String? assignedBy,
    Map<String, dynamic>? permissions,
    String? profileImageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final operator = await _operatorService.createOperator(
        phoneNumber: phoneNumber,
        name: name,
        email: email,
        role: role,
        storeId: storeId,
        assignedBy: assignedBy,
        permissions: permissions,
        profileImageUrl: profileImageUrl,
      );

      _isLoading = false;
      notifyListeners();

      return operator;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update operator
  Future<void> updateOperator(OperatorModel operator) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _operatorService.updateOperator(operator);

      // Update current operator if it's the same
      if (_currentOperator?.id == operator.id) {
        _currentOperator = operator;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update operator status
  Future<void> updateOperatorStatus(String operatorId, OperatorStatus status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _operatorService.updateOperatorStatus(operatorId, status);

      // Update current operator if it's the same
      if (_currentOperator?.id == operatorId) {
        _currentOperator = _currentOperator?.copyWith(status: status);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete operator
  Future<void> deleteOperator(String operatorId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _operatorService.deleteOperator(operatorId);

      // Remove from current operator if it's the same
      if (_currentOperator?.id == operatorId) {
        _currentOperator = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Authenticate operator
  Future<OperatorModel?> authenticateOperator(String phoneNumber, String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final operator = await _operatorService.authenticateOperator(phoneNumber, otp);

      if (operator != null) {
        _currentOperator = operator;
      }

      _isLoading = false;
      notifyListeners();

      return operator;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _operatorService.sendOTP(phoneNumber);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Verify OTP
  Future<OperatorModel?> verifyOTP(String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final operator = await _operatorService.verifyOTP(otp);

      if (operator != null) {
        _currentOperator = operator;
      }

      _isLoading = false;
      notifyListeners();

      return operator;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _operatorService.signOutOperator();

      _currentOperator = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Check if current operator has permission
  bool hasPermission(String permission) {
    return _currentOperator?.hasPermission(permission) ?? false;
  }

  // Check if current operator has role
  bool hasRole(OperatorRole role) {
    return _currentOperator?.role == role;
  }

  // Check if current operator is super operator
  bool get isSuperOperator {
    return _currentOperator?.isSuperOperator ?? false;
  }

  // Check if current operator is regular operator
  bool get isRegularOperator {
    return _currentOperator?.isRegularOperator ?? false;
  }

  // Check if current operator is active
  bool get isActive {
    return _currentOperator?.isActive ?? false;
  }

  // Get operator statistics
  Future<Map<String, dynamic>> getOperatorStats(String operatorId) async {
    try {
      return await _operatorService.getOperatorStats(operatorId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Search operators
  Future<List<OperatorModel>> searchOperators(String query) async {
    try {
      return await _operatorService.searchOperators(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update last login
  Future<void> updateLastLogin() async {
    if (_currentOperator != null) {
      try {
        await _operatorService.updateLastLogin(_currentOperator!.id);
      } catch (e) {
        // Don't throw error for last login updates
        print('Failed to update last login: $e');
      }
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