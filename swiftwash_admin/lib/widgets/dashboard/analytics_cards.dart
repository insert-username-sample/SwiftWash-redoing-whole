import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_admin/providers/dashboard_provider.dart';
import 'package:swiftwash_admin/utils/app_theme.dart';

class AnalyticsCards extends StatelessWidget {
  const AnalyticsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const _LoadingAnalyticsCards();
        }

        final stats = dashboardProvider.dashboardStats;

        return Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Orders',
                value: stats['totalOrders']?.toString() ?? '0',
                icon: Icons.shopping_cart,
                color: AppTheme.primaryColor,
                subtitle: '${stats['completionRate']?.toStringAsFixed(1) ?? '0'}% completion rate',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AnalyticsCard(
                title: 'Active Orders',
                value: stats['activeOrders']?.toString() ?? '0',
                icon: Icons.local_shipping,
                color: AppTheme.infoColor,
                subtitle: '${stats['pendingOrders'] ?? 0} pending',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AnalyticsCard(
                title: 'Total Users',
                value: stats['totalUsers']?.toString() ?? '0',
                icon: Icons.people,
                color: AppTheme.successColor,
                subtitle: 'Registered customers',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AnalyticsCard(
                title: 'Active Drivers',
                value: '${stats['activeDrivers'] ?? 0}/${stats['totalDrivers'] ?? 0}',
                icon: Icons.drive_eta,
                color: AppTheme.warningColor,
                subtitle: '${stats['driverUtilization']?.toStringAsFixed(1) ?? '0'}% utilization',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LoadingAnalyticsCards extends StatelessWidget {
  const _LoadingAnalyticsCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: AppTheme.successColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
