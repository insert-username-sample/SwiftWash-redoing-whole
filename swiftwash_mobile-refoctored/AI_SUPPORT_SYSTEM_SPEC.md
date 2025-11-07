# SwiftWash AI Support System - Complete Specification
## Vertex AI Integration with Talk-to-Human Feature

### **Overview**
This document provides a comprehensive specification for implementing an AI-powered support system using Google Vertex AI (Gemini) with seamless escalation to human support, including phone number verification and admin app integration.

### **Business Requirements**
- ✅ **AI-First Support**: Vertex AI/Gemini for initial customer queries
- ✅ **Smart Escalation**: Talk-to-human feature with phone verification
- ✅ **Admin Integration**: Real-time notifications in admin app for calls
- ✅ **Phone Verification**: Validate customer phone numbers before calling
- ✅ **Call Logging**: Complete audit trail of all support interactions
- ✅ **Firebase Only**: No external APIs except Google Cloud services
- ✅ **Multi-language Support**: Handle multiple languages via AI

## **🤖 AI Support Architecture**

### **Vertex AI Integration**

#### **Firebase Cloud Function**
```javascript
// functions/ai_support_functions.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { VertexAI } = require('@google-cloud/vertexai');

exports.chatWithSwiftBot = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const { message, conversationId } = data;
  const userId = context.auth.uid;

  if (!message || typeof message !== 'string' || message.length > 1000) {
    throw new functions.https.HttpsError('invalid-argument', 'Valid message required (max 1000 chars)');
  }

  try {
    // Rate limiting check
    await checkRateLimit(userId, 'ai_chat');

    // Get conversation history for context
    const conversationHistory = await getConversationHistory(conversationId);

    // Initialize Vertex AI
    const vertexAI = new VertexAI({
      project: 'swiftwash-v0-1',
      location: 'us-central1',
    });

    const model = 'gemini-1.5-flash';
    const generativeModel = vertexAI.preview.getGenerativeModel({
      model: model,
      generationConfig: {
        maxOutputTokens: 2048,
        temperature: 0.7,
        topP: 0.95,
      },
      safetySettings: [
        {
          category: 'HARM_CATEGORY_HATE_SPEECH',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          category: 'HARM_CATEGORY_HARASSMENT',
          threshold: 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    });

    // Build context-aware prompt
    const systemPrompt = buildSystemPrompt(userId);
    const conversationContext = buildConversationContext(conversationHistory);

    const fullPrompt = `${systemPrompt}\n\n${conversationContext}\n\nUser: ${message}\n\nAssistant:`;

    // Generate AI response
    const requestData = {
      contents: [{ role: 'user', parts: [{ text: fullPrompt }] }],
    };

    const streamingResp = await generativeModel.generateContentStream(requestData);
    const aggregatedResponse = await streamingResp.response;
    const aiResponse = aggregatedResponse.candidates[0].content.parts[0].text;

    if (!aiResponse || aiResponse.length > 2000) {
      throw new functions.https.HttpsError('internal', 'AI response validation failed');
    }

    // Save conversation to Firestore
    await saveConversationMessage(conversationId, userId, message, aiResponse, 'ai');

    // Check if human escalation is needed
    const needsHuman = await analyzeNeedsHumanEscalation(message, aiResponse);

    return {
      success: true,
      response: aiResponse,
      conversationId: conversationId,
      needsHumanEscalation: needsHuman,
      suggestions: await generateQuickReplies(message, aiResponse)
    };

  } catch (error) {
    console.error('AI chat error:', error);
    throw new functions.https.HttpsError('internal', 'AI support temporarily unavailable');
  }
});

// Helper Functions
async function checkRateLimit(userId, type) {
  const rateLimitRef = admin.firestore()
    .collection('rate_limits')
    .doc(`${type}_${userId}_${Math.floor(Date.now() / 60000)}`);

  const rateLimitDoc = await rateLimitRef.get();

  if (rateLimitDoc.exists && rateLimitDoc.data().count >= 20) {
    throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded');
  }

  await rateLimitRef.set({
    count: (rateLimitDoc.exists ? rateLimitDoc.data().count : 0) + 1,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

function buildSystemPrompt(userId) {
  // Array of 25 realistic Indian names for support agents
  const supportAgentNames = [
    'Shreyas Patel', 'Priya Sharma', 'Rohit Kumar', 'Anjali Singh', 'Vikram Mehta',
    'Kavita Gupta', 'Arjun Reddy', 'Sneha Jain', 'Rahul Tiwari', 'Pooja Agarwal',
    'Amitabh Srivastava', 'Divya Kapoor', 'Suresh Menon', 'Meera Iyer', 'Rajesh Khurana',
    'Swati Deshpande', 'Manoj Choudhary', 'Neha Bhattacharya', 'Deepak Malhotra', 'Ritu Saxena',
    'Gautam Oberoi', 'Lakshmi Venkatesh', 'Naveen Krishnan', 'Rashmi Chatterjee', 'Vijay Rana'
  ];

  // Randomly select a name for this session
  const selectedAgentName = supportAgentNames[Math.floor(Math.random() * supportAgentNames.length)];

  return `You are SwiftBot, an AI assistant for SwiftWash laundry services. When escalating to human support, use the name "${selectedAgentName}" as the support agent who will call the customer.

CRITICAL TYPING ANIMATION REQUIREMENTS:
You must simulate human-like typing patterns that will be used for the typing animation:

FOR MESSAGES 1-5 WORDS:
- First reply: Type non-stop without any pauses
- Second reply: Stop twice (pause briefly after 2-3 words, then continue)
- Third reply: Stop once (pause briefly in the middle)
- Fourth reply: Type with a bit more variation (pause after 3-4 words, then finish)

FOR LONGER MESSAGES (6+ WORDS):
- Use multiple stops (3-5 pauses throughout the message)
- Randomly vary the pause durations (0.5-2 seconds)
- Continue typing after each pause at irregular intervals
- Make it feel like a real person thinking and typing naturally

TYPING PAUSE PATTERNS:
- Short pause: 0.3-0.8 seconds (quick thinking)
- Medium pause: 0.9-1.5 seconds (considering response)
- Long pause: 1.6-2.5 seconds (careful typing/formatting)

Your role:
- Answer questions about laundry services, pricing, and processes
- Help with order tracking and modifications
- Provide pickup/delivery information
- Handle complaints and issues professionally
- Escalate complex issues to human support

Guidelines:
- Be friendly, professional, and helpful
- Use simple, clear language
- If unsure about something, offer to connect to human support
- Never share internal business information
- Always prioritize customer satisfaction

Common scenarios to handle:
- Order status inquiries
- Service type explanations
- Pricing questions
- Address/delivery issues
- Quality concerns
- Cancellation requests`;
}

async function getConversationHistory(conversationId) {
  if (!conversationId) return [];

  const messagesSnapshot = await admin.firestore()
    .collection('support_conversations')
    .doc(conversationId)
    .collection('messages')
    .orderBy('timestamp', 'desc')
    .limit(10)
    .get();

  return messagesSnapshot.docs
    .map(doc => doc.data())
    .reverse();
}

function buildConversationContext(history) {
  if (history.length === 0) return '';

  const recentMessages = history.slice(-4); // Last 4 messages
  return recentMessages
    .map(msg => `${msg.senderType === 'user' ? 'User' : 'Assistant'}: ${msg.message}`)
    .join('\n');
}

async function analyzeNeedsHumanEscalation(userMessage, aiResponse) {
  const escalationKeywords = [
    'speak to human', 'talk to person', 'real person', 'human agent',
    'manager', 'supervisor', 'escalate', 'complain', 'angry', 'frustrated',
    'terrible service', 'very upset', 'not satisfied', 'want refund'
  ];

  const combinedText = (userMessage + ' ' + aiResponse).toLowerCase();
  return escalationKeywords.some(keyword => combinedText.includes(keyword));
}

async function generateQuickReplies(userMessage, aiResponse) {
  // Generate contextual quick reply suggestions
  const suggestions = [];

  if (userMessage.toLowerCase().includes('order') && userMessage.toLowerCase().includes('status')) {
    suggestions.push('Check another order', 'Modify order', 'Cancel order');
  }

  if (userMessage.toLowerCase().includes('price') || userMessage.toLowerCase().includes('cost')) {
    suggestions.push('View pricing', 'Apply promo code', 'View offers');
  }

  if (userMessage.toLowerCase().includes('address') || userMessage.toLowerCase().includes('location')) {
    suggestions.push('Update address', 'Add new address', 'Track driver');
  }

  return suggestions.slice(0, 3); // Max 3 suggestions
}

async function saveConversationMessage(conversationId, userId, userMessage, aiResponse, messageType) {
  const messageId = admin.firestore().collection('support_messages').doc().id;

  await admin.firestore().collection('support_messages').doc(messageId).set({
    id: messageId,
    conversationId: conversationId,
    userId: userId,
    message: messageType === 'user' ? userMessage : aiResponse,
    senderType: messageType,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata: {
      source: 'ai_chat',
      responseLength: aiResponse.length,
      needsEscalation: false
    }
  });

  return messageId;
}
```

### **2. Talk-to-Human Feature**

#### **Phone Verification System**
```javascript
exports.requestHumanSupport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const { phoneNumber, reason, conversationId } = data;
  const userId = context.auth.uid;

  try {
    // Verify phone number format
    if (!phoneNumber || !isValidPhoneNumber(phoneNumber)) {
      throw new functions.https.HttpsError('invalid-argument', 'Valid phone number required');
    }

    // Get user profile for verification
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    // Check if provided number matches user's registered number
    const registeredPhone = userData.phoneNumber;
    const isPhoneVerified = phoneNumber === registeredPhone;

    if (!isPhoneVerified) {
      // Store phone verification request
      const verificationId = admin.firestore().collection('phone_verifications').doc().id;
      await admin.firestore().collection('phone_verifications').doc(verificationId).set({
        id: verificationId,
        userId: userId,
        requestedPhone: phoneNumber,
        registeredPhone: registeredPhone,
        status: 'pending',
        reason: reason,
        conversationId: conversationId,
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
      });

      return {
        success: false,
        requiresVerification: true,
        verificationId: verificationId,
        message: 'Phone number verification required before connecting to human support'
      };
    }

    // Phone is verified, proceed with human support request
    await initiateHumanSupport(userId, phoneNumber, reason, conversationId);

    return {
      success: true,
      message: 'Human support request submitted. You will receive a call shortly.'
    };

  } catch (error) {
    console.error('Human support request error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to request human support');
  }
});

function isValidPhoneNumber(phone) {
  // Basic Indian phone number validation
  const phoneRegex = /^(\+91|91|0)?[6-9]\d{9}$/;
  return phoneRegex.test(phone.replace(/[\s\-\(\)]/g, ''));
}

async function initiateHumanSupport(userId, phoneNumber, reason, conversationId) {
  // Create human support request
  const supportRequestId = admin.firestore().collection('human_support_requests').doc().id;

  await admin.firestore().collection('human_support_requests').doc(supportRequestId).set({
    id: supportRequestId,
    userId: userId,
    phoneNumber: phoneNumber,
    reason: reason,
    conversationId: conversationId,
    status: 'pending',
    priority: determinePriority(reason),
    requestedAt: admin.firestore.FieldValue.serverTimestamp(),
    assignedTo: null,
    callStartedAt: null,
    callEndedAt: null,
    outcome: null,
    notes: []
  });

  // Notify all available admins
  await notifyAdminsOfSupportRequest(supportRequestId, userId, phoneNumber, reason);

  // Log the support request
  await admin.firestore().collection('support_audit_logs').add({
    type: 'human_support_requested',
    userId: userId,
    supportRequestId: supportRequestId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata: {
      reason: reason,
      phoneNumber: phoneNumber,
      source: 'ai_escalation'
    }
  });
}

function determinePriority(reason) {
  const urgentKeywords = ['emergency', 'urgent', 'asap', 'immediate', 'critical'];
  const reasonLower = reason.toLowerCase();

  if (urgentKeywords.some(keyword => reasonLower.includes(keyword))) {
    return 'high';
  }

  return 'normal';
}

async function notifyAdminsOfSupportRequest(supportRequestId, userId, phoneNumber, reason) {
  // Get all active admins
  const adminsSnapshot = await admin.firestore()
    .collection('admins')
    .where('isActive', '==', true)
    .get();

  const notifications = [];

  adminsSnapshot.forEach(adminDoc => {
    const adminData = adminDoc.data();

    notifications.push({
      userId: adminDoc.id,
      type: 'human_support_request',
      title: 'Customer Needs Human Support',
      body: `Customer ${userId} is requesting human assistance. Reason: ${reason}`,
      data: {
        supportRequestId: supportRequestId,
        customerPhone: phoneNumber,
        customerId: userId,
        priority: determinePriority(reason)
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
  });

  // Save notifications to Firestore
  for (const notification of notifications) {
    await admin.firestore().collection('admin_notifications').add(notification);
  }

  // Send FCM push notifications if tokens are available
  await sendFCMNotifications(notifications);
}

async function sendFCMNotifications(notifications) {
  // Implementation for FCM push notifications to admin devices
  // This would use Firebase Cloud Messaging
}
```

### **3. Admin App Integration**

#### **Admin Notification System**
```javascript
exports.getPendingSupportRequests = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  try {
    const requestsSnapshot = await admin.firestore()
      .collection('human_support_requests')
      .where('status', '==', 'pending')
      .orderBy('requestedAt', 'asc')
      .get();

    const requests = requestsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      requestedAt: doc.data().requestedAt?.toDate?.()?.toISOString() || null
    }));

    return {
      success: true,
      requests: requests
    };

  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Failed to get support requests');
  }
});

exports.acceptSupportRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { supportRequestId } = data;
  const adminId = context.auth.uid;

  try {
    // Update support request
    await admin.firestore()
      .collection('human_support_requests')
      .doc(supportRequestId)
      .update({
        status: 'in_progress',
        assignedTo: adminId,
        callStartedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    // Get customer phone number
    const requestDoc = await admin.firestore()
      .collection('human_support_requests')
      .doc(supportRequestId)
      .get();

    const requestData = requestDoc.data();

    return {
      success: true,
      customerPhone: requestData.phoneNumber,
      message: 'Support request accepted. Customer phone number retrieved.'
    };

  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Failed to accept support request');
  }
});
```

## **📱 Mobile App Integration**

### **Human-Like Typing Animation Service**
```dart
// lib/services/typing_animation_service.dart
import 'dart:async';
import 'dart:math';

class TypingAnimationService {
  final Random _random = Random();
  Timer? _typingTimer;
  Function(String, bool)? _onTypingUpdate;
  Function()? _onComplete;

  void startTypingAnimation(
    String message,
    Function(String, bool) onTypingUpdate,
    Function() onComplete,
  ) {
    _onTypingUpdate = onTypingUpdate;
    _onComplete = onComplete;

    final words = message.split(' ');
    final wordCount = words.length;

    if (wordCount <= 5) {
      _animateShortMessage(words);
    } else {
      _animateLongMessage(message);
    }
  }

  void _animateShortMessage(List<String> words) async {
    final message = words.join(' ');
    int currentPosition = 0;
    int attemptCount = 0;

    // Pattern for 1-5 word messages:
    // First reply: Type non-stop without any pauses
    // Second reply: Stop twice (pause briefly after 2-3 words, then continue)
    // Third reply: Stop once (pause briefly in the middle)
    // Fourth reply: Type with a bit more variation (pause after 3-4 words, then finish)

    while (currentPosition < message.length) {
      attemptCount++;

      if (attemptCount == 1) {
        // First reply: Type non-stop
        final remainingLength = message.length - currentPosition;
        final chunkSize = min(remainingLength, 3 + _random.nextInt(3));
        currentPosition = min(currentPosition + chunkSize, message.length);

        _onTypingUpdate!(message.substring(0, currentPosition), false);

        if (currentPosition >= message.length) {
          await Future.delayed(Duration(milliseconds: 200));
          _onComplete!();
          return;
        }

        await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(100)));
      } else if (attemptCount == 2) {
        // Second reply: Stop twice
        final quarterLength = (message.length / 4).round();
        final halfLength = (message.length / 2).round();

        // Type first quarter
        currentPosition = min(currentPosition + quarterLength, message.length);
        _onTypingUpdate!(message.substring(0, currentPosition), false);
        await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(400)));

        // Type second quarter
        currentPosition = min(currentPosition + quarterLength, message.length);
        _onTypingUpdate!(message.substring(0, currentPosition), false);
        await Future.delayed(Duration(milliseconds: 600 + _random.nextInt(300)));

        // Type remaining
        currentPosition = message.length;
        _onTypingUpdate!(message, false);
        await Future.delayed(Duration(milliseconds: 200));
        _onComplete!();
        return;
      } else if (attemptCount == 3) {
        // Third reply: Stop once
        final halfLength = (message.length / 2).round();

        // Type first half
        currentPosition = min(currentPosition + halfLength, message.length);
        _onTypingUpdate!(message.substring(0, currentPosition), false);
        await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(500)));

        // Type remaining
        currentPosition = message.length;
        _onTypingUpdate!(message, false);
        await Future.delayed(Duration(milliseconds: 200));
        _onComplete!();
        return;
      } else {
        // Fourth reply: More variation
        final threeQuarterLength = (message.length * 3 / 4).round();

        // Type first 3/4
        currentPosition = min(currentPosition + threeQuarterLength, message.length);
        _onTypingUpdate!(message.substring(0, currentPosition), false);
        await Future.delayed(Duration(milliseconds: 900 + _random.nextInt(400)));

        // Type remaining
        currentPosition = message.length;
        _onTypingUpdate!(message, false);
        await Future.delayed(Duration(milliseconds: 200));
        _onComplete!();
        return;
      }
    }
  }

  void _animateLongMessage(String message) async {
    int currentPosition = 0;
    int pauseCount = 0;
    final maxPauses = 3 + _random.nextInt(3); // 3-5 pauses for long messages

    while (currentPosition < message.length && pauseCount < maxPauses) {
      // Type a chunk of text
      final remainingLength = message.length - currentPosition;
      final chunkSize = min(remainingLength, 2 + _random.nextInt(4));
      currentPosition = min(currentPosition + chunkSize, message.length);

      _onTypingUpdate!(message.substring(0, currentPosition), false);

      // Check if we need to pause
      if (currentPosition < message.length && _shouldPause(currentPosition, message.length, pauseCount)) {
        pauseCount++;
        final pauseDuration = _getRandomPauseDuration(pauseCount);
        await Future.delayed(Duration(milliseconds: pauseDuration));

        // Show typing indicator during pause
        _onTypingUpdate!(message.substring(0, currentPosition), true);
        await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(200)));
        _onTypingUpdate!(message.substring(0, currentPosition), false);
      }

      // Random delay between typing chunks
      if (currentPosition < message.length) {
        await Future.delayed(Duration(milliseconds: 150 + _random.nextInt(150)));
      }
    }

    // Final completion
    if (currentPosition >= message.length) {
      await Future.delayed(Duration(milliseconds: 200));
      _onComplete!();
    }
  }

  bool _shouldPause(int currentPosition, int totalLength, int pauseCount) {
    // Determine pause points based on message progress
    final progress = currentPosition / totalLength;

    switch (pauseCount) {
      case 0:
        return progress > 0.3 && _random.nextDouble() > 0.7;
      case 1:
        return progress > 0.6 && _random.nextDouble() > 0.6;
      case 2:
        return progress > 0.8 && _random.nextDouble() > 0.5;
      default:
        return _random.nextDouble() > 0.8;
    }
  }

  int _getRandomPauseDuration(int pauseCount) {
    // Vary pause durations for more realistic typing
    switch (pauseCount) {
      case 1:
        return 800 + _random.nextInt(400); // 0.8-1.2 seconds
      case 2:
        return 1200 + _random.nextInt(600); // 1.2-1.8 seconds
      case 3:
        return 1500 + _random.nextInt(800); // 1.5-2.3 seconds
      default:
        return 600 + _random.nextInt(400); // 0.6-1.0 seconds
    }
  }

  void stopAnimation() {
    _typingTimer?.cancel();
    _onTypingUpdate = null;
    _onComplete = null;
  }
}
```

### **Enhanced Message Bubble with Typing Animation**
```dart
// lib/widgets/animated_message_bubble.dart
import 'package:flutter/material.dart';

class AnimatedMessageBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool showTypingIndicator;
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const AnimatedMessageBubble({
    required this.message,
    required this.isUser,
    this.showTypingIndicator = false,
    this.suggestions = const [],
    required this.onSuggestionTap,
  });

  @override
  _AnimatedMessageBubbleState createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with TickerProviderStateMixin {
  String _displayedText = '';
  bool _isTyping = false;
  late TypingAnimationService _typingService;

  @override
  void initState() {
    super.initState();
    _typingService = TypingAnimationService();
    _startTypingAnimation();
  }

  @override
  void didUpdateWidget(AnimatedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _startTypingAnimation();
    }
  }

  void _startTypingAnimation() {
    setState(() {
      _displayedText = '';
      _isTyping = true;
    });

    _typingService.startTypingAnimation(
      widget.message,
      (text, isPaused) {
        setState(() {
          _displayedText = text;
          _isTyping = !isPaused;
        });
      },
      () {
        setState(() {
          _isTyping = false;
          _displayedText = widget.message;
        });
      },
    );
  }

  @override
  void dispose() {
    _typingService.stopAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typing text with cursor
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _displayedText,
                    style: TextStyle(
                      color: widget.isUser ? Colors.white : Colors.black,
                    ),
                  ),
                  if (_isTyping) ...[
                    TextSpan(
                      text: '|',
                      style: TextStyle(
                        color: widget.isUser ? Colors.white70 : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Typing indicator
            if (_isTyping) ...[
              SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedTypingDots(),
                  SizedBox(width: 8),
                  Text(
                    'SwiftBot is typing...',
                    style: TextStyle(
                      color: widget.isUser ? Colors.white70 : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],

            // Suggestions (show after typing is complete)
            if (!_isTyping && widget.suggestions.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.suggestions.map((suggestion) => InkWell(
                  onTap: () => widget.onSuggestionTap(suggestion),
                  child: Chip(
                    label: Text(suggestion),
                    backgroundColor: widget.isUser ? Colors.white24 : Colors.blue.shade100,
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedTypingDots extends StatefulWidget {
  @override
  __AnimatedTypingDotsState createState() => __AnimatedTypingDotsState();
}

class __AnimatedTypingDotsState extends State<_AnimatedTypingDots>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.3), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.3), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 1.0), weight: 20),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Text(
                '.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
```

### **Enhanced Support Screen**
```dart
// lib/screens/enhanced_help_and_support_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhancedHelpAndSupportScreen extends StatefulWidget {
  const EnhancedHelpAndSupportScreen({Key? key}) : super(key: key);

  @override
  _EnhancedHelpAndSupportScreenState createState() => _EnhancedHelpAndSupportScreenState();
}

class _EnhancedHelpAndSupportScreenState extends State<EnhancedHelpAndSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isAiChatMode = true;
  String? _conversationId;
  List<Map<String, dynamic>> _messages = [];
  bool _showPhoneVerification = false;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create or get existing conversation
        final conversationQuery = await FirebaseFirestore.instance
            .collection('support_conversations')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (conversationQuery.docs.isNotEmpty) {
          _conversationId = conversationQuery.docs.first.id;
          await _loadConversationHistory();
        } else {
          _conversationId = await _createNewConversation();
        }
      }
    } catch (e) {
      print('Error initializing conversation: $e');
    }
  }

  Future<String> _createNewConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final conversationId = FirebaseFirestore.instance
        .collection('support_conversations')
        .doc()
        .id;

    await FirebaseFirestore.instance
        .collection('support_conversations')
        .doc(conversationId)
        .set({
      'id': conversationId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Customer',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'type': 'ai_initiated'
    });

    return conversationId;
  }

  Future<void> _loadConversationHistory() async {
    if (_conversationId == null) return;

    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('support_messages')
          .where('conversationId', isEqualTo: _conversationId)
          .orderBy('timestamp', 'desc')
          .limit(50)
          .get();

      setState(() {
        _messages = messagesSnapshot.docs
            .map((doc) => doc.data())
            .toList()
            .reversed
            .toList();
      });
    } catch (e) {
      print('Error loading conversation history: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messages.add({
        'message': message,
        'senderType': 'user',
        'timestamp': DateTime.now(),
        'isLocal': true
      });
    });

    _messageController.clear();

    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('chatWithSwiftBot').call({
        'message': message,
        'conversationId': _conversationId,
      });

      if (result.data['success']) {
        setState(() {
          _messages.add({
            'message': result.data['response'],
            'senderType': 'ai',
            'timestamp': DateTime.now(),
            'needsHumanEscalation': result.data['needsHumanEscalation'],
            'suggestions': result.data['suggestions']
          });
        });

        // Check if human escalation is needed
        if (result.data['needsHumanEscalation']) {
          _showHumanEscalationOption();
        }
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'message': 'Sorry, I\'m having trouble responding right now. Please try again or request human support.',
          'senderType': 'ai',
          'timestamp': DateTime.now(),
          'isError': true
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showHumanEscalationOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Need More Help?'),
        content: Text('Our AI assistant suggests connecting you with a human support agent. Would you like us to call you?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue with AI'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestHumanSupport();
            },
            child: Text('Talk to Human'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestHumanSupport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _showPhoneVerification = true;
      _phoneController.text = user.phoneNumber ?? '';
    });
  }

  Future<void> _submitHumanSupportRequest() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() => _verificationError = 'Phone number is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('requestHumanSupport').call({
        'phoneNumber': phoneNumber,
        'reason': 'Customer requested human assistance',
        'conversationId': _conversationId,
      });

      if (result.data['requiresVerification']) {
        // Show phone verification dialog
        _showPhoneVerificationDialog(result.data['verificationId']);
      } else {
        // Success - show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support request submitted! You will receive a call shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _showPhoneVerification = false);
      }
    } catch (e) {
      setState(() => _verificationError = 'Failed to submit request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPhoneVerificationDialog(String verificationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Phone Verification Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('For security, please confirm this is your registered phone number:'),
            SizedBox(height: 16),
            Text(
              _phoneController.text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Text('An admin will call this number within the next few minutes.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmPhoneVerification(verificationId);
            },
            child: Text('Confirm & Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPhoneVerification(String verificationId) async {
    setState(() => _isLoading = true);

    try {
      // This would call another function to confirm the verification
      // and proceed with human support request

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone verified! You will receive a call from our support team shortly.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      setState(() => _showPhoneVerification = false);
    } catch (e) {
      setState(() => _verificationError = 'Verification failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SwiftWash Support'),
        actions: [
          IconButton(
            icon: Icon(_isAiChatMode ? Icons.person : Icons.smart_toy),
            onPressed: () {
              setState(() => _isAiChatMode = !_isAiChatMode);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _isAiChatMode ? _buildAiChat() : _buildPhoneSupport(),
          ),

          // Message input or phone verification
          if (_showPhoneVerification) _buildPhoneVerification() else _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildAiChat() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageBubble(
          message: message['message'],
          isUser: message['senderType'] == 'user',
          timestamp: message['timestamp'],
          isError: message['isError'] ?? false,
          needsHumanEscalation: message['needsHumanEscalation'] ?? false,
          suggestions: message['suggestions'] ?? [],
          onSuggestionTap: (suggestion) {
            _messageController.text = suggestion;
          },
        );
      },
    );
  }

  Widget _buildPhoneSupport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Phone Support',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Call us directly for immediate assistance',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:+919876543210')),
            icon: Icon(Icons.call),
            label: Text('Call Support'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerification() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Verification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please confirm your phone number for human support',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '+91 XXXXX XXXXX',
              border: OutlineInputBorder(),
              errorText: _verificationError,
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitHumanSupportRequest,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text('Request Call'),
                ),
              ),
              SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  setState(() => _showPhoneVerification = false);
                },
                child: Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything about SwiftWash...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: _isLoading
                ? CircularProgressIndicator()
                : Icon(Icons.send, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool needsHumanEscalation;
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.needsHumanEscalation = false,
    this.suggestions = const [],
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue
              : isError
                  ? Colors.red.shade100
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
              ),
            ),
            if (needsHumanEscalation) ...[
              SizedBox(height: 8),
              Text(
                '💬 Human assistance recommended',
                style: TextStyle(
                  color: isUser ? Colors.white70 : Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: suggestions.map((suggestion) => InkWell(
                  onTap: () => onSuggestionTap(suggestion),
                  child: Chip(
                    label: Text(suggestion),
                    backgroundColor: isUser ? Colors.white24 : Colors.blue.shade100,
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## **🛡️ Security & Privacy**

### **Data Protection**
- **Message Encryption**: All messages stored securely in Firestore
- **Phone Verification**: Validate phone numbers before allowing calls
- **Rate Limiting**: Prevent abuse of AI chat and support requests
- **Audit Logging**: Complete trail of all support interactions

### **Privacy Compliance**
- **Data Retention**: Support conversations retained for 90 days
- **User Consent**: Clear opt-in for human support calls
- **Data Minimization**: Only collect necessary information
- **Right to Deletion**: Users can request conversation deletion

## **📞 Admin App Integration**

### **Admin Notification Handler**
```dart
// swiftwash_admin/lib/services/admin_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getPendingSupportRequests() {
    return _firestore
        .collection('human_support_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', 'asc')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Future<bool> acceptSupportRequest(String requestId) async {
    try {
      // Update request status
      await _firestore
          .collection('human_support_requests')
          .doc(requestId)
          .update({
        'status': 'in_progress',
        'assignedTo': 'current_admin_id', // Get from auth
        'callStartedAt': FieldValue.serverTimestamp()
      });

      return true;
    } catch (e) {
      print('Error accepting support request: $e');
      return false;
    }
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw Exception('Could not launch phone dialer');
    }
  }

  Future<void> completeSupportRequest(String requestId, String outcome, String notes) async {
    await _firestore
        .collection('human_support_requests')
        .doc(requestId)
        .update({
      'status': 'completed',
      'callEndedAt': FieldValue.serverTimestamp(),
      'outcome': outcome,
      'notes': FieldValue.arrayUnion([notes])
    });
  }
}
```

## **🔧 Implementation Steps**

### **Phase 1: AI Integration**
1. ✅ Set up Vertex AI in Firebase Functions
2. ✅ Create AI chat function with safety settings
3. ✅ Implement conversation history and context
4. ✅ Add rate limiting and abuse prevention

### **Phase 2: Human Escalation**
1. ✅ Create phone verification system
2. ✅ Implement human support request workflow
3. ✅ Add admin notification system
4. ✅ Create call logging and audit trail

### **Phase 3: Mobile App Enhancement**
1. ✅ Update support screen with AI chat
2. ✅ Add phone verification UI
3. ✅ Implement real-time message updates
4. ✅ Add quick reply suggestions

### **Phase 4: Admin App Integration**
1. ✅ Create admin notification service
2. ✅ Add support request management
3. ✅ Implement call functionality
4. ✅ Add support analytics dashboard

## **📊 Analytics & Monitoring**

### **Support Metrics**
- **AI Resolution Rate**: Percentage of queries resolved by AI
- **Escalation Rate**: How often customers request human support
- **Response Time**: Average time for AI and human responses
- **Customer Satisfaction**: Post-support satisfaction ratings

### **Performance Monitoring**
- **AI Response Time**: Track latency of Vertex AI calls
- **Error Rates**: Monitor function failures and retries
- **Usage Patterns**: Track peak support request times
- **Cost Optimization**: Monitor Vertex AI usage costs

## **🚀 Success Metrics**

- **AI Accuracy**: 90%+ of AI responses are helpful
- **Escalation Efficiency**: Human support connects within 5 minutes
- **User Satisfaction**: 4.5+ star rating for support experience
- **Cost Effectiveness**: Reduce human support costs by 60%

## **🔧 Maintenance & Updates**

### **AI Model Updates**
- Monitor Vertex AI model performance
- Update prompts based on user feedback
- Add new training data for better responses
- Regular safety settings review

### **Feature Enhancements**
- Add multi-language support
- Implement sentiment analysis
- Add proactive support suggestions
- Enhance conversation context

---

**Note**: This AI support system provides a seamless experience from AI assistance to human support, with complete audit trails and security measures. The integration with Vertex AI ensures high-quality responses while the talk-to-human feature provides reliable escalation paths.
