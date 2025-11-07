import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superAdmin('Super Admin', 'Full system access'),
  storeAdmin('Store Admin', 'Manage specific stores'),
  supportAdmin('Support Admin', 'Customer support management');

  const AdminRole(this.displayName, this.description);

  final String displayName;
  final String description;
}

enum AdminStatus {
  active('Active', 'Admin is active'),
  inactive('Inactive', 'Admin is deactivated'),
  suspended('Suspended', 'Admin access suspended');

  const AdminStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}

class AdminUserModel {
  final String id;
  final String username;
  final String name;
  final String phone;
  final AdminRole role;
  final AdminStatus status;
  final List<String> managedStoreIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? profileImageUrl;
  final Map<String, dynamic> permissions;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  AdminUserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.managedStoreIds,
    required this.createdAt,
    this.lastLoginAt,
    this.profileImageUrl,
    required this.permissions,
    required this.isEmailVerified,
    required this.isPhoneVerified,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUserModel(
      id: doc.id,
      username: data['username'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: AdminRole.values[data['role'] ?? 0],
      status: AdminStatus.values[data['status'] ?? 0],
      managedStoreIds: List<String>.from(data['managedStoreIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      profileImageUrl: data['profileImageUrl'],
      permissions: data['permissions'] ?? {},
      isEmailVerified: data['isEmailVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'name': name,
      'phone': phone,
      'role': role.index,
      'status': status.index,
      'managedStoreIds': managedStoreIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'profileImageUrl': profileImageUrl,
      'permissions': permissions,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  AdminUserModel copyWith({
    String? id,
    String? username,
    String? name,
    String? phone,
    AdminRole? role,
    AdminStatus? status,
    List<String>? managedStoreIds,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? profileImageUrl,
    Map<String, dynamic>? permissions,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      managedStoreIds: managedStoreIds ?? this.managedStoreIds,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      permissions: permissions ?? this.permissions,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  bool get isActive => status == AdminStatus.active;

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  bool get canManageStores => isSuperAdmin || role == AdminRole.storeAdmin;

  bool get canManageSupport => isSuperAdmin || role == AdminRole.supportAdmin;

  bool get canCreateOperators => isSuperAdmin || (role == AdminRole.storeAdmin && managedStoreIds.isNotEmpty);

  bool get canViewAllStores => isSuperAdmin;

  String get roleDescription {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Full system access with all permissions';
      case AdminRole.storeAdmin:
        return 'Can manage assigned stores and operators';
      case AdminRole.supportAdmin:
        return 'Can manage customer support and communications';
    }
  }

  Map<String, dynamic> get adminInfo => {
    'name': name,
    'username': username,
    'phone': phone,
    'role': role.displayName,
    'status': status.displayName,
    'stores': managedStoreIds.length,
    'lastLogin': lastLoginAt?.toString() ?? 'Never',
  };
}