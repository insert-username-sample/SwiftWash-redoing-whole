import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/order_status.dart';

class DynamicCardWidget extends StatelessWidget {
  final OrderStatus status;

  const DynamicCardWidget({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              status.icon,
              size: 48,
              color: AppColors.brandBlue,
            ),
            const SizedBox(height: 16),
            Text(
              status.title,
              style: AppTypography.h2,
            ),
            const SizedBox(height: 8),
            Text(
              status.subtitle,
              style: AppTypography.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
