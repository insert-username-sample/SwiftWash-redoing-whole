import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createSupportRequest({
    required String customerName,
    required String customerPhone,
    String? initialMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = _firestore.collection('support_chats').doc().id;

      // Create support chat session
      await _firestore.collection('support_chats').doc(chatId).set({
        'id': chatId,
        'customerId': user.uid,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'messageIds': initialMessage != null ? [chatId + '_initial'] : [],
      });

      // Add initial message if provided
      if (initialMessage != null && initialMessage.trim().isNotEmpty) {
        final messageId = chatId + '_initial';
        await _firestore.collection('support_messages').doc(messageId).set({
          'id': messageId,
          'chatId': chatId,
          'senderId': user.uid,
          'senderName': customerName,
          'message': initialMessage.trim(),
          'type': 0, // text
          'status': 1, // sent
          'timestamp': FieldValue.serverTimestamp(),
          'customerId': user.uid,
        });
      }

      return chatId;
    } catch (e) {
      throw Exception('Failed to create support request: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageId = _firestore.collection('support_messages').doc().id;

      await _firestore.collection('support_messages').doc(messageId).set({
        'id': messageId,
        'chatId': chatId,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Customer',
        'message': message.trim(),
        'type': 0, // text
        'status': 1, // sent
        'timestamp': FieldValue.serverTimestamp(),
        'customerId': user.uid,
      });

      // Update chat's message list
      await _firestore.collection('support_chats').doc(chatId).update({
        'messageIds': FieldValue.arrayUnion([messageId]),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getSupportChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('support_chats')
        .where('customerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    return _firestore
        .collection('support_messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  Future<void> updateChatStatus(String chatId, String status) async {
    await _firestore.collection('support_chats').doc(chatId).update({
      'status': status,
      'resolvedAt': status == 'resolved' ? FieldValue.serverTimestamp() : null,
    });
  }
}