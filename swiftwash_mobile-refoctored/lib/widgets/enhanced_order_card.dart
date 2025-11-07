import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/models/enhanced_order_model.dart';
import 'package:intl/intl.dart';

class EnhancedOrderCard extends StatelessWidget {
  final EnhancedOrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onTrack;
  final VoidCallback? onCancel;
  final VoidCallback? onReorder;
  final VoidCallback? onRate;

  const EnhancedOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onTrack,
    this.onCancel,
    this.onReorder,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                _buildStatusSection(),
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
              Text(
                'Order #${order.orderId}',
                style: AppTypography.h2,
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
    );
  }

  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.itemsSummary,
          style: AppTypography.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Total: ',
              style: AppTypography.subtitle,
            ),
            Text(
              '₹${order.finalTotal.toStringAsFixed(2)}',
              style: AppTypography.cardTitle,
            ),
            const Spacer(),
            Text(
              DateFormat('MMM d, h:mm a').format(order.createdAt),
              style: AppTypography.cardSubtitle,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: order.statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: order.statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.statusDescription,
            style: AppTypography.subtitle,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: order.progress,
                  backgroundColor: order.statusColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(order.statusColor),
                ),
              ),
              const SizedBox(width: 12),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onTrack != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onTrack,
              icon: const Icon(Icons.track_changes, size: 16),
              label: const Text('Track'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (onTrack != null) const SizedBox(width: 8),
        if (onCancel != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (onReorder != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onReorder,
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Reorder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        if (onRate != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Rate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
