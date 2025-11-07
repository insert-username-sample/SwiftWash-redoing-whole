import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_operator/models/order_model.dart';
import 'package:swiftwash_operator/models/driver_model.dart';
import 'package:swiftwash_operator/providers/order_provider.dart';
import 'package:swiftwash_operator/services/driver_service.dart';
import 'package:swiftwash_operator/services/order_service.dart';
import 'package:swiftwash_operator/screens/order_details_screen.dart';
import 'package:swiftwash_operator/auth_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final OrderService _orderService = OrderService();
  final DriverService _driverService = DriverService();

  List<OrderModel> _searchResults = [];
  bool _isSearching = false;

  List<OrderModel> _pickedUpOrders = [];
  List<OrderModel> _outForPickupOrders = [];
  List<OrderModel> _outForDeliveryOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);

    // Load initial stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderStats();
      _initializeStreams();
    });
  }

  void _initializeStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Additional streams for new status sections
      FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'picked_up')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
            setState(() {
              _pickedUpOrders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
            });
          });

      FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'out_for_pickup')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
            setState(() {
              _outForPickupOrders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
            });
          });

      FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'out_for_delivery')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .listen((snapshot) {
            setState(() {
              _outForDeliveryOrders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
            });
          });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SwiftWash Operator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatsDialog,
          ),
          if (user != null && user.isAnonymous == false)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully logged out')),
                  );
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'New Orders'),
            Tab(text: 'Urgent'),
            Tab(text: 'Transit to Facility'),
            Tab(text: 'Picked Up'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Out for Delivery'),
            Tab(text: 'Out for Pickup'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
              controller: _tabController,
              children: [
                // New Orders
                _buildOrderList(context.read<OrderProvider>().newOrders, 'new'),
                // Urgent Orders
                _buildUrgentOrderList(),
                // Transit to Facility (Ongoing Processing)
                _buildOrderList(context.read<OrderProvider>().processingOrders, 'processing'),
                // Picked Up Orders
                _buildOrderList(_pickedUpOrders, 'picked_up'),
                // Ongoing (More Processing statuses)
                _buildOrderList(context.read<OrderProvider>().processingOrders.where((order) =>
                  order.status == 'washing' ||
                  order.status == 'cleaning' ||
                  order.status == 'ironing').toList(), 'ongoing'),
                // Out for Delivery
                _buildOrderList(_outForDeliveryOrders, 'out_for_delivery'),
                // Out for Pickup
                _buildOrderList(_outForPickupOrders, 'out_for_pickup'),
                // Completed Orders
                _buildOrderList(context.read<OrderProvider>().completedOrders, 'completed'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBulkOperationsDialog,
        child: const Icon(Icons.work),
        tooltip: 'Bulk Operations',
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String status, {bool isStream = false, String? streamStatus}) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading && !isStream) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orderProvider.error != null && !isStream) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${orderProvider.error}'),
                ElevatedButton(
                  onPressed: () => orderProvider.refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final displayOrders = isStream ? orders : orderProvider.orders.where((order) => order.status == status).toList();

        if (displayOrders.isEmpty && !isStream) {
          return Center(
            child: Text('No ${getStatusDisplayText(status)} orders found.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            orderProvider.refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: displayOrders.length,
            itemBuilder: (context, index) {
              final order = displayOrders[index];
              return OrderCard(
                order: order,
                onTap: () => _navigateToOrderDetails(order),
                onStatusUpdate: (newStatus) async {
                  // Check if it's a processing status that should update main status
                  if (['sorting', 'washing', 'drying', 'ironing', 'quality_check', 'ready_for_delivery', 'transit_to_facility', 'reached_facility', 'processing'].contains(newStatus.toLowerCase())) {
                    await orderProvider.updateProcessingStatus(
                      order.id,
                      newStatus,
                      description: orderProvider.getProcessingStatusDescription(newStatus),
                    );
                  } else {
                    await orderProvider.updateOrderStatus(order.id, newStatus);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUrgentOrderList() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final urgentOrders = orderProvider.getUrgentOrders() + orderProvider.getPriorityOrders();

        if (urgentOrders.isEmpty) {
          return const Center(
            child: Text('No urgent orders found.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: urgentOrders.length,
          itemBuilder: (context, index) {
            final order = urgentOrders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: order.priority == 'urgent' ? Colors.red.shade50 : Colors.orange.shade50,
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: order.priority == 'urgent' ? Colors.red : Colors.orange,
                ),
                title: Text('Order: ${order.orderId}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service: ${order.serviceName}'),
                    Text('Priority: ${order.priority.toUpperCase()}'),
                    Text('Created: ${_formatDate(order.createdAt.toDate())}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => _navigateToOrderDetails(order),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: order.id),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter Order ID or Customer Name',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _performSearch,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchResults = []);
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

  void _performSearch(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await context.read<OrderProvider>().searchOrders(query);
      setState(() => _searchResults = results);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Statistics'),
        content: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            final stats = orderProvider.stats;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatsChip('Today Orders', '${stats['todayOrders'] ?? 0}', Colors.blue),
                      _buildStatsChip('Pending', '${stats['pendingOrders'] ?? 0}', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatsChip('Completed', '${stats['completedToday'] ?? 0}', Colors.green),
                      _buildStatsChip('Revenue', '₹${stats['todayRevenue']?.toStringAsFixed(0) ?? '0'}', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Total Orders: ${stats['totalOrders'] ?? 0}'),
                  Text('Total Revenue: ₹${stats['totalRevenue']?.toStringAsFixed(0) ?? '0'}'),
                ],
              ),
            );
          },
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
                children: [
                  ElevatedButton(
                    onPressed: () => _bulkUpdateStatus(context, selectedOrders.toList(), 'processing'),
                    child: const Text('Mark as Processing'),
                  ),
                  ElevatedButton(
                    onPressed: () => _bulkUpdateStatus(context, selectedOrders.toList(), 'completed'),
                    child: const Text('Mark as Completed'),
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

  void _bulkUpdateStatus(BuildContext context, List<String> orderIds, String status) async {
    Navigator.of(context).pop();
    await context.read<OrderProvider>().bulkUpdateOrderStatus(orderIds, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated ${orderIds.length} orders to ${getStatusDisplayText(status)}')),
    );
  }

  void _bulkCancelOrders(BuildContext context, List<String> orderIds) async {
    // TODO: Show reason dialog
    Navigator.of(context).pop();
  }

  String getStatusDisplayText(String status) {
    switch (status) {
      case 'new':
        return 'New';
      case 'confirmed':
        return 'Confirmed';
      case 'driver_assigned':
        return 'Driver Assigned';
      case 'out_for_pickup':
        return 'Out for Pickup';
      case 'reached_pickup_location':
        return 'Reached Pickup Location';
      case 'picked_up':
        return 'Picked Up';
      case 'transit_to_facility':
        return 'Transit to Facility';
      case 'reached_facility':
        return 'Reached Facility';
      case 'processing':
        return 'Processing';
      case 'sorting':
        return 'Sorting';
      case 'washing':
        return 'Washing';
      case 'cleaning':
        return 'Cleaning';
      case 'ironing':
        return 'Ironing';
      case 'drying':
        return 'Drying';
      case 'quality_check':
        return 'Quality Check';
      case 'ready_for_delivery':
        return 'Ready for Delivery';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'reached_delivery_location':
        return 'Reached Delivery Location';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Context-aware actions helper
List<Map<String, String>> _getContextActions(String currentStatus) {
  switch (currentStatus) {
    case 'new':
      return [
        {'value': 'confirmed', 'label': 'Confirm Order'},
        {'value': 'assign_driver', 'label': 'Assign Driver'},
        {'value': 'cancelled', 'label': 'Cancel Order'},
      ];

    case 'confirmed':
      return [
        {'value': 'assign_driver', 'label': 'Assign Driver'},
        {'value': 'cancelled', 'label': 'Cancel Order'},
      ];

    case 'driver_assigned':
      return [
        {'value': 'out_for_pickup', 'label': 'Send Driver'},
        {'value': 'cancelled', 'label': 'Cancel Order'},
      ];

    case 'out_for_pickup':
      return [
        {'value': 'reached_pickup_location', 'label': 'Driver Arrived'},
        {'value': 'cancelled', 'label': 'Cancel Pickup'},
      ];

    case 'reached_pickup_location':
      return [
        {'value': 'picked_up', 'label': 'Mark as Picked Up'},
      ];

    case 'picked_up':
      return [
        {'value': 'transit_to_facility', 'label': 'Start Transit to Facility'},
        {'value': 'out_for_delivery', 'label': 'Return to Customer'},
        {'value': 'cancelled', 'label': 'Cancel Order'},
      ];

    case 'transit_to_facility':
      return [
        {'value': 'reached_facility', 'label': 'Reached Facility'},
        {'value': 'cancelled', 'label': 'Cancel Transit'},
      ];

    case 'reached_facility':
      return [
        {'value': 'processing', 'label': 'Start Processing'},
      ];

    case 'processing':
    case 'sorting':
      return [
        {'value': 'washing', 'label': 'Start Washing'},
        {'value': 'cancelled', 'label': 'Cancel Processing'},
      ];

    case 'washing':
      return [
        {'value': 'cleaning', 'label': 'Start Cleaning'},
        {'value': 'drying', 'label': 'Start Drying'},
      ];

    case 'cleaning':
      return [
        {'value': 'ironing', 'label': 'Start Ironing'},
      ];

    case 'ironing':
    case 'drying':
      return [
        {'value': 'quality_check', 'label': 'Quality Check'},
      ];

    case 'quality_check':
      return [
        {'value': 'ready_for_delivery', 'label': 'Ready for Delivery'},
        {'value': 'processing', 'label': 'Needs Rework'},
      ];

    case 'ready_for_delivery':
      return [
        {'value': 'out_for_delivery', 'label': 'Start Delivery'},
      ];

    case 'out_for_delivery':
      return [
        {'value': 'reached_delivery_location', 'label': 'Driver Arrived'},
        {'value': 'cancelled', 'label': 'Cancel Delivery'},
      ];

    case 'reached_delivery_location':
      return [
        {'value': 'delivered', 'label': 'Mark as Delivered'},
      ];

    case 'delivered':
    case 'cancelled':
      return [
        {'value': 'completed', 'label': 'Mark as Completed'},
      ];

    default:
      return [
        {'value': 'view_details', 'label': 'View Details'},
      ];
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final Function(String) onStatusUpdate;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          children: [
            Text('Order: ${order.orderId}'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(order.status).withOpacity(0.3)),
              ),
              child: Text(
                order.getStatusText(),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${order.serviceName}'),
            Text('Amount: ₹${order.totalAmount}'),
            Text('Created: ${_formatDate(order.createdAt.toDate())}'),
            if (order.getFormattedAddress().isNotEmpty)
              Text('Address: ${order.getFormattedAddress()}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onStatusUpdate,
          itemBuilder: (context) => _getContextActions(order.status)
              .map((action) => PopupMenuItem(value: action['value'], child: Text(action['label']!)))
              .toList(),
          child: const Icon(Icons.more_vert),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'out_for_pickup':
      case 'picked_up':
      case 'out_for_delivery':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
