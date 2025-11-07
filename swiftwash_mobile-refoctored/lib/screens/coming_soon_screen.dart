import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Plans'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 100,
              color: AppColors.brandBlue,
            ),
            const SizedBox(height: 20),
            Text(
              'This feature is under construction.',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 10),
            Text(
              'We are working hard to bring it to you soon!',
              style: AppTypography.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
