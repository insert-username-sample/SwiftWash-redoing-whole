import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class OrderSummaryWidget extends StatelessWidget {
  const OrderSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Order Summary',
        style: AppTypography.h2,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: 8),
              const Text('👕 Shirt x2'),
              const Text('👖 Jeans x1'),
              const SizedBox(height: 16),
              Text(
                'Address',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: 8),
              const Text('123 Main St, Anytown, USA'),
              const SizedBox(height: 16),
              Text(
                'Payment Summary',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: 8),
              const Text('Total: \$25.00'),
            ],
          ),
        ),
      ],
    );
  }
}
