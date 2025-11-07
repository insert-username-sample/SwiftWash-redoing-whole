import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class DynamicStepsWidget extends StatelessWidget {
  final String currentStatus;

  const DynamicStepsWidget({super.key, required this.currentStatus});

  Map<String, dynamic> _getDynamicFirstStep() {
    // Define dynamic first step based on current status
    final statusLower = currentStatus.toLowerCase().replaceAll('_', ' ');

    if ([
      'new', 'confirmed', 'driver_assigned',
      'out_for_pickup', 'reached_pickup_location', 'picked_up'
    ].contains(currentStatus)) {
      // Pickup Phase - Show current pickup progress
      if (currentStatus == 'picked_up') {
        return {
          'emoji': '✅',
          'label': 'Picked Up',
          'isCompleted': true,
        };
      } else if (['out_for_pickup', 'reached_pickup_location'].contains(currentStatus)) {
        return {
          'emoji': '🚗',
          'label': 'Out for Pickup',
          'isCompleted': false,
          'isActive': true,
        };
      } else {
        return {
          'emoji': '📋',
          'label': 'Order Confirmed',
          'isCompleted': false,
          'isActive': true,
        };
      }
    } else if ([
      'transit_to_facility', 'reached_facility', 'sorting', 'processing', 'washing', 'cleaning', 'ironing', 'drying'
    ].contains(currentStatus)) {
      // Processing Phase
      return {
        'emoji': '🧼',
        'label': 'Processing',
        'isCompleted': false,
        'isActive': true,
      };
    } else if (currentStatus == 'quality_check') {
      return {
        'emoji': '✨',
        'label': 'Quality Check',
        'isCompleted': false,
        'isActive': true,
      };
    } else if (['ready_for_delivery', 'out_for_delivery', 'reached_delivery_location'].contains(currentStatus)) {
      return {
        'emoji': '🚚',
        'label': 'Out for Delivery',
        'isCompleted': false,
        'isActive': true,
      };
    } else if (currentStatus == 'delivered') {
      return {
        'emoji': '✅',
        'label': 'Delivered',
        'isCompleted': true,
      };
    }

    // Default fallback
    return {
      'emoji': '🧺',
      'label': 'Processing',
      'isCompleted': false,
      'isActive': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dynamicStep = _getDynamicFirstStep();
    final bool isDelivered = currentStatus == 'delivered';
    final bool hasQualityCheck = ['quality_check', 'ready_for_delivery', 'out_for_delivery', 'delivered'].contains(currentStatus);
    final bool hasDelivery = ['ready_for_delivery', 'out_for_delivery', 'reached_delivery_location', 'delivered'].contains(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          // Progress Bar Background
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                // Dynamic progress
                Expanded(
                  flex: isDelivered ? 1 : (hasQualityCheck ? 2 : 3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (!hasQualityCheck) ...[
                  Expanded(flex: 1, child: Container()),
                  Expanded(flex: 1, child: Container()),
                ] else if (!hasDelivery) ...[
                  Expanded(flex: 1, child: Container()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Step 1: Dynamic (changes based on status)
              _buildStep(
                emoji: dynamicStep['emoji'],
                label: dynamicStep['label'],
                isCompleted: dynamicStep['isCompleted'] ?? false,
                isActive: dynamicStep['isActive'] ?? false,
              ),

              // Step 2: Processing & Cleaning
              _buildStep(
                emoji: '🧼',
                label: 'Processing',
                isCompleted: hasQualityCheck || hasDelivery || isDelivered,
                isActive: !hasQualityCheck && !hasDelivery && !isDelivered,
              ),

              // Step 3: Quality Check
              _buildStep(
                emoji: '✨',
                label: 'Quality Check',
                isCompleted: hasDelivery || isDelivered,
                isActive: currentStatus == 'quality_check',
              ),

              // Step 4: Delivery
              _buildStep(
                emoji: '🚚',
                label: 'Delivery',
                isCompleted: isDelivered,
                isActive: ['out_for_delivery', 'reached_delivery_location'].contains(currentStatus),
              ),

              // Step 5: Delivered
              _buildStep(
                emoji: '✅',
                label: 'Delivered',
                isCompleted: isDelivered,
                isActive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required String emoji,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    Color getStepColor() {
      if (isCompleted) return AppColors.brandGreen;
      if (isActive) return AppColors.brandBlue;
      return AppColors.textSecondary;
    }

    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.brandGreen.withOpacity(0.1)
                : isActive
                    ? AppColors.brandBlue.withOpacity(0.1)
                    : Colors.grey.shade100,
            border: Border.all(
              color: getStepColor(),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: getStepColor(),
            fontWeight: isCompleted || isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
