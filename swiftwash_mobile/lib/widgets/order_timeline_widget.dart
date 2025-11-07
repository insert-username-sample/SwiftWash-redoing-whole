import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/models/enhanced_order_model.dart';
import 'package:swiftwash_mobile/models/order_status_model.dart';
import 'package:intl/intl.dart';

class OrderTimelineWidget extends StatelessWidget {
  final List<OrderStatusHistory> statusHistory;
  final OrderStatus currentStatus;

  const OrderTimelineWidget({
    super.key,
    required this.statusHistory,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Combine and sort all statuses
    final allStatuses = _getAllStatusesWithHistory();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allStatuses.length,
      itemBuilder: (context, index) {
        final statusItem = allStatuses[index];
        final isLast = index == allStatuses.length - 1;
        final isCompleted = statusItem.timestamp != null;
        final isCurrent = statusItem.status == currentStatus && !isCompleted;

        return _buildTimelineItem(
          statusItem,
          isLast: isLast,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        );
      },
    );
  }

  List<_TimelineStatusItem> _getAllStatusesWithHistory() {
    // Get all possible statuses in order
    final allStatuses = OrderStatus.values;

    // Create timeline items
    final timelineItems = <_TimelineStatusItem>[];

    for (final status in allStatuses) {
      // Find if this status has been reached
      final historyItem = statusHistory.firstWhere(
        (h) => h.status == status,
        orElse: () => OrderStatusHistory(
          id: '',
          status: status,
          timestamp: DateTime.now(),
          changedBy: '',
        ),
      );

      // Check if this status has been completed
      final isCompleted = statusHistory.any((h) => h.status == status);

      timelineItems.add(_TimelineStatusItem(
        status: status,
        timestamp: isCompleted ? historyItem.timestamp : null,
        changedBy: isCompleted ? historyItem.changedBy : null,
        reason: isCompleted ? historyItem.reason : null,
      ));
    }

    return timelineItems;
  }

  Widget _buildTimelineItem(
    _TimelineStatusItem item, {
    required bool isLast,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and dot
        SizedBox(
          width: 60,
          child: Column(
            children: [
              // Status dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(item.status, isCompleted, isCurrent),
                  border: Border.all(
                    color: _getStatusBorderColor(item.status, isCompleted, isCurrent),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(item.status, isCompleted, isCurrent),
                  size: 12,
                  color: Colors.white,
                ),
              ),
              // Timeline line
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: isCompleted ? item.status.color.withOpacity(0.5) : Colors.grey.shade300,
                ),
            ],
          ),
        ),

        // Status content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getCardColor(isCompleted, isCurrent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCardBorderColor(item.status, isCompleted, isCurrent),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status title and time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.status.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(isCompleted, isCurrent),
                        ),
                      ),
                    ),
                    if (item.timestamp != null)
                      Text(
                        _formatTimestamp(item.timestamp!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Status description
                Text(
                  item.status.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _getTextColor(isCompleted, isCurrent).withOpacity(0.8),
                  ),
                ),

                // Current status indicator
                if (isCurrent) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.status.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: item.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'In Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Additional info for completed statuses
                if (isCompleted && item.changedBy != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Updated by: ${item.changedBy}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                // Reason if available
                if (isCompleted && item.reason != null && item.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.reason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status, bool isCompleted, bool isCurrent) {
    if (isCurrent) return status.color;
    if (isCompleted) return status.color;
    return Colors.grey.shade400;
  }

  Color _getStatusBorderColor(OrderStatus status, bool isCompleted, bool isCurrent) {
    if (isCurrent) return status.color.withOpacity(0.5);
    if (isCompleted) return status.color.withOpacity(0.3);
    return Colors.grey.shade300;
  }

  IconData _getStatusIcon(OrderStatus status, bool isCompleted, bool isCurrent) {
    if (isCurrent) return Icons.access_time;
    if (isCompleted) return Icons.check;
    return Icons.radio_button_unchecked;
  }

  Color _getCardColor(bool isCompleted, bool isCurrent) {
    if (isCurrent) return Colors.white;
    if (isCompleted) return Colors.grey.shade50;
    return Colors.grey.shade100;
  }

  Color _getCardBorderColor(OrderStatus status, bool isCompleted, bool isCurrent) {
    if (isCurrent) return status.color.withOpacity(0.3);
    if (isCompleted) return status.color.withOpacity(0.2);
    return Colors.grey.shade300;
  }

  Color _getTextColor(bool isCompleted, bool isCurrent) {
    if (isCurrent) return Colors.black87;
    if (isCompleted) return Colors.black87;
    return Colors.grey.shade600;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _TimelineStatusItem {
  final OrderStatus status;
  final DateTime? timestamp;
  final String? changedBy;
  final String? reason;

  _TimelineStatusItem({
    required this.status,
    this.timestamp,
    this.changedBy,
    this.reason,
  });
}
