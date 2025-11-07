import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final String? driverId;
  final String status;
  final String serviceName;
  final double totalAmount;
  final Map<String, dynamic> address;
  final Map<String, dynamic>? customerInfo;
  final Timestamp createdAt;
  final Timestamp? pickupTime;
  final Timestamp? deliveryTime;
  final List<String>? serviceItems;
  final String? specialInstructions;
  final String priority;
  final Map<String, dynamic>? location;
  final List<Map<String, dynamic>>? processingStatuses; // Detailed processing timeline

  OrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    this.driverId,
    required this.status,
    required this.serviceName,
    required this.totalAmount,
    required this.address,
    this.customerInfo,
    required this.createdAt,
    this.pickupTime,
    this.deliveryTime,
    this.serviceItems,
    this.specialInstructions,
    this.priority = 'normal',
    this.location,
    this.processingStatuses,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      driverId: data['driverId'],
      status: data['status'] ?? 'new',
      serviceName: data['serviceName'] ?? 'Unknown Service',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      address: data['address'] ?? {},
      customerInfo: data['customerInfo'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      pickupTime: data['pickupTime'],
      deliveryTime: data['deliveryTime'],
      serviceItems: List<String>.from(data['serviceItems'] ?? []),
      specialInstructions: data['specialInstructions'],
      priority: data['priority'] ?? 'normal',
      location: data['location'],
      processingStatuses: List<Map<String, dynamic>>.from(data['processingStatuses'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'driverId': driverId,
      'status': status,
      'serviceName': serviceName,
      'totalAmount': totalAmount,
      'address': address,
      'customerInfo': customerInfo,
      'createdAt': createdAt,
      'pickupTime': pickupTime,
      'deliveryTime': deliveryTime,
      'serviceItems': serviceItems,
      'specialInstructions': specialInstructions,
      'priority': priority,
      'location': location,
      'processingStatuses': processingStatuses,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  OrderModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? driverId,
    String? status,
    String? serviceName,
    double? totalAmount,
    Map<String, dynamic>? address,
    Map<String, dynamic>? customerInfo,
    Timestamp? createdAt,
    Timestamp? pickupTime,
    Timestamp? deliveryTime,
    List<String>? serviceItems,
    String? specialInstructions,
    String? priority,
    Map<String, dynamic>? location,
    List<Map<String, dynamic>>? processingStatuses,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      serviceName: serviceName ?? this.serviceName,
      totalAmount: totalAmount ?? this.totalAmount,
      address: address ?? this.address,
      customerInfo: customerInfo ?? this.customerInfo,
      createdAt: createdAt ?? this.createdAt,
      pickupTime: pickupTime ?? this.pickupTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      serviceItems: serviceItems ?? this.serviceItems,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      processingStatuses: processingStatuses ?? this.processingStatuses,
    );
  }

  bool get isNew => status == 'new';
  bool get isProcessing => status == 'processing';
  bool get isOutForPickup => status == 'out_for_pickup';
  bool get isPickedUp => status == 'picked_up';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String getStatusText() {
    switch (status) {
      case 'new':
        return 'New Order';
      case 'processing':
        return 'Processing';
      case 'out_for_pickup':
        return 'Out for Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String getFormattedAddress() {
    final addr = address;
    if (addr.isEmpty) return 'Address not available';

    final parts = <String>[];
    if (addr['street'] != null) parts.add(addr['street']);
    if (addr['area'] != null) parts.add(addr['area']);
    if (addr['city'] != null) parts.add(addr['city']);

    return parts.join(', ');
  }
}
