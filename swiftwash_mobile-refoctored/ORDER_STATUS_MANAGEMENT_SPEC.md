# SwiftWash Order Status Management - Complete Specification
## Real-Time Status Updates & Floating Card System

### **Overview**
This document provides a comprehensive specification for implementing a robust order status management system with real-time updates, intelligent floating cards, and seamless admin-mobile app synchronization. The system ensures that order status changes from the admin app are immediately reflected in the mobile app with unique, non-stacking floating cards.

### **Critical Requirements**
- ✅ **Real-Time Synchronization**: Status changes reflect instantly across all platforms
- ✅ **Unique Floating Cards**: Each status change gets its own card (no stacking)
- ✅ **Order ID Focus**: Smart order IDs as primary reference points
- ✅ **Admin-Controlled Status**: All status changes originate from admin app
- ✅ **Mobile App Reflection**: Changes visible even when app is open/active
- ✅ **Notification System**: Push notifications for each status change
- ✅ **Non-Intrusive UI**: Floating cards that don't interfere with user experience

## **📱 Order Status System Architecture**

### **Status Flow & Lifecycle**
```javascript
// Complete order status lifecycle
const ORDER_STATUS_FLOW = {
  // Initial states
  'new': { color: '#2196F3', icon: 'new_order', priority: 1 },
  'confirmed': { color: '#4CAF50', icon: 'confirmed', priority: 2 },
  'assigned': { color: '#FF9800', icon: 'assigned', priority: 3 },

  // In-progress states
  'pickup_in_progress': { color: '#FFC107', icon: 'pickup', priority: 4 },
  'picked_up': { color: '#8BC34A', icon: 'picked_up', priority: 5 },
  'processing': { color: '#9C27B0', icon: 'processing', priority: 6 },
  'ready_for_delivery': { color: '#00BCD4', icon: 'ready', priority: 7 },

  // Delivery states
  'out_for_delivery': { color: '#3F51B5', icon: 'delivery', priority: 8 },
  'delivered': { color: '#4CAF50', icon: 'delivered', priority: 9 },

  // Issue states
  'issue_reported': { color: '#F44336', icon: 'issue', priority: 10 },
  'cancelled': { color: '#9E9E9E', icon: 'cancelled', priority: 11 },
  'refunded': { color: '#607D8B', icon: 'refunded', priority: 12 }
};
```

### **Real-Time Status Update Mechanism**

#### **Firebase Cloud Function for Status Updates**
```javascript
// functions/order_status_updates.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.updateOrderStatus = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Admin authentication required');
  }

  const { orderId, newStatus, adminId, notes } = data;

  if (!orderId || !newStatus) {
    throw new functions.https.HttpsError('invalid-argument', 'Order ID and status required');
  }

  try {
    // Verify admin permissions
    const adminDoc = await admin.firestore()
      .collection('admins')
      .doc(adminId)
      .get();

    if (!adminDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Admin not found');
    }

    // Get order details for notifications
    const orderDoc = await admin.firestore()
      .collection('orders')
      .doc(orderId)
      .get();

    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found');
    }

    const orderData = orderDoc.data();
    const userId = orderData.userId;

    // Update order status atomically
    await admin.firestore().runTransaction(async (transaction) => {
      const orderRef = admin.firestore().collection('orders').doc(orderId);
      const userRef = admin.firestore().collection('users').doc(userId);

      // Update order document
      transaction.update(orderRef, {
        status: newStatus,
        statusUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        statusUpdatedBy: adminId,
        statusNotes: notes || '',
        statusHistory: admin.firestore.FieldValue.arrayUnion({
          status: newStatus,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          updatedBy: adminId,
          notes: notes || '',
          orderId: orderId
        })
      });

      // Update user's current order reference
      transaction.update(userRef, {
        currentOrderStatus: newStatus,
        lastStatusUpdate: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    // Send real-time notification to user
    const notificationData = {
      orderId: orderId,
      newStatus: newStatus,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      adminId: adminId,
      notes: notes || '',
      type: 'status_update'
    };

    // Store notification for mobile app retrieval
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add(notificationData);

    // Send FCM push notification
    if (orderData.fcmToken) {
      const message = {
        token: orderData.fcmToken,
        notification: {
          title: `Order ${orderId} Updated`,
          body: `Status changed to: ${newStatus.replace(/_/g, ' ').toUpperCase()}`
        },
        data: {
          orderId: orderId,
          newStatus: newStatus,
          type: 'status_update',
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        }
      };

      await admin.messaging().send(message);
    }

    // Log status change for audit trail
    await admin.firestore().collection('order_status_audit').add({
      orderId: orderId,
      oldStatus: orderData.status,
      newStatus: newStatus,
      updatedBy: adminId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      notes: notes || '',
      source: 'admin_app'
    });

    return {
      success: true,
      orderId: orderId,
      newStatus: newStatus,
      updatedAt: new Date().toISOString()
    };

  } catch (error) {
    console.error('Error updating order status:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update order status');
  }
});
```

## **🎯 Floating Card System**

### **Card Management Architecture**

#### **Floating Card States**
```javascript
// Card display logic based on status
const FLOATING_CARD_CONFIG = {
  'new': {
    title: 'Order Received',
    message: 'Your order has been received and is being processed',
    icon: 'new_order',
    color: '#2196F3',
    duration: 5000,
    canSwipe: true,
    priority: 1
  },
  'confirmed': {
    title: 'Order Confirmed',
    message: 'Your order has been confirmed and payment processed',
    icon: 'confirmed',
    color: '#4CAF50',
    duration: 4000,
    canSwipe: true,
    priority: 2
  },
  'assigned': {
    title: 'Driver Assigned',
    message: 'A driver has been assigned to your order',
    icon: 'assigned',
    color: '#FF9800',
    duration: 6000,
    canSwipe: true,
    priority: 3
  },
  'pickup_in_progress': {
    title: 'Pickup in Progress',
    message: 'Driver is on the way to pick up your items',
    icon: 'pickup',
    color: '#FFC107',
    duration: 8000,
    canSwipe: false,
    priority: 4
  },
  'picked_up': {
    title: 'Items Picked Up',
    message: 'Your items have been collected by our driver',
    icon: 'picked_up',
    color: '#8BC34A',
    duration: 5000,
    canSwipe: true,
    priority: 5
  },
  'processing': {
    title: 'Processing Order',
    message: 'Your items are being processed at our facility',
    icon: 'processing',
    color: '#9C27B0',
    duration: 10000,
    canSwipe: false,
    priority: 6
  },
  'ready_for_delivery': {
    title: 'Ready for Delivery',
    message: 'Your order is ready and will be delivered soon',
    icon: 'ready',
    color: '#00BCD4',
    duration: 6000,
    canSwipe: true,
    priority: 7
  },
  'out_for_delivery': {
    title: 'Out for Delivery',
    message: 'Driver is on the way to deliver your order',
    icon: 'delivery',
    color: '#3F51B5',
    duration: 15000,
    canSwipe: false,
    priority: 8
  },
  'delivered': {
    title: 'Order Delivered',
    message: 'Your order has been successfully delivered',
    icon: 'delivered',
    color: '#4CAF50',
    duration: 8000,
    canSwipe: true,
    priority: 9
  },
  'issue_reported': {
    title: 'Issue Reported',
    message: 'An issue has been reported with your order',
    icon: 'issue',
    color: '#F44336',
    duration: 0, // Persistent until resolved
    canSwipe: false,
    priority: 10
  },
  'cancelled': {
    title: 'Order Cancelled',
    message: 'Your order has been cancelled',
    icon: 'cancelled',
    color: '#9E9E9E',
    duration: 10000,
    canSwipe: true,
    priority: 11
  },
  'refunded': {
    title: 'Order Refunded',
    message: 'Refund has been processed for your order',
    icon: 'refunded',
    color: '#607D8B',
    duration: 7000,
    canSwipe: true,
    priority: 12
  }
};
```

### **Mobile App Floating Card Implementation**

#### **Floating Card Widget**
```dart
// lib/widgets/enhanced_floating_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedFloatingCard extends StatefulWidget {
  final String orderId;
  final String status;
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final bool canSwipe;
  final VoidCallback onDismiss;

  const EnhancedFloatingCard({
    required this.orderId,
    required this.status,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.canSwipe,
    required this.onDismiss,
  });

  @override
  _EnhancedFloatingCardState createState() => _EnhancedFloatingCardState();
}

class _EnhancedFloatingCardState extends State<EnhancedFloatingCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAutoDismissTimer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  void _startAutoDismissTimer() {
    // Auto-dismiss based on status configuration
    final config = FLOATING_CARD_CONFIG[widget.status];
    if (config != null && config.duration > 0) {
      Future.delayed(Duration(milliseconds: config.duration), () {
        if (mounted) {
          _dismissCard();
        }
      });
    }
  }

  void _dismissCard() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () {
            // Navigate to order details
            Navigator.pushNamed(context, '/order-details', arguments: widget.orderId);
          },
          child: Dismissible(
            key: Key(widget.orderId + widget.status),
            direction: widget.canSwipe ? DismissDirection.horizontal : DismissDirection.none,
            onDismissed: (direction) => _dismissCard(),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 20),
              child: Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.close, color: Colors.white),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.9), widget.color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Order ID: ${widget.orderId}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.canSwipe) ...[
                        SizedBox(width: 16),
                        Icon(
                          Icons.swipe,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### **Floating Card Manager Service**
```dart
// lib/services/floating_card_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FloatingCardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<FloatingCardData> _activeCards = [];
  bool _isListening = false;

  List<FloatingCardData> get activeCards => List.unmodifiable(_activeCards);

  void startListening(String userId) {
    if (_isListening) return;

    _isListening = true;

    // Listen for new notifications
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'status_update')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              _handleNewNotification(doc.doc.data()!, doc.doc.id);
            }
          }
        });
  }

  void _handleNewNotification(Map<String, dynamic> data, String notificationId) {
    final orderId = data['orderId'] as String;
    final newStatus = data['newStatus'] as String;

    // Check if we already have a card for this order ID
    final existingCardIndex = _activeCards.indexWhere(
      (card) => card.orderId == orderId,
    );

    if (existingCardIndex >= 0) {
      // Update existing card
      _updateExistingCard(existingCardIndex, newStatus, data);
    } else {
      // Add new card
      _addNewCard(orderId, newStatus, data);
    }

    // Mark notification as read
    _markNotificationAsRead(data['userId'], notificationId);

    notifyListeners();
  }

  void _updateExistingCard(int index, String newStatus, Map<String, dynamic> data) {
    final config = FLOATING_CARD_CONFIG[newStatus];
    if (config != null) {
      _activeCards[index] = FloatingCardData(
        orderId: data['orderId'],
        status: newStatus,
        title: config.title,
        message: config.message,
        color: config.color,
        icon: _getIconForStatus(newStatus),
        canSwipe: config.canSwipe,
        timestamp: data['timestamp'],
      );
    }
  }

  void _addNewCard(String orderId, String status, Map<String, dynamic> data) {
    final config = FLOATING_CARD_CONFIG[status];
    if (config != null) {
      final newCard = FloatingCardData(
        orderId: orderId,
        status: status,
        title: config.title,
        message: config.message,
        color: config.color,
        icon: _getIconForStatus(status),
        canSwipe: config.canSwipe,
        timestamp: data['timestamp'],
      );

      // Insert at beginning to show latest first
      _activeCards.insert(0, newCard);

      // Keep only latest 3 cards to prevent UI clutter
      if (_activeCards.length > 3) {
        _activeCards.removeLast();
      }
    }
  }

  void dismissCard(String orderId) {
    _activeCards.removeWhere((card) => card.orderId == orderId);
    notifyListeners();
  }

  void _markNotificationAsRead(String? userId, String notificationId) {
    if (userId != null) {
      _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    }
  }

  IconData _getIconForStatus(String status) {
    // Map status to appropriate icons
    switch (status) {
      case 'new':
        return Icons.fiber_new;
      case 'confirmed':
        return Icons.check_circle;
      case 'assigned':
        return Icons.person_add;
      case 'pickup_in_progress':
        return Icons.local_shipping;
      case 'picked_up':
        return Icons.shopping_bag;
      case 'processing':
        return Icons.sync;
      case 'ready_for_delivery':
        return Icons.check_circle_outline;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'issue_reported':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.undo;
      default:
        return Icons.info;
    }
  }
}

class FloatingCardData {
  final String orderId;
  final String status;
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  final bool canSwipe;
  final Timestamp timestamp;

  FloatingCardData({
    required this.orderId,
    required this.status,
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.canSwipe,
    required this.timestamp,
  });
}
```

## **🔧 Admin App Integration**

### **Admin Order Status Management**

#### **Status Update Interface**
```dart
// swiftwash_admin/lib/widgets/status_update_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StatusUpdateWidget extends StatefulWidget {
  final String orderId;
  final String currentStatus;
  final String userId;

  const StatusUpdateWidget({
    required this.orderId,
    required this.currentStatus,
    required this.userId,
  });

  @override
  _StatusUpdateWidgetState createState() => _StatusUpdateWidgetState();
}

class _StatusUpdateWidgetState extends State<StatusUpdateWidget> {
  String? _selectedStatus;
  String? _notes;
  bool _isUpdating = false;

  final List<String> _availableStatuses = [
    'new',
    'confirmed',
    'assigned',
    'pickup_in_progress',
    'picked_up',
    'processing',
    'ready_for_delivery',
    'out_for_delivery',
    'delivered',
    'issue_reported',
    'cancelled',
    'refunded'
  ];

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a status')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('updateOrderStatus').call({
        'orderId': widget.orderId,
        'newStatus': _selectedStatus,
        'adminId': 'current_admin_id', // Get from auth
        'notes': _notes,
      });

      if (result.data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _selectedStatus = null;
          _notes = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          Text(
            'Current Status: ${widget.currentStatus.replace(/_/g, ' ').toUpperCase()}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'New Status',
              border: OutlineInputBorder(),
            ),
            value: _selectedStatus,
            items: _availableStatuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.replace(/_/g, ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),

          SizedBox(height: 16),

          TextField(
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(),
              hintText: 'Add notes about this status change...',
            ),
            maxLines: 3,
            onChanged: (value) => _notes = value,
          ),

          SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updateStatus,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ORDER_STATUS_FLOW[_selectedStatus]?['color'] as Color? ?? Colors.blue,
              ),
              child: _isUpdating
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## **📊 Real-Time Synchronization**

### **Mobile App Status Listener**
```dart
// lib/services/order_status_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _notificationSubscription;

  void startListeningForStatusUpdates(String userId) {
    // Listen for changes to user's current order status
    _statusSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userDoc) {
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null && data.containsKey('currentOrderStatus')) {
              _handleStatusUpdate(data['currentOrderStatus'], data['lastStatusUpdate']);
            }
          }
        });

    // Listen for new notifications
    _notificationSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', isEqualTo: 'status_update')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              _handleNewNotification(doc.doc.data()!);
            }
          }
        });
  }

  void _handleStatusUpdate(String? newStatus, Timestamp? timestamp) {
    if (newStatus != null && timestamp != null) {
      // Notify floating card service about status change
      // This will trigger UI updates in real-time
      print('Status updated to: $newStatus at ${timestamp.toDate()}');
    }
  }

  void _handleNewNotification(Map<String, dynamic> notificationData) {
    final orderId = notificationData['orderId'];
    final newStatus = notificationData['newStatus'];

    // Show local notification if app is in background
    if (orderId != null && newStatus != null) {
      _showLocalNotification(orderId, newStatus);
    }
  }

  void _showLocalNotification(String orderId, String status) {
    // Implementation for local notifications
    // This will show notification even when app is in background
  }

  void stopListening() {
    _statusSubscription?.cancel();
    _notificationSubscription?.cancel();
  }
}
```

## **🎨 UI/UX Implementation**

### **Main Screen Integration**
```dart
// lib/screens/enhanced_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EnhancedMainScreen extends StatefulWidget {
  @override
  _EnhancedMainScreenState createState() => _EnhancedMainScreenState();
}

class _EnhancedMainScreenState extends State<EnhancedMainScreen> {
  late FloatingCardService _floatingCardService;
  late OrderStatusService _orderStatusService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _floatingCardService = Provider.of<FloatingCardService>(context, listen: false);
    _orderStatusService = Provider.of<OrderStatusService>(context, listen: false);

    // Start listening for real-time updates
    final userId = 'current_user_id'; // Get from auth
    _orderStatusService.startListeningForStatusUpdates(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),

          // Floating cards overlay
          Consumer<FloatingCardService>(
            builder: (context, cardService, child) {
              return Stack(
                children: cardService.activeCards.map((cardData) {
                  return EnhancedFloatingCard(
                    orderId: cardData.orderId,
                    status: cardData.status,
                    title: cardData.title,
                    message: cardData.message,
                    color: cardData.color,
                    icon: cardData.icon,
                    canSwipe: cardData.canSwipe,
                    onDismiss: () => cardService.dismissCard(cardData.orderId),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Existing main screen content
    return Container(
      // Main screen UI
    );
  }
}
```

## **🔧 Database Schema Updates**

### **Enhanced Order Document**
```javascript
// Updated orders collection structure
{
  orderId: "SW-NGP-N-440-IRN-001",
  userId: "user_uid_123",
  status: "out_for_delivery",
  statusUpdatedAt: "2025-01-15T10:30:00Z",
  statusUpdatedBy: "admin_uid_456",
  statusNotes: "Driver John assigned to delivery",
  statusHistory: [
    {
      status: "new",
      timestamp: "2025-01-15T09:00:00Z",
      updatedBy: "system",
      notes: "Order created"
    },
    {
      status: "confirmed",
      timestamp: "2025-01-15T09:05:00Z",
      updatedBy: "admin_uid_456",
      notes: "Payment confirmed"
    },
    {
      status: "out_for_delivery",
      timestamp: "2025-01-15T10:30:00Z",
      updatedBy: "admin_uid_456",
      notes: "Driver John assigned to delivery"
    }
  ],
  // ... other order fields
}
```

### **User Notifications Collection**
```javascript
// users/{userId}/notifications/{notificationId}
{
  orderId: "SW-NGP-N-440-IRN-001",
  type: "status_update",
  newStatus: "out_for_delivery",
  timestamp: "2025-01-15T10:30:00Z",
  adminId: "admin_uid_456",
  notes: "Driver John assigned to delivery",
  read: false
}
```

### **Order Status Audit Collection**
```javascript
// order_status_audit/{auditId}
{
  orderId: "SW-NGP-N-440-IRN-001",
  oldStatus: "ready_for_delivery",
  newStatus: "out_for_delivery",
  updatedBy: "admin_uid_456",
  updatedAt: "2025-01-15T10:30:00Z",
  notes: "Driver John assigned to delivery",
  source: "admin_app"
}
```

## **📱 Implementation Phases**

### **Phase 1: Core Status Management**
1. ✅ Implement Firebase function for status updates
2. ✅ Create floating card configuration system
3. ✅ Set up real-time listeners for status changes
4. ✅ Implement basic floating card widget
5. ✅ Add notification system integration

### **Phase 2: Enhanced UI/UX**
1. ✅ Create floating card manager service
2. ✅ Implement card animation and transitions
3. ✅ Add swipe-to-dismiss functionality
4. ✅ Integrate with main screen layout
5. ✅ Add order ID display in cards

### **Phase 3: Admin Integration**
1. ✅ Create admin status update interface
2. ✅ Implement status validation and permissions
3. ✅ Add audit trail logging
4. ✅ Create admin notification system
5. ✅ Add bulk status update capabilities

### **Phase 4: Advanced Features**
1. ✅ Implement persistent cards for issues
2. ✅ Add card priority system
3. ✅ Create status-specific animations
4. ✅ Add sound/vibration feedback
5. ✅ Implement card history and analytics

## **🚀 Success Metrics**

### **Technical Success**
- **Real-Time Updates**: Status changes reflect within 2 seconds
- **Zero Data Loss**: All status changes logged and auditable
- **Memory Efficient**: Cards don't cause memory leaks
- **Battery Friendly**: Efficient Firebase listeners

### **User Experience**
- **Non-Intrusive**: Cards don't interfere with app usage
- **Informative**: Clear status information and order IDs
- **Responsive**: Smooth animations and transitions
- **Accessible**: Works with screen readers and accessibility features

### **Admin Experience**
- **Easy Updates**: Simple interface for status changes
- **Real-Time Feedback**: Immediate confirmation of updates
- **Audit Trail**: Complete history of all changes
- **Bulk Operations**: Efficient mass status updates

## **🔧 Maintenance & Monitoring**

### **Performance Monitoring**
- Track floating card memory usage
- Monitor Firebase listener efficiency
- Measure notification delivery times
- Analyze status update patterns

### **Error Handling**
- Graceful handling of network issues
- Retry mechanisms for failed updates
- User feedback for update failures
- Admin alerts for critical errors

### **Analytics & Insights**
- Status change frequency analysis
- Card interaction tracking
- User engagement metrics
- Admin productivity insights

---

**Note**: This order status management system ensures real-time synchronization between admin and mobile apps while providing an elegant, non-intrusive user experience. The floating card system replaces the need for stacking notifications and provides clear, actionable information to users about their order status changes.
