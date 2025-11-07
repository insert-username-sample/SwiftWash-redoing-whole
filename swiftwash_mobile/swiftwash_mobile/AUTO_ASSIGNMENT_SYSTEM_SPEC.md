# SwiftWash Auto-Assignment System - Complete Specification
## Intelligent Task Assignment for Online Admins

### **Overview**
This document provides a comprehensive specification for implementing an intelligent auto-assignment system that automatically assigns orders to available online admins who are not currently delivering. The system prioritizes order IDs, ensures fair distribution, and operates in parallel across all platforms.

### **Critical Requirements**
- ✅ **Online Admin Detection**: Real-time tracking of admin online status
- ✅ **Delivery Status Awareness**: Only assign to admins not currently delivering
- ✅ **Order ID Prioritization**: Smart order IDs influence assignment priority
- ✅ **Fair Distribution**: Round-robin assignment with workload balancing
- ✅ **Real-Time Updates**: Instant assignment when admins become available
- ✅ **Parallel Processing**: Works across mobile app, backend app, and Firebase
- ✅ **Fallback Protection**: Manual assignment if auto-assignment fails

## **🏗️ System Architecture**

### **Admin Status Tracking System**

#### **Real-Time Admin Status Management**
```javascript
// Firebase Cloud Function for admin status updates
exports.updateAdminStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Admin authentication required');
  }

  const { adminId, status, isDelivering, currentOrderId } = data;

  if (!adminId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'Admin ID and status required');
  }

  try {
    // Update admin status in Firestore
    await admin.firestore().collection('admins').doc(adminId).update({
      status: status, // 'online', 'offline', 'busy'
      isDelivering: isDelivering || false,
      currentOrderId: currentOrderId || null,
      lastStatusUpdate: admin.firestore.FieldValue.serverTimestamp(),
      lastSeen: admin.firestore.FieldValue.serverTimestamp()
    });

    // If admin goes offline or starts delivering, check for reassignment
    if (status === 'offline' || isDelivering) {
      await checkForOrderReassignment(adminId);
    }

    // If admin becomes available, trigger auto-assignment
    if (status === 'online' && !isDelivering) {
      await triggerAutoAssignment(adminId);
    }

    return {
      success: true,
      adminId: adminId,
      status: status,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error('Error updating admin status:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update admin status');
  }
});
```

### **Order Assignment Algorithm**

#### **Intelligent Assignment Logic**
```javascript
// functions/auto_assignment.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.processAutoAssignment = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const orderData = snap.data();
    const orderId = context.params.orderId;

    try {
      // Only process new orders that need assignment
      if (orderData.status !== 'new' && orderData.status !== 'confirmed') {
        return null;
      }

      console.log(`Processing auto-assignment for order: ${orderId}`);

      // Find available admins
      const availableAdmins = await getAvailableAdmins();

      if (availableAdmins.length === 0) {
        console.log('No available admins for assignment');
        await markOrderForManualAssignment(orderId);
        return null;
      }

      // Apply assignment algorithm
      const selectedAdmin = await selectBestAdmin(availableAdmins, orderData, orderId);

      if (selectedAdmin) {
        await assignOrderToAdmin(orderId, selectedAdmin.adminId, orderData);
        console.log(`Order ${orderId} assigned to admin ${selectedAdmin.adminId}`);
      } else {
        await markOrderForManualAssignment(orderId);
      }

      return {
        success: true,
        orderId: orderId,
        assignedAdminId: selectedAdmin?.adminId || null
      };

    } catch (error) {
      console.error('Error in auto-assignment:', error);
      await markOrderForManualAssignment(orderId);
      return null;
    }
  });

async function getAvailableAdmins() {
  const adminsSnapshot = await admin.firestore()
    .collection('admins')
    .where('status', '==', 'online')
    .where('isDelivering', '==', false)
    .get();

  const availableAdmins = [];
  adminsSnapshot.forEach(doc => {
    const data = doc.data();

    // Check if admin was seen recently (within last 5 minutes)
    const lastSeen = data.lastSeen?.toDate();
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

    if (lastSeen && lastSeen > fiveMinutesAgo) {
      availableAdmins.push({
        adminId: doc.id,
        ...data,
        workload: data.currentWorkload || 0,
        priority: data.priority || 1,
        specializations: data.specializations || []
      });
    }
  });

  return availableAdmins;
}

async function selectBestAdmin(availableAdmins, orderData, orderId) {
  if (availableAdmins.length === 0) return null;

  // Parse order ID for intelligent assignment
  const orderComponents = parseOrderId(orderId);

  // Score each admin based on multiple factors
  const scoredAdmins = availableAdmins.map(admin => {
    let score = 0;

    // Factor 1: Workload (lower is better)
    score += (10 - Math.min(admin.workload, 10)) * 2;

    // Factor 2: Priority level (higher is better)
    score += admin.priority * 3;

    // Factor 3: Geographic proximity (if location data available)
    if (admin.currentLocation && orderData.pickupAddress?.coordinates) {
      const distance = calculateDistance(
        admin.currentLocation.latitude,
        admin.currentLocation.longitude,
        orderData.pickupAddress.coordinates.lat,
        orderData.pickupAddress.coordinates.lng
      );
      score += Math.max(0, 10 - (distance / 1000)); // Closer = higher score
    }

    // Factor 4: Specialization match
    if (admin.specializations && admin.specializations.length > 0) {
      const orderType = orderComponents.typeCode;
      if (admin.specializations.includes(orderType)) {
        score += 5;
      }
    }

    // Factor 5: Recent performance (based on completion rate)
    if (admin.completionRate) {
      score += admin.completionRate * 2;
    }

    return {
      ...admin,
      assignmentScore: score
    };
  });

  // Sort by score (highest first)
  scoredAdmins.sort((a, b) => b.assignmentScore - a.assignmentScore);

  // Return top admin
  return scoredAdmins[0] || null;
}

async function assignOrderToAdmin(orderId, adminId, orderData) {
  // Use transaction to ensure atomic assignment
  await admin.firestore().runTransaction(async (transaction) => {
    const orderRef = admin.firestore().collection('orders').doc(orderId);
    const adminRef = admin.firestore().collection('admins').doc(adminId);

    // Update order
    transaction.update(orderRef, {
      assignedAdminId: adminId,
      status: 'assigned',
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignmentMethod: 'auto'
    });

    // Update admin
    transaction.update(adminRef, {
      currentOrderId: orderId,
      isDelivering: true,
      currentWorkload: admin.firestore.FieldValue.increment(1),
      lastAssignment: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  // Send notifications
  await sendAssignmentNotifications(orderId, adminId, orderData);

  // Log assignment
  await logAssignment(orderId, adminId, 'auto', orderData);
}

function parseOrderId(orderId) {
  // Parse smart order ID: SW-{CITY}-{DIRECTION}-{PINCODE}-{TYPE}-{SEQUENCE}-{FLAGS}
  const parts = orderId.split('-');
  return {
    cityCode: parts[1],
    direction: parts[2],
    pincodePrefix: parts[3],
    typeCode: parts[4],
    sequence: parts[5],
    flags: parts.slice(6)
  };
}

function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c * 1000; // Return distance in meters
}

async function sendAssignmentNotifications(orderId, adminId, orderData) {
  // Send push notification to admin
  if (orderData.adminFcmToken) {
    const message = {
      token: orderData.adminFcmToken,
      notification: {
        title: 'New Order Assigned',
        body: `Order ${orderId} has been assigned to you`
      },
      data: {
        orderId: orderId,
        type: 'order_assigned',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    };

    await admin.messaging().send(message);
  }

  // Notify user about assignment
  if (orderData.userFcmToken) {
    const userMessage = {
      token: orderData.userFcmToken,
      notification: {
        title: 'Order Update',
        body: `Your order ${orderId} has been assigned to a representative`
      },
      data: {
        orderId: orderId,
        type: 'order_assigned',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    };

    await admin.messaging().send(userMessage);
  }
}

async function logAssignment(orderId, adminId, method, orderData) {
  await admin.firestore().collection('order_assignments').add({
    orderId: orderId,
    adminId: adminId,
    assignmentMethod: method,
    assignedAt: admin.firestore.FieldValue.serverTimestamp(),
    orderData: orderData,
    source: 'auto_assignment'
  });
}

async function markOrderForManualAssignment(orderId) {
  await admin.firestore().collection('orders').doc(orderId).update({
    status: 'pending_manual_assignment',
    flaggedForManualAssignment: true,
    manualAssignmentReason: 'No available admins',
    flaggedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Notify all super admins about manual assignment needed
  await notifySuperAdmins(orderId);
}

async function notifySuperAdmins(orderId) {
  const superAdminsSnapshot = await admin.firestore()
    .collection('admins')
    .where('role', '==', 'super_admin')
    .where('status', '==', 'online')
    .get();

  const tokens = [];
  superAdminsSnapshot.forEach(doc => {
    const data = doc.data();
    if (data.fcmToken) {
      tokens.push(data.fcmToken);
    }
  });

  if (tokens.length > 0) {
    const message = {
      tokens: tokens,
      notification: {
        title: 'Manual Assignment Required',
        body: `Order ${orderId} needs manual assignment`
      },
      data: {
        orderId: orderId,
        type: 'manual_assignment_required',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      }
    };

    await admin.messaging().sendMulticast(message);
  }
}
```

## **📊 Admin Workload Management**

### **Workload Balancing Algorithm**

#### **Dynamic Workload Calculation**
```javascript
// functions/workload_manager.js
exports.updateAdminWorkload = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const orderId = context.params.orderId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // If order status changed, update admin workload
    if (beforeData.status !== afterData.status) {
      await updateAdminWorkloadIfNeeded(orderId, beforeData, afterData);
    }
  });

async function updateAdminWorkloadIfNeeded(orderId, beforeData, afterData) {
  const adminId = afterData.assignedAdminId;

  if (!adminId) return;

  // Define workload impact by status
  const workloadImpact = {
    'assigned': 1,
    'pickup_in_progress': 0.5,
    'picked_up': 0.3,
    'processing': 0.2,
    'ready_for_delivery': 0.1,
    'out_for_delivery': 0.5,
    'delivered': -1,
    'cancelled': -1,
    'refunded': -0.5
  };

  const beforeImpact = workloadImpact[beforeData.status] || 0;
  const afterImpact = workloadImpact[afterData.status] || 0;
  const netImpact = afterImpact - beforeImpact;

  if (netImpact !== 0) {
    await admin.firestore().collection('admins').doc(adminId).update({
      currentWorkload: admin.firestore.FieldValue.increment(netImpact),
      lastWorkloadUpdate: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}
```

## **🔧 Mobile App Integration**

### **Order Assignment Service**
```dart
// lib/services/order_assignment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderAssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen for assignment updates for current admin
  Stream<DocumentSnapshot> getAdminAssignmentStream(String adminId) {
    return _firestore
        .collection('admins')
        .doc(adminId)
        .snapshots();
  }

  // Listen for orders assigned to current admin
  Stream<QuerySnapshot> getAssignedOrdersStream(String adminId) {
    return _firestore
        .collection('orders')
        .where('assignedAdminId', isEqualTo: adminId)
        .where('status', whereIn: [
          'assigned',
          'pickup_in_progress',
          'picked_up',
          'processing',
          'ready_for_delivery',
          'out_for_delivery'
        ])
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }

  // Update admin status and availability
  Future<void> updateAdminStatus({
    required String adminId,
    required String status,
    bool? isDelivering,
    String? currentOrderId,
  }) async {
    try {
      await _firestore.collection('admins').doc(adminId).update({
        'status': status,
        'isDelivering': isDelivering ?? false,
        'currentOrderId': currentOrderId,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update admin status: $e');
    }
  }

  // Get available admins for manual assignment
  Future<List<Map<String, dynamic>>> getAvailableAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('status', isEqualTo: 'online')
          .where('isDelivering', isEqualTo: false)
          .get();

      final admins = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'adminId': doc.id,
          'name': data['name'] ?? 'Unknown Admin',
          'workload': data['currentWorkload'] ?? 0,
          'priority': data['priority'] ?? 1,
          'specializations': data['specializations'] ?? [],
          'lastSeen': data['lastSeen']?.toDate(),
        };
      }).toList();

      // Sort by workload (ascending) and priority (descending)
      admins.sort((a, b) {
        if (a['workload'] != b['workload']) {
          return a['workload'].compareTo(b['workload']);
        }
        return b['priority'].compareTo(a['priority']);
      });

      return admins;
    } catch (e) {
      throw Exception('Failed to get available admins: $e');
    }
  }
}
```

## **📱 Admin App Assignment Interface**

### **Assignment Management Widget**
```dart
// swiftwash_admin/lib/widgets/assignment_management_widget.dart
import 'package:flutter/material.dart';

class AssignmentManagementWidget extends StatefulWidget {
  @override
  _AssignmentManagementWidgetState createState() => _AssignmentManagementWidgetState();
}

class _AssignmentManagementWidgetState extends State<AssignmentManagementWidget> {
  final OrderAssignmentService _assignmentService = OrderAssignmentService();
  List<Map<String, dynamic>> _availableAdmins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableAdmins();
  }

  Future<void> _loadAvailableAdmins() async {
    setState(() => _isLoading = true);

    try {
      final admins = await _assignmentService.getAvailableAdmins();
      setState(() {
        _availableAdmins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load available admins: $e')),
      );
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
          Row(
            children: [
              Text(
                'Available Admins',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadAvailableAdmins,
                tooltip: 'Refresh',
              ),
            ],
          ),

          SizedBox(height: 16),

          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _availableAdmins.isEmpty
                  ? _buildNoAdminsView()
                  : _buildAdminsList(),
        ],
      ),
    );
  }

  Widget _buildNoAdminsView() {
    return Container(
      padding: EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Available Admins',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All admins are either offline or currently delivering orders.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _availableAdmins.length,
      itemBuilder: (context, index) {
        final admin = _availableAdmins[index];
        return _buildAdminCard(admin);
      },
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(
                admin['name'].toString().substring(0, 1).toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: _getWorkloadColor(admin['workload']),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Workload: ${admin['workload']} | Priority: ${admin['priority']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (admin['specializations'].isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Specializations: ${admin['specializations'].join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  admin['lastSeen'] != null
                      ? 'Last seen: ${_formatLastSeen(admin['lastSeen'])}'
                      : 'Online now',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getWorkloadColor(int workload) {
    if (workload <= 2) return Colors.green;
    if (workload <= 5) return Colors.orange;
    return Colors.red;
  }

  String _formatLastSeen(DateTime lastSeen) {
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }
}
```

## **🔧 Database Schema Updates**

### **Enhanced Admin Document**
```javascript
// Updated admins collection structure
{
  adminId: "admin_uid_456",
  name: "John Doe",
  email: "john@swiftwash.com",
  role: "admin", // admin, super_admin, manager
  status: "online", // online, offline, busy
  isDelivering: false,
  currentOrderId: null,
  currentWorkload: 0,
  priority: 1, // Higher number = higher priority
  specializations: ["IRN", "WSH"], // Order types this admin specializes in
  currentLocation: {
    latitude: 21.1458,
    longitude: 79.0882,
    lastUpdated: "2025-01-15T10:30:00Z"
  },
  performanceMetrics: {
    completionRate: 0.95,
    averageDeliveryTime: 45, // minutes
    totalOrdersCompleted: 150,
    rating: 4.8
  },
  lastStatusUpdate: "2025-01-15T10:30:00Z",
  lastSeen: "2025-01-15T10:30:00Z",
  fcmToken: "admin_fcm_token_here"
}
```

### **Order Assignment Collection**
```javascript
// order_assignments/{assignmentId}
{
  orderId: "SW-NGP-N-440-IRN-001",
  adminId: "admin_uid_456",
  assignmentMethod: "auto", // auto, manual
  assignedAt: "2025-01-15T10:30:00Z",
  assignmentScore: 8.5, // Score used for auto-assignment
  orderData: {
    // Snapshot of order data at assignment time
    orderId: "SW-NGP-N-440-IRN-001",
    userId: "user_uid_123",
    serviceType: "ironing",
    // ... other relevant order data
  },
  source: "auto_assignment"
}
```

### **Manual Assignment Queue**
```javascript
// manual_assignment_queue/{orderId}
{
  orderId: "SW-NGP-N-440-IRN-001",
  reason: "No available admins",
  flaggedAt: "2025-01-15T10:30:00Z",
  priority: "high", // high, medium, low
  userId: "user_uid_123",
  orderData: {
    // Essential order information for manual assignment
  },
  assigned: false,
  assignedAt: null,
  assignedBy: null
}
```

## **📊 Real-Time Monitoring Dashboard**

### **Assignment Analytics**
```javascript
// functions/assignment_analytics.js
exports.generateAssignmentAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  try {
    const { timeRange = '24h' } = data;

    // Get assignment data for time range
    const assignmentsSnapshot = await admin.firestore()
      .collection('order_assignments')
      .where('assignedAt', '>=', getTimeRangeStart(timeRange))
      .get();

    const manualQueueSnapshot = await admin.firestore()
      .collection('manual_assignment_queue')
      .where('flaggedAt', '>=', getTimeRangeStart(timeRange))
      .get();

    // Analyze assignment patterns
    const analytics = {
      totalAssignments: assignmentsSnapshot.size,
      autoAssignments: 0,
      manualAssignments: 0,
      manualAssignmentRate: 0,
      averageAssignmentTime: 0,
      adminPerformance: {},
      peakHours: {},
      commonFailureReasons: {}
    };

    assignmentsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.assignmentMethod === 'auto') {
        analytics.autoAssignments++;
      } else {
        analytics.manualAssignments++;
      }

      // Track admin performance
      const adminId = data.adminId;
      if (!analytics.adminPerformance[adminId]) {
        analytics.adminPerformance[adminId] = {
          assignments: 0,
          avgScore: 0,
          scores: []
        };
      }
      analytics.adminPerformance[adminId].assignments++;
      if (data.assignmentScore) {
        analytics.adminPerformance[adminId].scores.push(data.assignmentScore);
      }
    });

    // Calculate averages
    Object.keys(analytics.adminPerformance).forEach(adminId => {
      const admin = analytics.adminPerformance[adminId];
      admin.avgScore = admin.scores.reduce((a, b) => a + b, 0) / admin.scores.length;
    });

    analytics.manualAssignmentRate = (analytics.manualAssignments / analytics.totalAssignments) * 100;

    return {
      success: true,
      analytics: analytics,
      timeRange: timeRange
    };

  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Failed to generate analytics');
  }
});

function getTimeRangeStart(timeRange) {
  const now = new Date();
  switch (timeRange) {
    case '1h':
      return new Date(now.getTime() - 60 * 60 * 1000);
    case '24h':
      return new Date(now.getTime() - 24 * 60 * 60 * 1000);
    case '7d':
      return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    case '30d':
      return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    default:
      return new Date(now.getTime() - 24 * 60 * 60 * 1000);
  }
}
```

## **📱 Implementation Phases**

### **Phase 1: Core Assignment System**
1. ✅ Implement admin status tracking Firebase function
2. ✅ Create auto-assignment algorithm with scoring
3. ✅ Set up workload calculation and management
4. ✅ Implement assignment notification system
5. ✅ Add audit trail for all assignments

### **Phase 2: Mobile App Integration**
1. ✅ Create order assignment service for mobile app
2. ✅ Implement real-time admin status updates
3. ✅ Add assignment stream listeners
4. ✅ Create admin availability monitoring
5. ✅ Integrate with existing order flow

### **Phase 3: Admin App Interface**
1. ✅ Build assignment management widget
2. ✅ Create admin status update interface
3. ✅ Add manual assignment capabilities
4. ✅ Implement assignment analytics dashboard
5. ✅ Add bulk assignment features

### **Phase 4: Advanced Features**
1. ✅ Implement geographic proximity calculation
2. ✅ Add specialization-based assignment
3. ✅ Create performance-based scoring
4. ✅ Add predictive workload balancing
5. ✅ Implement reassignment on admin offline

## **🚀 Success Metrics**

### **Assignment Efficiency**
- **Auto-Assignment Rate**: Target 90%+ automatic assignments
- **Assignment Speed**: Average under 30 seconds for assignment
- **Fair Distribution**: Workload variance under 20% across admins
- **Zero Manual Backlog**: No orders waiting >5 minutes for assignment

### **System Performance**
- **Real-Time Updates**: Status changes reflect within 2 seconds
- **Scalability**: Support 100+ concurrent admins
- **Reliability**: 99.9% uptime for assignment system
- **Resource Efficiency**: Minimal battery/network impact

### **Admin Experience**
- **Easy Status Management**: Simple interface for status updates
- **Clear Assignment Notifications**: Immediate feedback on new assignments
- **Workload Transparency**: Clear view of current workload and assignments
- **Performance Insights**: Analytics on assignment patterns and efficiency

## **🔧 Maintenance & Monitoring**

### **System Health Monitoring**
- Monitor auto-assignment success rates
- Track admin availability patterns
- Alert on unusual assignment failures
- Performance metrics collection

### **Load Balancing**
- Dynamic workload redistribution
- Peak hour management
- Geographic load balancing
- Emergency reassignment protocols

### **Error Recovery**
- Automatic retry for failed assignments
- Manual override capabilities
- Fallback to super admin notification
- System status alerts

---

**Note**: This auto-assignment system ensures intelligent, fair distribution of orders to available admins while maintaining parallel processing capabilities and prioritizing smart order IDs. The system provides real-time updates and comprehensive monitoring to ensure optimal performance and admin satisfaction.
