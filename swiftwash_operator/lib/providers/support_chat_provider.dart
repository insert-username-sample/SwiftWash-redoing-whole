import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/support_chat_model.dart';

class SupportChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<SupportChatSession> _activeChats = [];
  SupportChatSession? _currentChat;
  bool _isLoading = false;
  String? _error;

  List<SupportChatSession> get activeChats => _activeChats;
  SupportChatSession? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<SupportChatSession>> get activeChatsStream {
    final operatorId = _auth.currentUser?.uid;
    if (operatorId == null) return Stream.value([]);

    return _firestore
        .collection('support_chats')
        .where('status', whereIn: ['waiting', 'active'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => SupportChatSession.fromFirestore(doc))
              .toList();
          _updateActiveChats(chats);
          return chats;
        });
  }

  Stream<List<SupportChatSession>> get waitingChatsStream {
    return _firestore
        .collection('support_chats')
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportChatSession.fromFirestore(doc))
            .toList());
  }

  Stream<List<SupportChatMessage>> get messagesStream {
    if (_currentChat == null) return Stream.value([]);

    return _firestore
        .collection('support_messages')
        .where('chatId', isEqualTo: _currentChat!.id)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportChatMessage.fromFirestore(doc))
            .toList());
  }

  void _updateActiveChats(List<SupportChatSession> chats) {
    _activeChats = chats;
    notifyListeners();
  }

  Future<void> loadActiveChats() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final operatorId = _auth.currentUser?.uid;
      if (operatorId == null) throw Exception('Operator not authenticated');

      final snapshot = await _firestore
          .collection('support_chats')
          .where('operatorId', isEqualTo: operatorId)
          .where('status', whereIn: ['waiting', 'active'])
          .orderBy('createdAt', descending: true)
          .get();

      _activeChats = snapshot.docs
          .map((doc) => SupportChatSession.fromFirestore(doc))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectChat(SupportChatSession chat) async {
    _currentChat = chat;
    notifyListeners();

    // Mark chat as active if it was waiting
    if (chat.status == 'waiting') {
      await _updateChatStatus(chat.id, 'active');
    }
  }

  Future<void> sendMessage(String message) async {
    if (_currentChat == null || message.trim().isEmpty) return;

    try {
      final operatorId = _auth.currentUser?.uid;
      if (operatorId == null) throw Exception('Operator not authenticated');

      final messageId = _firestore.collection('support_messages').doc().id;

      final chatMessage = SupportChatMessage(
        id: messageId,
        chatId: _currentChat!.id,
        senderId: operatorId,
        senderName: 'Store Operator',
        message: message.trim(),
        type: MessageType.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        customerId: _currentChat!.customerId,
        operatorId: operatorId,
      );

      // Add message to Firestore
      await _firestore
          .collection('support_messages')
          .doc(messageId)
          .set(chatMessage.toFirestore());

      // Update message status to sent
      await _firestore
          .collection('support_messages')
          .doc(messageId)
          .update({'status': MessageStatus.sent.index});

      // Update chat's message list
      await _updateChatMessageList(_currentChat!.id, messageId);

    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  Future<void> _updateChatMessageList(String chatId, String messageId) async {
    await _firestore.collection('support_chats').doc(chatId).update({
      'messageIds': FieldValue.arrayUnion([messageId]),
    });
  }

  Future<void> _updateChatStatus(String chatId, String status) async {
    await _firestore.collection('support_chats').doc(chatId).update({
      'status': status,
      'operatorId': _auth.currentUser?.uid,
    });
  }

  Future<void> resolveChat() async {
    if (_currentChat == null) return;

    try {
      await _firestore.collection('support_chats').doc(_currentChat!.id).update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      _currentChat = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to resolve chat: $e';
      notifyListeners();
    }
  }

  Future<void> closeChat() async {
    if (_currentChat == null) return;

    try {
      await _firestore.collection('support_chats').doc(_currentChat!.id).update({
        'status': 'closed',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      _currentChat = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to close chat: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentChat() {
    _currentChat = null;
    notifyListeners();
  }
}