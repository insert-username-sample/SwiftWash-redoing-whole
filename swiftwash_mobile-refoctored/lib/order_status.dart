import 'package:flutter/material.dart';

class OrderStatus {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  OrderStatus({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}
