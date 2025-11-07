import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreStatus {
  active('Active', 'Store is operational'),
  inactive('Inactive', 'Store is temporarily closed'),
  pending('Pending', 'Store awaiting approval'),
  suspended('Suspended', 'Store access suspended');

  const StoreStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}

class StoreModel {
  final String id;
  final String storeName;
  final String storeCode;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final Map<String, dynamic> location;
  final StoreStatus status;
  final String adminUsername;
  final String adminPassword;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> operatorIds;
  final Map<String, dynamic> settings;
  final String? logoUrl;
  final String? description;

  StoreModel({
    required this.id,
    required this.storeName,
    required this.storeCode,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.location,
    required this.status,
    required this.adminUsername,
    required this.adminPassword,
    required this.createdAt,
    this.updatedAt,
    required this.operatorIds,
    required this.settings,
    this.logoUrl,
    this.description,
  });

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      storeName: data['storeName'] ?? '',
      storeCode: data['storeCode'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      location: data['location'] ?? {},
      status: StoreStatus.values[data['status'] ?? 0],
      adminUsername: data['adminUsername'] ?? '',
      adminPassword: data['adminPassword'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      operatorIds: List<String>.from(data['operatorIds'] ?? []),
      settings: data['settings'] ?? {},
      logoUrl: data['logoUrl'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'status': status.index,
      'adminUsername': adminUsername,
      'adminPassword': adminPassword,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'operatorIds': operatorIds,
      'settings': settings,
      'logoUrl': logoUrl,
      'description': description,
    };
  }

  StoreModel copyWith({
    String? id,
    String? storeName,
    String? storeCode,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    String? address,
    String? city,
    String? state,
    String? pincode,
    Map<String, dynamic>? location,
    StoreStatus? status,
    String? adminUsername,
    String? adminPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? operatorIds,
    Map<String, dynamic>? settings,
    String? logoUrl,
    String? description,
  }) {
    return StoreModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeCode: storeCode ?? this.storeCode,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      location: location ?? this.location,
      status: status ?? this.status,
      adminUsername: adminUsername ?? this.adminUsername,
      adminPassword: adminPassword ?? this.adminPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      operatorIds: operatorIds ?? this.operatorIds,
      settings: settings ?? this.settings,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
    );
  }

  String get fullAddress => '$address, $city, $state $pincode';

  bool get isActive => status == StoreStatus.active;

  bool get canAcceptOrders => isActive && operatorIds.isNotEmpty;

  String get statusDescription {
    switch (status) {
      case StoreStatus.active:
        return 'Store is operational and accepting orders';
      case StoreStatus.inactive:
        return 'Store is temporarily closed';
      case StoreStatus.pending:
        return 'Store is pending approval';
      case StoreStatus.suspended:
        return 'Store access has been suspended';
    }
  }

  Map<String, dynamic> get storeInfo => {
    'name': storeName,
    'code': storeCode,
    'owner': ownerName,
    'phone': ownerPhone,
    'email': ownerEmail,
    'address': fullAddress,
    'status': status.displayName,
    'operators': operatorIds.length,
  };
}