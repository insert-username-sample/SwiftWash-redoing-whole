import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String userId;
  final String planName;
  final String status; // 'active', 'expired', 'cancelled', 'trial'
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String currency;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.currency,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      planName: map['planName'] ?? '',
      status: map['status'] ?? 'inactive',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'INR',
      paymentId: map['paymentId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planName': planName,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'amount': amount,
      'currency': currency,
      'paymentId': paymentId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isActive {
    return status == 'active' && endDate.isAfter(DateTime.now());
  }

  bool get isExpired {
    return status == 'expired' || endDate.isBefore(DateTime.now());
  }

  bool get isTrial {
    return status == 'trial';
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planName,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    String? currency,
    String? paymentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planName: planName ?? this.planName,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentId: paymentId ?? this.paymentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
  });

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly Premium',
      description: 'Perfect for regular users',
      price: 99.0,
      currency: 'INR',
      durationDays: 30,
      features: [
        'Priority booking',
        'Express delivery',
        '24/7 customer support',
        'Free pickup & delivery',
        'Real-time tracking',
      ],
    ),
    SubscriptionPlan(
      id: 'quarterly',
      name: 'Quarterly Premium',
      description: 'Best value for 3 months',
      price: 249.0,
      currency: 'INR',
      durationDays: 90,
      features: [
        'All Monthly features',
        '15% discount on services',
        'Dedicated account manager',
        'Monthly laundry reports',
      ],
    ),
    SubscriptionPlan(
      id: 'yearly',
      name: 'Yearly Premium',
      description: 'Maximum savings annually',
      price: 899.0,
      currency: 'INR',
      durationDays: 365,
      features: [
        'All Quarterly features',
        '25% discount on all services',
        'Free emergency services',
        'VIP customer support',
        'Custom service scheduling',
      ],
    ),
  ];
}