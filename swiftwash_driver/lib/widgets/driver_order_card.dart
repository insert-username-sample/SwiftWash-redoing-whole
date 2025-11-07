import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String, String) onStatusUpdate;
  final VoidCallback onViewDetails;

  const DriverOrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['orderId'] ?? 'N/A';
    final status = order['status'] ?? 'unknown';
    final customerName = order['customerName'] ?? 'Customer';
    final customerPhone = order['customerPhone'] ?? '';
    final pickupAddress = order['pickupAddress']?['formattedAddress'] ?? 'Pickup address not available';
    final deliveryAddress = order['deliveryAddress']?['formattedAddress'] ?? 'Delivery address not available';
    final finalTotal = (order['finalTotal'] ?? 0).toDouble();
    final createdAt = order['createdAt'] as Timestamp?;
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with order ID and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$orderId',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getStatusDisplayText(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Customer info
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                customerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (customerPhone.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  customerPhone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Order amount and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
              if (createdAt != null)
                Text(
                  DateFormat('MMM d, h:mm a').format(createdAt.toDate()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Addresses based on current status
          _buildAddressSection(status, pickupAddress, deliveryAddress),

          const SizedBox(height: 12),

          // Items summary
          if (items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getItemsSummary(items),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          _buildActionButtons(status),
        ],
      ),
    );
  }

  Widget _buildAddressSection(String status, String pickupAddress, String deliveryAddress) {
    switch (status) {
      case 'driver_assigned':
      case 'out_for_pickup':
      case 'reached_pickup_location':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pickupAddress,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );

      case 'picked_up':
      case 'out_for_delivery':
      case 'reached_delivery_location':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Delivery Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                deliveryAddress,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );

      default:
        return Column(
          children: [
            // Pickup address
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pickupAddress,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Delivery address
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      deliveryAddress,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionButtons(String status) {
    final actions = _getAvailableActions(status);

    if (actions.isEmpty) {
      return ElevatedButton.icon(
        onPressed: onViewDetails,
        icon: const Icon(Icons.visibility, size: 16),
        label: const Text('View Details'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          minimumSize: const Size(double.infinity, 40),
        ),
      );
    }

    return Column(
      children: [
        // Primary action buttons
        if (actions.length <= 2)
          Row(
            children: actions.map((action) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: () => onStatusUpdate(order['id'], action['status']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action['color'],
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text(action['label']),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return ElevatedButton(
                onPressed: () => onStatusUpdate(order['id'], action['status']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action['color'],
                ),
                child: Text(action['label']),
              );
            }).toList(),
          ),

        const SizedBox(height: 8),

        // View details button
        OutlinedButton.icon(
          onPressed: onViewDetails,
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 36),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(String status) {
    switch (status) {
      case 'driver_assigned':
        return [
          {
            'label': 'Start Pickup',
            'status': 'out_for_pickup',
            'color': const Color(0xFF1E88E5),
          },
        ];

      case 'out_for_pickup':
        return [
          {
            'label': 'Reached Pickup',
            'status': 'reached_pickup_location',
            'color': Colors.orange,
          },
        ];

      case 'reached_pickup_location':
        return [
          {
            'label': 'Picked Up',
            'status': 'picked_up',
            'color': Colors.green,
          },
        ];

      case 'picked_up':
        return [
          {
            'label': 'Start Delivery',
            'status': 'out_for_delivery',
            'color': const Color(0xFF1E88E5),
          },
        ];

      case 'out_for_delivery':
        return [
          {
            'label': 'Reached Delivery',
            'status': 'reached_delivery_location',
            'color': Colors.orange,
          },
        ];

      case 'reached_delivery_location':
        return [
          {
            'label': 'Delivered',
            'status': 'delivered',
            'color': Colors.green,
          },
        ];

      default:
        return [];
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'driver_assigned':
        return 'Assigned';
      case 'out_for_pickup':
        return 'Going to Pickup';
      case 'reached_pickup_location':
        return 'At Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'out_for_delivery':
        return 'Delivering';
      case 'reached_delivery_location':
        return 'At Delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'driver_assigned':
        return const Color(0xFF1E88E5);
      case 'out_for_pickup':
      case 'out_for_delivery':
        return const Color(0xFF1E88E5);
      case 'reached_pickup_location':
      case 'reached_delivery_location':
        return Colors.orange;
      case 'picked_up':
      case 'delivered':
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getItemsSummary(List<dynamic> items) {
    if (items.isEmpty) return 'No items';

    final itemCounts = <String, int>{};
    for (final item in items) {
      final name = item['name'] ?? 'Unknown';
      final quantity = item['quantity'] ?? 1;
      itemCounts[name] = (itemCounts[name] ?? 0) + quantity as int;
    }

    final summary = itemCounts.entries.map((e) => '${e.value}x ${e.key}').join(', ');
    return summary.length > 100 ? '${summary.substring(0, 100)}...' : summary;
  }
}
