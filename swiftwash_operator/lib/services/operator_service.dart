import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftwash_operator/models/operator_model.dart';

class OperatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'operators';

  // Get current operator
  Future<OperatorModel?> getCurrentOperator() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection(_collection).doc(user.uid).get();
      if (doc.exists) {
        return OperatorModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current operator: $e');
    }
  }

  // Get operator by ID
  Future<OperatorModel?> getOperatorById(String operatorId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(operatorId).get();
      if (doc.exists) {
        return OperatorModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get operator: $e');
    }
  }

  // Get operator by phone number
  Future<OperatorModel?> getOperatorByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return OperatorModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get operator by phone: $e');
    }
  }

  // Get all operators
  Stream<List<OperatorModel>> getAllOperators() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => OperatorModel.fromFirestore(doc)).toList();
    });
  }

  // Get operators by role
  Stream<List<OperatorModel>> getOperatorsByRole(OperatorRole role) {
    return _firestore
        .collection(_collection)
        .where('role', isEqualTo: role.index)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OperatorModel.fromFirestore(doc)).toList();
    });
  }

  // Get operators by status
  Stream<List<OperatorModel>> getOperatorsByStatus(OperatorStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.index)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OperatorModel.fromFirestore(doc)).toList();
    });
  }

  // Get operators by store
  Stream<List<OperatorModel>> getOperatorsByStore(String storeId) {
    return _firestore
        .collection(_collection)
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OperatorModel.fromFirestore(doc)).toList();
    });
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
      // Check if operator already exists
      final existingOperator = await getOperatorByPhone(phoneNumber);
      if (existingOperator != null) {
        throw Exception('Operator with this phone number already exists');
      }

      final operatorId = _firestore.collection(_collection).doc().id;
      final now = DateTime.now();

      final operatorData = {
        'phoneNumber': phoneNumber,
        'name': name,
        'email': email,
        'role': role.index,
        'status': OperatorStatus.pending.index,
        'storeId': storeId,
        'assignedBy': assignedBy,
        'createdAt': Timestamp.fromDate(now),
        'permissions': permissions ?? _getDefaultPermissions(role),
        'profileImageUrl': profileImageUrl,
      };

      await _firestore.collection(_collection).doc(operatorId).set(operatorData);

      final doc = await _firestore.collection(_collection).doc(operatorId).get();
      return OperatorModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create operator: $e');
    }
  }

  // Update operator
  Future<void> updateOperator(OperatorModel operator) async {
    try {
      final updateData = operator.toFirestore();
      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection(_collection).doc(operator.id).update(updateData);
    } catch (e) {
      throw Exception('Failed to update operator: $e');
    }
  }

  // Update operator status
  Future<void> updateOperatorStatus(String operatorId, OperatorStatus status) async {
    try {
      await _firestore.collection(_collection).doc(operatorId).update({
        'status': status.index,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update operator status: $e');
    }
  }

  // Update operator last login
  Future<void> updateLastLogin(String operatorId) async {
    try {
      await _firestore.collection(_collection).doc(operatorId).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Don't throw error for last login updates
      print('Failed to update last login: $e');
    }
  }

  // Delete operator
  Future<void> deleteOperator(String operatorId) async {
    try {
      await _firestore.collection(_collection).doc(operatorId).delete();
    } catch (e) {
      throw Exception('Failed to delete operator: $e');
    }
  }

  // Authenticate operator with phone and OTP
  Future<OperatorModel?> authenticateOperator(String phoneNumber, String otp) async {
    try {
      // First verify the phone number with Firebase Auth
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _getVerificationId(),
        smsCode: otp,
      );

      final authResult = await _auth.signInWithCredential(phoneCredential);
      final user = authResult.user;

      if (user == null) {
        throw Exception('Authentication failed');
      }

      // Get or create operator
      OperatorModel? operator = await getOperatorByPhone(phoneNumber);

      if (operator == null) {
        // Create new operator if doesn't exist
        operator = await createOperator(
          phoneNumber: phoneNumber,
          name: '', // Will be updated later
          email: '', // Will be updated later
          role: OperatorRole.regularOperator,
        );
      }

      // Update last login
      await updateLastLogin(operator.id);

      return operator;
    } catch (e) {
      throw Exception('Failed to authenticate operator: $e');
    }
  }

  // Sign out operator
  Future<void> signOutOperator() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Send OTP for phone verification
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _setVerificationId(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _setVerificationId(verificationId);
        },
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP
  Future<OperatorModel?> verifyOTP(String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _getVerificationId(),
        smsCode: otp,
      );

      final authResult = await _auth.signInWithCredential(credential);
      final user = authResult.user;

      if (user == null) {
        throw Exception('OTP verification failed');
      }

      // Get operator by phone number
      final phoneNumber = user.phoneNumber;
      if (phoneNumber == null) {
        throw Exception('Phone number not available');
      }

      final operator = await getOperatorByPhone(phoneNumber);
      if (operator != null) {
        await updateLastLogin(operator.id);
      }

      return operator;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Get operator statistics
  Future<Map<String, dynamic>> getOperatorStats(String operatorId) async {
    try {
      // This would typically involve querying related collections
      // For now, return basic stats
      return {
        'totalOrders': 0,
        'completedOrders': 0,
        'pendingOrders': 0,
        'rating': 0.0,
        'earnings': 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get operator stats: $e');
    }
  }

  // Search operators
  Future<List<OperatorModel>> searchOperators(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) => OperatorModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to search operators: $e');
    }
  }

  // Helper methods
  Map<String, dynamic> _getDefaultPermissions(OperatorRole role) {
    switch (role) {
      case OperatorRole.superOperator:
        return {
          'manage_operators': true,
          'manage_stores': true,
          'view_all_orders': true,
          'manage_settings': true,
          'view_analytics': true,
        };
      case OperatorRole.regularOperator:
        return {
          'manage_own_orders': true,
          'view_assigned_orders': true,
          'update_profile': true,
        };
    }
  }

  // Temporary storage for verification ID (in production, use secure storage)
  static String? _verificationId;
  String _getVerificationId() => _verificationId ?? '';
  void _setVerificationId(String id) => _verificationId = id;
}