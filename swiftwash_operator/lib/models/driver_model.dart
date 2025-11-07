import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status; // 'available', 'busy', 'offline'
  final GeoPoint? currentLocation;
  final Timestamp? lastUpdated;
  final int totalOrders;
  final double rating;
  final String? vehicleType;
  final String? vehicleNumber;
  final Map<String, dynamic>? profile;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.currentLocation,
    this.lastUpdated,
    this.totalOrders = 0,
    this.rating = 0.0,
    this.vehicleType,
    this.vehicleNumber,
    this.profile,
  });

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Driver',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      status: data['status'] ?? 'offline',
      currentLocation: data['currentLocation'],
      lastUpdated: data['lastUpdated'],
      totalOrders: data['totalOrders'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      vehicleType: data['vehicleType'],
      vehicleNumber: data['vehicleNumber'],
      profile: data['profile'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'currentLocation': currentLocation,
      'lastUpdated': lastUpdated ?? Timestamp.now(),
      'totalOrders': totalOrders,
      'rating': rating,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'profile': profile,
    };
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? status,
    GeoPoint? currentLocation,
    Timestamp? lastUpdated,
    int? totalOrders,
    double? rating,
    String? vehicleType,
    String? vehicleNumber,
    Map<String, dynamic>? profile,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalOrders: totalOrders ?? this.totalOrders,
      rating: rating ?? this.rating,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      profile: profile ?? this.profile,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isBusy => status == 'busy';
  bool get isOffline => status == 'offline';

  String getStatusText() {
    switch (status) {
      case 'available':
        return 'Available';
      case 'busy':
        return 'Busy';
      case 'offline':
        return 'Offline';
      default:
        return 'Unknown';
    }
  }

  String getShortName() {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0]} ${names[1][0]}.';
    }
    return name;
  }
}
