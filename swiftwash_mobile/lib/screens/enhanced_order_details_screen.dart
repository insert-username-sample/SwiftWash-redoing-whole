import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/models/enhanced_order_model.dart';
import 'package:swiftwash_mobile/services/enhanced_order_service.dart';
import 'package:swiftwash_mobile/widgets/order_timeline_widget.dart';
import 'package:intl/intl.dart';

class EnhancedOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const EnhancedOrderDetailsScreen({super.key, required this.orderId});

  @override
  _EnhancedOrderDetailsScreenState createState() => _EnhancedOrderDetailsScreenState();
}

class _EnhancedOrderDetailsScreenState extends State<EnhancedOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedOrderService _orderService = EnhancedOrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'Order Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<EnhancedOrderModel?>(
        stream: _orderService.getOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return _buildErrorWidget('Order not found');
          }

          final order = snapshot.data!;
          return _buildOrderDetails(order);
        },
      ),
    );
  }

  Widget _buildOrderDetails(EnhancedOrderModel order) {
    return Column(
      children: [
        _buildOrderHeader(order),
        _buildOrderProgress(order),
        Expanded(
          child: _buildOrderTabs(order),
        ),
      ],
    );
  }

  Widget _buildOrderHeader(EnhancedOrderModel order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.trackingCardBorderGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.serviceName,
                      style: AppTypography.subtitle,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: order.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: order.statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.statusIcon,
                      size: 16,
                      color: order.statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.statusDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: order.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Total Amount',
                  '₹${order.finalTotal.toStringAsFixed(2)}',
                  Icons.currency_rupee,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Order Date',
                  DateFormat('MMM d, yyyy').format(order.createdAt),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.brandBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.cardSubtitle,
              ),
              Text(
                value,
                style: AppTypography.cardTitle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderProgress(EnhancedOrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 12),
          Text(
            order.statusDescription,
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: order.progress,
            backgroundColor: order.statusColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(order.statusColor),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: ${(order.progress * 100).round()}%',
                style: AppTypography.cardSubtitle,
              ),
              Text(
                order.estimatedTime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: order.statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTabs(EnhancedOrderModel order) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: AppColors.brandBlue),
            ),
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            labelColor: AppColors.brandBlue,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: const [
              Tab(text: 'Items'),
              Tab(text: 'Timeline'),
              Tab(text: 'Details'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsTab(order),
                _buildTimelineTab(order),
                _buildDetailsTab(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(EnhancedOrderModel order) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: order.items.length,
      itemBuilder: (context, index) {
        final item = order.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppColors.brandBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Unknown Item',
                      style: AppTypography.cardTitle,
                    ),
                    Text(
                      'Quantity: ${item['quantity'] ?? 0}',
                      style: AppTypography.cardSubtitle,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${((item['price'] ?? 0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                style: AppTypography.cardTitle,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab(EnhancedOrderModel order) {
    return StreamBuilder<List<OrderStatusHistory>>(
      stream: _orderService.getOrderStatusHistory(order.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildTabErrorWidget('Failed to load timeline');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];
        return OrderTimelineWidget(
          statusHistory: history,
          currentStatus: order.status,
        );
      },
    );
  }

  Widget _buildDetailsTab(EnhancedOrderModel order) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDetailSection(
          'Customer Information',
          [
            _buildDetailItem('Name', order.customerInfo?['name'] ?? 'N/A'),
            _buildDetailItem('Phone', order.customerInfo?['phone'] ?? 'N/A'),
            _buildDetailItem('Email', order.customerInfo?['email'] ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailSection(
          'Delivery Address',
          [
            _buildDetailItem('Address', order.formattedAddress),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailSection(
          'Payment Information',
          [
            _buildDetailItem('Subtotal', '₹${order.itemTotal.toStringAsFixed(2)}'),
            _buildDetailItem('Swift Charge', '₹${order.swiftCharge.toStringAsFixed(2)}'),
            _buildDetailItem('Discount', '-₹${order.discount.toStringAsFixed(2)}'),
            const Divider(),
            _buildDetailItem('Total', '₹${order.finalTotal.toStringAsFixed(2)}', isBold: true),
          ],
        ),
        if (order.driverName != null) ...[
          const SizedBox(height: 16),
          _buildDetailSection(
            'Driver Information',
            [
              _buildDetailItem('Name', order.driverName!),
              _buildDetailItem('Phone', order.driverPhone ?? 'N/A'),
            ],
          ),
        ],
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDetailSection(
            'Notes',
            [
              _buildDetailItem('Special Instructions', order.notes!),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h3,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.cardSubtitle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isBold ? AppTypography.cardTitle : AppTypography.subtitle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
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

  Widget _buildTabErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: AppTypography.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
