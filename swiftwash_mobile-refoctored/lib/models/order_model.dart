class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String? driverId;
  final String? storeId;
  final String pickupAddressId;
  final String deliveryAddressId;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? scheduledPickupTime;
  final DateTime? scheduledDeliveryTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDeliveryTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.driverId,
    this.storeId,
    required this.pickupAddressId,
    required this.deliveryAddressId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.scheduledPickupTime,
    this.scheduledDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      driverId: json['driver_id'] as String?,
      storeId: json['store_id'] as String?,
      pickupAddressId: json['pickup_address_id'] as String,
      deliveryAddressId: json['delivery_address_id'] as String,
      status: json['status'] as String? ?? 'pending',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      scheduledPickupTime: json['scheduled_pickup_time'] != null
          ? DateTime.parse(json['scheduled_pickup_time'] as String)
          : null,
      scheduledDeliveryTime: json['scheduled_delivery_time'] != null
          ? DateTime.parse(json['scheduled_delivery_time'] as String)
          : null,
      actualPickupTime: json['actual_pickup_time'] != null
          ? DateTime.parse(json['actual_pickup_time'] as String)
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'driver_id': driverId,
      'store_id': storeId,
      'pickup_address_id': pickupAddressId,
      'delivery_address_id': deliveryAddressId,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'scheduled_pickup_time': scheduledPickupTime?.toIso8601String(),
      'scheduled_delivery_time': scheduledDeliveryTime?.toIso8601String(),
      'actual_pickup_time': actualPickupTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final String? category;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.category,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
    };
  }
}
