import 'package:cloud_firestore/cloud_firestore.dart';

enum OperatorRole {
  superOperator,
  regularOperator,
}

enum OperatorStatus {
  active,
  inactive,
  suspended,
  pending,
}

class OperatorModel {
  final String id;
  final String phoneNumber;
  final String name;
  final String email;
  final OperatorRole role;
  final OperatorStatus status;
  final String? storeId;
  final String? assignedBy;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;
  final Map<String, dynamic>? permissions;
  final String? profileImageUrl;
  final String? deviceToken;
  final Map<String, dynamic>? metadata;

  OperatorModel({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.storeId,
    this.assignedBy,
    required this.createdAt,
    this.lastLogin,
    this.updatedAt,
    this.permissions,
    this.profileImageUrl,
    this.deviceToken,
    this.metadata,
  });

  factory OperatorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OperatorModel(
      id: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: OperatorRole.values[data['role'] ?? 0],
      status: OperatorStatus.values[data['status'] ?? 0],
      storeId: data['storeId'],
      assignedBy: data['assignedBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null ? (data['lastLogin'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      permissions: data['permissions'],
      profileImageUrl: data['profileImageUrl'],
      deviceToken: data['deviceToken'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'role': role.index,
      'status': status.index,
      'storeId': storeId,
      'assignedBy': assignedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'permissions': permissions,
      'profileImageUrl': profileImageUrl,
      'deviceToken': deviceToken,
      'metadata': metadata,
    };
  }

  OperatorModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    OperatorRole? role,
    OperatorStatus? status,
    String? storeId,
    String? assignedBy,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    Map<String, dynamic>? permissions,
    String? profileImageUrl,
    String? deviceToken,
    Map<String, dynamic>? metadata,
  }) {
    return OperatorModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      storeId: storeId ?? this.storeId,
      assignedBy: assignedBy ?? this.assignedBy,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      permissions: permissions ?? this.permissions,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      deviceToken: deviceToken ?? this.deviceToken,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isSuperOperator => role == OperatorRole.superOperator;
  bool get isRegularOperator => role == OperatorRole.regularOperator;
  bool get isActive => status == OperatorStatus.active;
  bool get isSuspended => status == OperatorStatus.suspended;
  bool get isPending => status == OperatorStatus.pending;

  bool hasPermission(String permission) {
    return permissions?[permission] == true;
  }

  String get roleDisplayName {
    switch (role) {
      case OperatorRole.superOperator:
        return 'Super Operator';
      case OperatorRole.regularOperator:
        return 'Regular Operator';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case OperatorStatus.active:
        return 'Active';
      case OperatorStatus.inactive:
        return 'Inactive';
      case OperatorStatus.suspended:
        return 'Suspended';
      case OperatorStatus.pending:
        return 'Pending';
    }
  }

  @override
  String toString() {
    return 'OperatorModel(id: $id, name: $name, phone: $phoneNumber, role: $role, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperatorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}