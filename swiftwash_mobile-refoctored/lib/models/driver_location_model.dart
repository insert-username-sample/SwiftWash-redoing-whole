class DriverLocationModel {
  final String id;
  final String driverId;
  final String? orderId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime timestamp;
  final DateTime createdAt;

  DriverLocationModel({
    required this.id,
    required this.driverId,
    this.orderId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    required this.timestamp,
    required this.createdAt,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      orderId: json['order_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'order_id': orderId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
