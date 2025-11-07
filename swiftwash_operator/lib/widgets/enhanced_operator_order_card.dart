import 'package:flutter/material.dart';
import 'package:swiftwash_operator/models/enhanced_operator_order_model.dart';
import 'package:swiftwash_operator/models/order_status_model.dart';
import 'package:intl/intl.dart';

class EnhancedOperatorOrderCard extends StatefulWidget {
  final EnhancedOperatorOrderModel order;
  final VoidCallback onTap;
  final Function(OrderStatus) onStatusUpdate;
  final VoidCallback onAssignDriver;
  final Function(String) onPriorityChange;
  final VoidCallback onCancel;

  const EnhancedOperatorOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onStatusUpdate,
    required this.onAssignDriver,
    required this.onPriorityChange,
    required this.onCancel,
  });

  @override
  _EnhancedOperatorOrderCardState createState() => _EnhancedOperatorOrderCardState();
}

class _EnhancedOperatorOrderCardState extends State<EnhancedOperatorOrderCard> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(),
          width: widget.order.needsAttention ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildOrderInfo(),
                const SizedBox(height: 12),
                _buildStatusAndProgress(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Order #${widget.order.orderId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.order.isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (widget.order.isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.order.serviceName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.order.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.order.statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.order.statusIcon,
                size: 16,
                color: widget.order.statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.order.statusDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.order.statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer info
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              widget.order.customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.phone, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              widget.order.customerPhone,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Items and amount
        Row(
          children: [
            Expanded(
              child: Text(
                widget.order.itemsSummary,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '₹${widget.order.finalTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
          ],
        ),

        // Address
        if (widget.order.formattedAddress.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.order.formattedAddress,
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
        ],

        // Driver info
        if (widget.order.driverName != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.delivery_dining, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Driver: ${widget.order.driverName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              if (widget.order.driverPhone != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.order.driverPhone!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],

        // Time info
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(widget.order.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (widget.order.estimatedCompletionTime != null) ...[
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'ETA: ${DateFormat('h:mm a').format(widget.order.estimatedCompletionTime!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.order.isOverdue ? Colors.red : Colors.grey,
                  fontWeight: widget.order.isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusAndProgress() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.order.statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.order.statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.order.statusDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.order.progress,
                  backgroundColor: widget.order.statusColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.order.statusColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(widget.order.progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.order.statusColor,
                ),
              ),
            ],
          ),
          if (widget.order.estimatedTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Estimated time: ${widget.order.estimatedTime}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final availableActions = widget.order.availableActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary actions row
        Row(
          children: [
            // Status update dropdown
            if (availableActions.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<OrderStatus>(
                    value: null,
                    hint: const Text(
                      'Update Status',
                      style: TextStyle(fontSize: 14),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: availableActions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.displayName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (status) {
                      if (status != null) {
                        widget.onStatusUpdate(status);
                      }
                    },
                  ),
                ),
              ),

            // Driver assignment
            if (widget.order.driverId == null && [
              OrderStatus.confirmed,
              OrderStatus.readyForDelivery,
              OrderStatus.outForDelivery,
            ].contains(widget.order.status))
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: widget.onAssignDriver,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Assign Driver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Secondary actions row
        Row(
          children: [
            // Priority setting
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showPriorityDialog(),
                icon: Icon(
                  widget.order.isUrgent ? Icons.priority_high : Icons.low_priority,
                  size: 16,
                  color: widget.order.isUrgent ? Colors.red : Colors.grey,
                ),
                label: Text(
                  widget.order.isUrgent ? 'High Priority' : 'Set Priority',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Cancel button
            if (widget.order.status != OrderStatus.cancelled && widget.order.status != OrderStatus.completed)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              ),

            // Track button for active deliveries
            if (widget.order.canTrack)
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to tracking screen
                  },
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: const Text('Track'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showPriorityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Order Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.low_priority, color: Colors.green),
              title: const Text('Normal'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onPriorityChange('normal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.priority_high, color: Colors.orange),
              title: const Text('High'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onPriorityChange('high');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Urgent'),
              onTap: () {
                Navigator.of(context).pop();
                widget.onPriorityChange('urgent');
              },
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
    );
  }

  Color _getBorderColor() {
    if (widget.order.needsAttention) {
      return widget.order.isUrgent ? Colors.red : Colors.orange;
    }
    return Colors.grey.shade300;
  }
}
