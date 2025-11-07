import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/models/enhanced_operator_order_model.dart';
import 'package:swiftwash_operator/services/enhanced_operator_service.dart';
import 'package:swiftwash_operator/widgets/enhanced_operator_order_card.dart';
import 'package:swiftwash_operator/widgets/support_chat_widget.dart';
import 'package:swiftwash_operator/providers/support_chat_provider.dart';
import 'package:swiftwash_operator/models/order_status_model.dart';
import 'package:swiftwash_operator/models/support_chat_model.dart';
import 'package:intl/intl.dart';

class EnhancedOperatorHomeScreen extends StatefulWidget {
  const EnhancedOperatorHomeScreen({super.key});

  @override
  _EnhancedOperatorHomeScreenState createState() => _EnhancedOperatorHomeScreenState();
}

class _EnhancedOperatorHomeScreenState extends State<EnhancedOperatorHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedOperatorService _operatorService = EnhancedOperatorService();

  String _searchQuery = '';
  bool _isSearching = false;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _operatorService.getOrderStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SwiftWash Operator',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.black87),
            onPressed: _showStatisticsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 60),
          child: Column(
            children: [
              _buildStatisticsBar(),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: Color(0xFF1E88E5)),
                ),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'Attention'),
                  Tab(text: 'New'),
                  Tab(text: 'Pickup'),
                  Tab(text: 'Processing'),
                  Tab(text: 'Delivery'),
                  Tab(text: 'Completed'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_operatorService.getOrdersNeedingAttention()),
          _buildOrdersList(_operatorService.getOrdersByStatus(OrderStatus.pending)),
          _buildPickupOrdersList(),
          _buildProcessingOrdersList(),
          _buildDeliveryOrdersList(),
          _buildOrdersList(_operatorService.getOrdersByStatus(OrderStatus.completed)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Consumer<SupportChatProvider>(
            builder: (context, chatProvider, child) {
              return StreamBuilder<List<SupportChatSession>>(
                stream: chatProvider.waitingChatsStream,
                builder: (context, snapshot) {
                  final waitingCount = snapshot.data?.length ?? 0;

                  return Stack(
                    children: [
                      FloatingActionButton(
                        onPressed: _showSupportChat,
                        heroTag: 'support_chat',
                        tooltip: 'Customer Support',
                        backgroundColor: waitingCount > 0 ? Colors.orange : Colors.green,
                        child: const Icon(Icons.headset_mic),
                      ),
                      if (waitingCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              waitingCount > 9 ? '9+' : waitingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _showBulkOperationsDialog,
            icon: const Icon(Icons.work),
            label: const Text('Bulk Actions'),
            backgroundColor: const Color(0xFF1E88E5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar() {
    if (_statistics == null) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatChip(
            'Today',
            '${_statistics!['todayOrders'] ?? 0}',
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Pending',
            '${_statistics!['pendingOrders'] ?? 0}',
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Completed',
            '${_statistics!['completedToday'] ?? 0}',
            Colors.green,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Revenue',
            '₹${((_statistics!['todayRevenue'] ?? 0) as double).toStringAsFixed(0)}',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(Stream<List<EnhancedOperatorOrderModel>> ordersStream) {
    return StreamBuilder<List<EnhancedOperatorOrderModel>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        List<EnhancedOperatorOrderModel> orders = snapshot.data!;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          orders = orders.where((order) {
            return order.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   order.customerPhone.contains(_searchQuery);
          }).toList();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _loadStatistics();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return EnhancedOperatorOrderCard(
                order: order,
                onTap: () => _navigateToOrderDetails(order),
                onStatusUpdate: (newStatus) => _updateOrderStatus(order, newStatus),
                onAssignDriver: () => _showDriverAssignmentDialog(order),
                onPriorityChange: (priority) => _setOrderPriority(order, priority),
                onCancel: () => _showCancelDialog(order),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPickupOrdersList() {
    return StreamBuilder<List<EnhancedOperatorOrderModel>>(
      stream: _operatorService.getOrdersByStatus(OrderStatus.outForPickup),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorWidget(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pickupOrders = snapshot.data ?? [];

        // Also get reached pickup location orders
        return StreamBuilder<List<EnhancedOperatorOrderModel>>(
          stream: _operatorService.getOrdersByStatus(OrderStatus.reachedPickupLocation),
          builder: (context, reachedSnapshot) {
            if (reachedSnapshot.hasError) return _buildErrorWidget(reachedSnapshot.error.toString());
            if (reachedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reachedOrders = reachedSnapshot.data ?? [];
            final allPickupOrders = [...pickupOrders, ...reachedOrders];

            if (allPickupOrders.isEmpty) return _buildEmptyState();

            return RefreshIndicator(
              onRefresh: () async => await _loadStatistics(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: allPickupOrders.length,
                itemBuilder: (context, index) {
                  final order = allPickupOrders[index];
                  return EnhancedOperatorOrderCard(
                    order: order,
                    onTap: () => _navigateToOrderDetails(order),
                    onStatusUpdate: (newStatus) => _updateOrderStatus(order, newStatus),
                    onAssignDriver: () => _showDriverAssignmentDialog(order),
                    onPriorityChange: (priority) => _setOrderPriority(order, priority),
                    onCancel: () => _showCancelDialog(order),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProcessingOrdersList() {
    return StreamBuilder<List<EnhancedOperatorOrderModel>>(
      stream: _operatorService.getOrdersByStatus(OrderStatus.arrivedAtFacility),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorWidget(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final facilityOrders = snapshot.data ?? [];

        // Also get processing orders
        return StreamBuilder<List<EnhancedOperatorOrderModel>>(
          stream: _operatorService.getOrdersByStatus(OrderStatus.sorting),
          builder: (context, processingSnapshot) {
            if (processingSnapshot.hasError) return _buildErrorWidget(processingSnapshot.error.toString());
            if (processingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final processingOrders = processingSnapshot.data ?? [];
            final allProcessingOrders = [...facilityOrders, ...processingOrders];

            if (allProcessingOrders.isEmpty) return _buildEmptyState();

            return RefreshIndicator(
              onRefresh: () async => await _loadStatistics(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: allProcessingOrders.length,
                itemBuilder: (context, index) {
                  final order = allProcessingOrders[index];
                  return EnhancedOperatorOrderCard(
                    order: order,
                    onTap: () => _navigateToOrderDetails(order),
                    onStatusUpdate: (newStatus) => _updateOrderStatus(order, newStatus),
                    onAssignDriver: () => _showDriverAssignmentDialog(order),
                    onPriorityChange: (priority) => _setOrderPriority(order, priority),
                    onCancel: () => _showCancelDialog(order),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeliveryOrdersList() {
    return StreamBuilder<List<EnhancedOperatorOrderModel>>(
      stream: _operatorService.getOrdersByStatus(OrderStatus.outForDelivery),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorWidget(snapshot.error.toString());
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final deliveryOrders = snapshot.data ?? [];

        // Also get reached delivery location orders
        return StreamBuilder<List<EnhancedOperatorOrderModel>>(
          stream: _operatorService.getOrdersByStatus(OrderStatus.reachedDeliveryLocation),
          builder: (context, reachedSnapshot) {
            if (reachedSnapshot.hasError) return _buildErrorWidget(reachedSnapshot.error.toString());
            if (reachedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reachedOrders = reachedSnapshot.data ?? [];
            final allDeliveryOrders = [...deliveryOrders, ...reachedOrders];

            if (allDeliveryOrders.isEmpty) return _buildEmptyState();

            return RefreshIndicator(
              onRefresh: () async => await _loadStatistics(),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: allDeliveryOrders.length,
                itemBuilder: (context, index) {
                  final order = allDeliveryOrders[index];
                  return EnhancedOperatorOrderCard(
                    order: order,
                    onTap: () => _navigateToOrderDetails(order),
                    onStatusUpdate: (newStatus) => _updateOrderStatus(order, newStatus),
                    onAssignDriver: () => _showDriverAssignmentDialog(order),
                    onPriorityChange: (priority) => _setOrderPriority(order, priority),
                    onCancel: () => _showCancelDialog(order),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here when available',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetails(EnhancedOperatorOrderModel order) {
    // Navigate to order details screen
    // Implementation depends on your order details screen
  }

  Future<void> _updateOrderStatus(EnhancedOperatorOrderModel order, OrderStatus newStatus) async {
    try {
      await _operatorService.updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to ${newStatus.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _showDriverAssignmentDialog(EnhancedOperatorOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _operatorService.getAvailableDrivers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load drivers: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final drivers = snapshot.data ?? [];

          if (drivers.isEmpty) {
            return AlertDialog(
              title: const Text('No Drivers Available'),
              content: const Text('All drivers are currently busy. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Assign Driver'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(driver['name'] ?? 'Unknown Driver'),
                    subtitle: Text(driver['phone'] ?? 'No phone'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _assignDriver(order, driver['id']);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _assignDriver(EnhancedOperatorOrderModel order, String driverId) async {
    try {
      await _operatorService.assignDriver(order.id, driverId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver assigned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign driver: $e')),
        );
      }
    }
  }

  Future<void> _setOrderPriority(EnhancedOperatorOrderModel order, String priority) async {
    try {
      await _operatorService.setOrderPriority(order.id, priority);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority set to $priority')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set priority: $e')),
        );
      }
    }
  }

  void _showCancelDialog(EnhancedOperatorOrderModel order) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a cancellation reason')),
                );
                return;
              }

              Navigator.of(context).pop();
              await _cancelOrder(order, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(EnhancedOperatorOrderModel order, String reason) async {
    try {
      await _operatorService.cancelOrder(order.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Order ID, Customer Name, or Phone',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Statistics'),
        content: _statistics != null
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatRow('Total Orders', '${_statistics!['totalOrders'] ?? 0}'),
                    _buildStatRow('Today\'s Orders', '${_statistics!['todayOrders'] ?? 0}'),
                    _buildStatRow('Pending Orders', '${_statistics!['pendingOrders'] ?? 0}'),
                    _buildStatRow('Completed Today', '${_statistics!['completedToday'] ?? 0}'),
                    _buildStatRow('Today\'s Revenue', '₹${((_statistics!['todayRevenue'] ?? 0) as double).toStringAsFixed(0)}'),
                    _buildStatRow('Total Revenue', '₹${((_statistics!['totalRevenue'] ?? 0) as double).toStringAsFixed(0)}'),
                  ],
                ),
              )
            : const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showBulkOperationsDialog() {
    final selectedOrders = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bulk Operations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select orders and choose an action:'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => _bulkUpdateStatus(context, selectedOrders.toList(), OrderStatus.confirmed),
                    child: const Text('Confirm Orders'),
                  ),
                  ElevatedButton(
                    onPressed: () => _bulkUpdateStatus(context, selectedOrders.toList(), OrderStatus.readyForDelivery),
                    child: const Text('Mark Ready'),
                  ),
                  ElevatedButton(
                    onPressed: () => _bulkUpdateStatus(context, selectedOrders.toList(), OrderStatus.completed),
                    child: const Text('Mark Completed'),
                  ),
                  ElevatedButton(
                    onPressed: () => _bulkCancelOrders(context, selectedOrders.toList()),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cancel Orders'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _bulkUpdateStatus(BuildContext context, List<String> orderIds, OrderStatus status) async {
    if (orderIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders selected')),
      );
      return;
    }

    Navigator.of(context).pop();
    try {
      await _operatorService.bulkUpdateOrders(orderIds, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated ${orderIds.length} orders to ${status.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update orders: $e')),
        );
      }
    }
  }

  void _bulkCancelOrders(BuildContext context, List<String> orderIds) async {
    // Show reason dialog for bulk cancellation
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Cancellation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cancel ${orderIds.length} orders?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a cancellation reason')),
                );
                return;
              }

              Navigator.of(context).pop();
              // Implement bulk cancellation
              for (final orderId in orderIds) {
                try {
                  await _operatorService.cancelOrder(orderId, reason);
                } catch (e) {
                  print('Failed to cancel order $orderId: $e');
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cancelled ${orderIds.length} orders')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSupportChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SupportChatWidget(),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully logged out')),
      );
    }
  }
}
