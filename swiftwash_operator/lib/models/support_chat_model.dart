import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class SupportChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String message;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? customerId;
  final String? operatorId;

  SupportChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.type,
    required this.status,
    required this.timestamp,
    this.customerId,
    this.operatorId,
  });

  factory SupportChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      message: data['message'] ?? '',
      type: MessageType.values[data['type'] ?? 0],
      status: MessageStatus.values[data['status'] ?? 0],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      customerId: data['customerId'],
      operatorId: data['operatorId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type.index,
      'status': status.index,
      'timestamp': Timestamp.fromDate(timestamp),
      'customerId': customerId,
      'operatorId': operatorId,
    };
  }

  SupportChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? message,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? customerId,
    String? operatorId,
  }) {
    return SupportChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      customerId: customerId ?? this.customerId,
      operatorId: operatorId ?? this.operatorId,
    );
  }
}

class SupportChatSession {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? operatorId;
  final String status; // 'waiting', 'active', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<String> messageIds;

  SupportChatSession({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.operatorId,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    required this.messageIds,
  });

  factory SupportChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportChatSession(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      customerPhone: data['customerPhone'] ?? '',
      operatorId: data['operatorId'],
      status: data['status'] ?? 'waiting',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      messageIds: List<String>.from(data['messageIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'operatorId': operatorId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'messageIds': messageIds,
    };
  }

  SupportChatSession copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? operatorId,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    List<String>? messageIds,
  }) {
    return SupportChatSession(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      operatorId: operatorId ?? this.operatorId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      messageIds: messageIds ?? this.messageIds,
    );
  }
}