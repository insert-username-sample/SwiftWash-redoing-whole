import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/models/enhanced_order_model.dart';
import 'package:swiftwash_mobile/services/enhanced_order_service.dart';
import 'package:swiftwash_mobile/screens/enhanced_order_details_screen.dart';
import 'package:swiftwash_mobile/widgets/enhanced_order_card.dart';

class EnhancedOrdersScreen extends StatefulWidget {
  const EnhancedOrdersScreen({super.key});

  @override
  _EnhancedOrdersScreenState createState() => _EnhancedOrdersScreenState();
}

class _EnhancedOrdersScreenState extends State<EnhancedOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedOrderService _orderService = EnhancedOrderService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Orders',
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: AppColors.brandBlue),
            ),
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            labelColor: AppColors.brandBlue,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Processing'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_getActiveOrders()),
          _buildOrdersList(_getProcessingOrders()),
          _buildOrdersList(_getCompletedOrders()),
          _buildOrdersList(_getCancelledOrders()),
        ],
      ),
    );
  }

  Widget _buildOrdersList(Stream<List<EnhancedOrderModel>> ordersStream) {
    return StreamBuilder<List<EnhancedOrderModel>>(
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

        List<EnhancedOrderModel> orders = snapshot.data!;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          orders = orders.where((order) {
            return order.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   order.serviceName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh is handled by the stream
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return EnhancedOrderCard(
                order: order,
                onTap: () => _navigateToOrderDetails(order),
                onTrack: order.canTrack ? () => _navigateToTracking(order) : null,
                onCancel: order.canCancel ? () => _showCancelDialog(order) : null,
                onReorder: order.status == OrderStatus.completed ? () => _reorderItems(order) : null,
                onRate: order.status == OrderStatus.completed ? () => _showRatingDialog(order) : null,
              );
            },
          ),
        );
      },
    );
  }

  Stream<List<EnhancedOrderModel>> _getActiveOrders() {
    return _orderService.getUserOrders().map((orders) {
      return orders.where((order) {
        return order.status == OrderStatus.pending ||
               order.status == OrderStatus.confirmed ||
               order.status == OrderStatus.driverAssigned ||
               order.status == OrderStatus.outForPickup ||
               order.status == OrderStatus.reachedPickupLocation ||
               order.status == OrderStatus.pickedUp;
      }).toList();
    });
  }

  Stream<List<EnhancedOrderModel>> _getProcessingOrders() {
    return _orderService.getUserOrders().map((orders) {
      return orders.where((order) {
        return order.status == OrderStatus.transitToFacility ||
               order.status == OrderStatus.arrivedAtFacility ||
               order.status == OrderStatus.sorting ||
               order.status == OrderStatus.washing ||
               order.status == OrderStatus.drying ||
               order.status == OrderStatus.ironing ||
               order.status == OrderStatus.qualityCheck ||
               order.status == OrderStatus.readyForDelivery;
      }).toList();
    });
  }

  Stream<List<EnhancedOrderModel>> _getCompletedOrders() {
    return _orderService.getUserOrders().map((orders) {
      return orders.where((order) {
        return order.status == OrderStatus.outForDelivery ||
               order.status == OrderStatus.reachedDeliveryLocation ||
               order.status == OrderStatus.delivered ||
               order.status == OrderStatus.completed;
      }).toList();
    });
  }

  Stream<List<EnhancedOrderModel>> _getCancelledOrders() {
    return _orderService.getUserOrders().map((orders) {
      return orders.where((order) {
        return order.status == OrderStatus.cancelled ||
               order.status == OrderStatus.pickupFailed ||
               order.status == OrderStatus.deliveryFailed ||
               order.status == OrderStatus.issueReported;
      }).toList();
    });
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.subtitle,
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
            style: AppTypography.h2,
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here once you place them',
            style: AppTypography.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetails(EnhancedOrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedOrderDetailsScreen(orderId: order.id),
      ),
    );
  }

  void _navigateToTracking(EnhancedOrderModel order) {
    // Navigate to tracking screen
    // Implementation depends on your tracking screen
  }

  void _showCancelDialog(EnhancedOrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelOrder(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(EnhancedOrderModel order) async {
    try {
      await _orderService.cancelOrder(order.id, 'Customer requested cancellation');
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

  Future<void> _reorderItems(EnhancedOrderModel order) async {
    try {
      final newOrderId = await _orderService.reorderItems(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reorder: $e')),
        );
      }
    }
  }

  void _showRatingDialog(EnhancedOrderModel order) {
    int rating = 5;
    String review = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Your Experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Review (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => review = value,
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
                Navigator.of(context).pop();
                await _orderService.rateOrder(order.id, rating, review);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for your feedback!')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by Order ID or Service',
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
}
