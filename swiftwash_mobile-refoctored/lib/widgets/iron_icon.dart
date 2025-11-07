import 'package:flutter/material.dart';

class IronIcon extends StatelessWidget {
  final double height;
  final double width;
  final Color? color;

  const IronIcon({super.key, this.height = 24, this.width = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        color ?? Colors.black,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        'assets/iron_minimal-removebg-preview.png',
        height: height,
        width: width,
      ),
    );
  }
}
