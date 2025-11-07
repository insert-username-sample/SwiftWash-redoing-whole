import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class GradientProgressBar extends StatelessWidget {
  final double value;
  final Duration duration;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: value),
        duration: duration,
        builder: (context, value, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return AppColors.brandGradient.createShader(bounds);
            },
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      ),
    );
  }
}
