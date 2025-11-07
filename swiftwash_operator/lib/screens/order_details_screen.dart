import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:swiftwash_operator/models/order_model.dart';
import 'package:swiftwash_operator/models/driver_model.dart';
import 'package:swiftwash_operator/screens/driver_assignment_screen.dart';
import 'package:swiftwash_operator/screens/processing_status_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
  DriverModel? _assignedDriver;
  List<DocumentSnapshot> _statusHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (orderDoc.exists) {
        _order = OrderModel.fromFirestore(orderDoc);

        // Load assigned driver if exists
        if (_order!.driverId != null) {
          final driverDoc = await FirebaseFirestore.instance
              .collection('drivers')
              .doc(_order!.driverId!)
              .get();

          if (driverDoc.exists) {
            _assignedDriver = DriverModel.fromFirestore(driverDoc);
          }
        }

        // Load status history
        final historySnapshot = await orderDoc.reference
            .collection('statusHistory')
            .orderBy('timestamp', descending: true)
            .get();
        _statusHistory = historySnapshot.docs;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order details: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (_order == null) return;

    try {
      setState(() => _isLoading = true);

      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);

      // Update order status
      batch.update(orderRef, {
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Add status change to history
      final historyRef = orderRef.collection('statusHistory').doc();
      batch.set(historyRef, {
        'status': newStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': 'operator',
        'action': 'status_update',
      });

      await batch.commit();
      await _loadOrderDetails(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to ${newStatus.toUpperCase()}')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _manageProcessingStatus() async {
    if (_order == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingStatusScreen(order: _order!),
      ),
    );

    // Refresh order details after returning from processing screen
    await _loadOrderDetails();
  }

  Future<void> _assignDriver() async {
    if (_order == null) return;

    final driver = await Navigator.push<DriverModel>(
      context,
      MaterialPageRoute(
        builder: (context) => DriverAssignmentScreen(order: _order!),
      ),
    );

    if (driver != null) {
      setState(() => _assignedDriver = driver);
      await _loadOrderDetails(); // Refresh order data
    }
  }

  Future<void> _unassignDriver() async {
    if (_order == null || _assignedDriver == null) return;

    try {
      setState(() => _isLoading = true);

      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
      final driverRef = FirebaseFirestore.instance.collection('drivers').doc(_assignedDriver!.id);

      // Update order
      batch.update(orderRef, {
        'driverId': FieldValue.delete(),
        'status': 'new',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update driver
      batch.update(driverRef, {
        'currentOrderId': FieldValue.delete(),
        'status': 'available',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await _loadOrderDetails(); // Refresh data

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver unassigned successfully')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unassign driver: $e')),
      );
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => CancelOrderDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        setState(() => _isLoading = true);

        final batch = FirebaseFirestore.instance.batch();
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);

        batch.update(orderRef, {
          'status': 'cancelled',
          'cancelReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Add to status history
        final historyRef = orderRef.collection('statusHistory').doc();
        batch.set(historyRef, {
          'status': 'cancelled',
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          'changedBy': 'operator',
          'action': 'cancelled',
        });

        await batch.commit();
        await _loadOrderDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (_order != null)
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'cancel':
                    _cancelOrder();
                    break;
                  case 'priority':
                    _showPriorityDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'priority', child: Text('Set Priority')),
                const PopupMenuItem(value: 'cancel', child: Text('Cancel Order')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderHeader(),
                      const SizedBox(height: 16),
                      _buildOrderStatus(),
                      const SizedBox(height: 16),
                      _buildCustomerInfo(),
                      const SizedBox(height: 16),
                      _buildServiceDetails(),
                      const SizedBox(height: 16),
                      _buildDriverAssignment(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                      _buildStatusHistory(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order: ${_order!.orderId}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Created: ${_formatDate(_order!.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_order!.priority == 'urgent' || _order!.priority == 'high')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _order!.priority == 'urgent' ? Colors.red.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _order!.priority.toUpperCase(),
                  style: TextStyle(
                    color: _order!.priority == 'urgent' ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_order!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(_order!.status)),
              ),
              child: Text(
                _order!.getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(_order!.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_order!.customerInfo != null) ...[
              Text('Name: ${_order!.customerInfo!['name'] ?? 'N/A'}'),
              Text('Phone: ${_order!.customerInfo!['phone'] ?? 'N/A'}'),
            ],
            const SizedBox(height: 8),
            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_order!.getFormattedAddress()),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service Details', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Service: ${_order!.serviceName}'),
            Text('Amount: ₹${_order!.totalAmount}'),
            if (_order!.serviceItems != null && _order!.serviceItems!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._order!.serviceItems!.map((item) => Text('• $item')),
            ],
            if (_order!.specialInstructions != null && _order!.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Special Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_order!.specialInstructions!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAssignment() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_assignedDriver != null) ...[
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_assignedDriver!.name),
                        Text('Phone: ${_assignedDriver!.phone}'),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _unassignDriver,
                    child: const Text('Unassign'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ] else ...[
              const Text('No driver assigned'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _assignDriver,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Driver'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_order!.status == 'new')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus('processing'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Start Processing'),
                  ),
                if (_order!.status == 'processing')
                  ElevatedButton.icon(
                    onPressed: _manageProcessingStatus,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Manage Processing'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                if (_order!.status == 'processing')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus('picked_up'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Mark as Picked Up'),
                  ),
                if (_order!.status == 'picked_up')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus('out_for_delivery'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Out for Delivery'),
                  ),
                if (_order!.status == 'out_for_delivery' || _order!.status == 'picked_up')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus('completed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Mark as Completed'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistory() {
    if (_statusHistory.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status History', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._statusHistory.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.history,
                  color: Colors.grey,
                  size: 16,
                ),
                title: Text('${data['status'] ?? 'Unknown'}'),
                subtitle: Text(_formatDate(timestamp)),
                trailing: Text(data['changedBy'] ?? 'System'),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPriorityDialog() {
    final priorities = ['normal', 'high', 'urgent'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: priorities.map((priority) => RadioListTile<String>(
            title: Text(priority.toUpperCase()),
            value: priority,
            groupValue: _order!.priority,
            onChanged: (value) async {
              if (value != null) {
                await _updateOrderPriority(value);
                Navigator.of(context).pop();
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _updateOrderPriority(String priority) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'priority': priority,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      await _loadOrderDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update priority: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'picked_up':
      case 'out_for_delivery':
        return Colors.orange;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy hh:mm a').format(timestamp.toDate());
    }
    return 'Unknown';
  }
}

class CancelOrderDialog extends StatefulWidget {
  @override
  _CancelOrderDialogState createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: TextField(
        controller: _reasonController,
        decoration: const InputDecoration(
          labelText: 'Reason for cancellation',
          hintText: 'Enter cancellation reason...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_reasonController.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
