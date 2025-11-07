import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/models/order_status_model.dart';

class EnhancedOrderModel {
  final String id;
  final String orderId;
  final String userId;
  final String serviceName;
  final double itemTotal;
  final double swiftCharge;
  final double discount;
  final double finalTotal;
  final OrderStatus status;
  final OrderStatus? currentProcessingStatus;
  final Map<String, dynamic>? address;
  final List<Map<String, dynamic>> items;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final String? notes;
  final Map<String, dynamic>? customerInfo;
  final List<OrderStatusHistory> statusHistory;
  final List<ProcessingUpdate> processingHistory;

  EnhancedOrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.serviceName,
    required this.itemTotal,
    required this.swiftCharge,
    required this.discount,
    required this.finalTotal,
    required this.status,
    this.currentProcessingStatus,
    this.address,
    required this.items,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.createdAt,
    this.lastUpdated,
    this.cancelReason,
    this.cancelledAt,
    this.notes,
    this.customerInfo,
    required this.statusHistory,
    required this.processingHistory,
  });

  factory EnhancedOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EnhancedOrderModel(
      id: doc.id,
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      serviceName: data['serviceName'] ?? 'Laundry Service',
      itemTotal: (data['itemTotal'] ?? 0).toDouble(),
      swiftCharge: (data['swiftCharge'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      finalTotal: (data['finalTotal'] ?? 0).toDouble(),
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      currentProcessingStatus: data['currentProcessingStatus'] != null
          ? OrderStatus.fromString(data['currentProcessingStatus'])
          : null,
      address: data['address'] as Map<String, dynamic>?,
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      cancelReason: data['cancelReason'],
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      customerInfo: data['customerInfo'] as Map<String, dynamic>?,
      statusHistory: [], // Will be loaded separately
      processingHistory: [], // Will be loaded separately
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'userId': userId,
      'serviceName': serviceName,
      'itemTotal': itemTotal,
      'swiftCharge': swiftCharge,
      'discount': discount,
      'finalTotal': finalTotal,
      'status': status.name,
      'currentProcessingStatus': currentProcessingStatus?.name,
      'address': address,
      'items': items,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'cancelReason': cancelReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'notes': notes,
      'customerInfo': customerInfo,
    };
  }

  // Helper methods
  String get formattedAddress {
    if (address == null) return '';
    return '${address!['street']}, ${address!['area']}, ${address!['city']} - ${address!['pincode']}';
  }

  String get itemsSummary {
    return items.map((item) => '${item['quantity']}x ${item['name']}').join(', ');
  }

  bool get isActive {
    return status.allowsCustomerActions && status != OrderStatus.cancelled;
  }

  bool get canTrack {
    return status.showsTrackingMap;
  }

  bool get canCancel {
    return [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.driverAssigned,
    ].contains(status);
  }

  String get statusDisplayName => status.displayName;
  String get statusDescription => status.description;
  IconData get statusIcon => status.icon;
  Color get statusColor => status.color;
  double get progress => status.progress;
  String get estimatedTime => status.estimatedTimeRemaining;
}

class OrderStatusHistory {
  final String id;
  final OrderStatus status;
  final DateTime timestamp;
  final String changedBy;
  final String? reason;
  final Map<String, dynamic>? metadata;

  OrderStatusHistory({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.changedBy,
    this.reason,
    this.metadata,
  });

  factory OrderStatusHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderStatusHistory(
      id: doc.id,
      status: OrderStatus.fromString(data['status'] ?? ''),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changedBy: data['changedBy'] ?? 'system',
      reason: data['reason'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}

class ProcessingUpdate {
  final String id;
  final String status;
  final DateTime timestamp;
  final String description;
  final String operatorId;
  final String? notes;
  final Map<String, dynamic>? metadata;

  ProcessingUpdate({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.description,
    required this.operatorId,
    this.notes,
    this.metadata,
  });

  factory ProcessingUpdate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProcessingUpdate(
      id: doc.id,
      status: data['status'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      operatorId: data['operatorId'] ?? 'system',
      notes: data['notes'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}
