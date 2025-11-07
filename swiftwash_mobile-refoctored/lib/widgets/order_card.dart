import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final String items;
  final String price;
  final String time;
  final VoidCallback onTrack;
  final VoidCallback? onReorder;
  final VoidCallback? onCall;
  final Map<String, dynamic>? orderData;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.status,
    required this.items,
    required this.price,
    required this.time,
    required this.onTrack,
    this.onReorder,
    this.onCall,
    this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDetails(),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            orderId,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String emoji;
    String displayStatus = _formatStatusText(status);

    // If we have currentProcessingStatus, use it for more detailed status
    if (status.toLowerCase() == 'processing' || status.toLowerCase().contains('processing')) {
      final processingStatus = _getCurrentProcessingStatus();
      if (processingStatus.isNotEmpty) {
        displayStatus = processingStatus;
        // Update color and emoji based on processing status
        switch (processingStatus.toLowerCase()) {
          case 'sorting clothes':
            color = Colors.blue.shade800;
            emoji = '📋';
            break;
          case 'washing in progress':
            color = Colors.blue;
            emoji = '🌀';
            break;
          case 'drying clothes':
            color = Colors.lightBlue;
            emoji = '💨';
            break;
          case 'cleaning items':
            color = Colors.cyan;
            emoji = '🧼';
            break;
          case 'ironing clothes':
            color = Colors.grey.shade700;
            emoji = '👔';
            break;
          case 'quality check':
          case 'sure pass clothes quality checking':
            color = Colors.purple;
            emoji = '🔍';
            break;
          default:
            color = Colors.blue.shade800;
            emoji = '⚙️';
        }
      } else {
        // Default processing color and emoji
        color = Colors.blue.shade800;
        emoji = '⚙️';
      }
      // Return early for processing status
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Text(
              displayStatus,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      );
    }

    switch (status.toLowerCase()) {
      // Initial Phase
      case 'new':
        color = Colors.blue;
        emoji = '📝';
        break;
      case 'confirmed':
        color = Colors.lightBlue;
        emoji = '✅';
        break;
      case 'driver_assigned':
        color = Colors.teal;
        emoji = '👨‍🚗';
        break;

      // Pickup Phase
      case 'out_for_pickup':
        color = Colors.orange;
        emoji = '🚶';
        break;
      case 'reached_pickup_location':
        color = Colors.deepOrange;
        emoji = '📍';
        break;
      case 'picked_up':
        color = Colors.green;
        emoji = '📦';
        break;

      // Transit Phase
      case 'transit_to_facility':
        color = Colors.yellow.shade800;
        emoji = '🚐';
        break;
      case 'reached_facility':
        color = Colors.brown;
        emoji = '🏭';
        break;

      // Processing Phase
      case 'processing':
      case 'sorting':
        color = Colors.blue.shade800;
        emoji = '⚙️';
        break;
      case 'washing':
        color = Colors.blue;
        emoji = '🌀';
        break;
      case 'cleaning':
        color = Colors.cyan;
        emoji = '🧼';
        break;
      case 'ironing':
        color = Colors.grey.shade700;
        emoji = '👔';
        break;
      case 'drying':
        color = Colors.lightBlue;
        emoji = '💨';
        break;
      case 'quality_check':
        color = Colors.purple;
        emoji = '🔍';
        break;
      case 'ready_for_delivery':
        color = Colors.deepPurple;
        emoji = '📋';
        break;

      // Delivery Phase
      case 'out_for_delivery':
        color = Colors.orange;
        emoji = '🚚';
        break;
      case 'reached_delivery_location':
        color = Colors.deepOrange;
        emoji = '🏁';
        break;
      case 'delivered':
        color = Colors.green;
        emoji = '✅';
        break;

      // Special Cases
      case 'cancelled':
        color = Colors.red.withOpacity(0.7);
        emoji = '❌';
        break;
      case 'returned':
        color = Colors.red.shade600;
        emoji = '↩️';
        break;
      case 'issue_reported':
        color = Colors.red.shade800;
        emoji = '🚨';
        break;
      case 'pickup_failed':
        color = Colors.red.shade600;
        emoji = '⚠️';
        break;
      case 'failed':
        color = Colors.red.shade600;
        emoji = '❌';
        break;
      default:
        color = Colors.grey;
        emoji = '⏳';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(
            displayStatus,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatStatusText(String status) {
    // Format snake_case to Title Case
    return status.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getCurrentProcessingStatus() {
    if (orderData != null) {
      final processingStatus = orderData!['currentProcessingStatus'] as String?;
      if (processingStatus != null && processingStatus.isNotEmpty) {
        switch (processingStatus.toLowerCase()) {
          case 'sorting':
            return 'Sorting Clothes';
          case 'washing':
            return 'Washing in Progress';
          case 'drying':
            return 'Drying Clothes';
          case 'cleaning':
            return 'Cleaning Items';
          case 'ironing':
            return 'Ironing Clothes';
          case 'quality_check':
            return 'Quality Check';
          case 'ready_for_delivery':
            return 'Ready for Delivery';
          case 'arrived_at_facility':
            return 'Arrived at Facility';
          case 'transit_to_facility':
            return 'In Transit to Facility';
          default:
            return processingStatus.replaceAll('_', ' ').split(' ').map((word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
            ).join(' ');
        }
      }
    }
    return '';
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(FontAwesomeIcons.tshirt, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            const Text('x 3'),
            const SizedBox(width: 16),
            const Icon(FontAwesomeIcons.userTie, color: Colors.blue, size: 20),
            const SizedBox(width: 4),
            const Text('x 2'),
            const SizedBox(width: 16),
            const Icon(FontAwesomeIcons.vest, color: Colors.brown, size: 20),
            const SizedBox(width: 4),
            const Text('x 1'),
            const Spacer(),
            Text(
              '₹$price',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.watch_later_outlined, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(time, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (status == 'Cancelled' || status == 'Pickup Failed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(status == 'Cancelled' ? FontAwesomeIcons.timesCircle : FontAwesomeIcons.exclamationCircle, size: 16),
          label: Text(status == 'Cancelled' ? 'Cancelled' : 'Failed', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.grey,
            backgroundColor: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (onReorder == null)
          SizedBox(
            width: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.bookingButtonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: onTrack,
                icon: const Icon(FontAwesomeIcons.mapMarkerAlt, size: 16, color: Colors.white),
                label: const Text('Track Order', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: 150,
            child: ElevatedButton.icon(
              onPressed: onReorder,
              icon: const Icon(FontAwesomeIcons.redo, size: 16),
              label: const Text('Reorder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        const Spacer(),
        if (onCall != null)
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.green,
            child: IconButton(
              onPressed: onCall,
              icon: const Icon(FontAwesomeIcons.phone, size: 20, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
