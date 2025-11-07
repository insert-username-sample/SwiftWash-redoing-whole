import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_admin/providers/dashboard_provider.dart';
import 'package:swiftwash_admin/utils/app_theme.dart';

class DriverStatsCard extends StatelessWidget {
  const DriverStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const _LoadingDriverStatsCard();
        }

        final driverStats = dashboardProvider.driverStats;

        return Container(
          padding: const EdgeInsets.all(24),
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
                  const Text(
                    'Driver Performance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full driver list
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (driverStats.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No drivers available',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                )
              else
                ...driverStats.take(5).map((driver) => _DriverListItem(driver: driver)).toList(),

              const SizedBox(height: 16),

              // Driver Summary Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DriverSummaryItem(
                      label: 'Online',
                      value: '${driverStats.where((d) => d['isOnline'] == true).length}',
                      color: AppTheme.successColor,
                      icon: Icons.circle,
                    ),
                    _DriverSummaryItem(
                      label: 'Active',
                      value: '${driverStats.where((d) => d['status'] == 'active').length}',
                      color: AppTheme.infoColor,
                      icon: Icons.drive_eta,
                    ),
                    _DriverSummaryItem(
                      label: 'Pending',
                      value: '${driverStats.where((d) => d['status'] == 'pending').length}',
                      color: AppTheme.warningColor,
                      icon: Icons.schedule,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Performance Indicators
              const Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _PerformanceIndicator(
                label: 'Average Rating',
                value: _calculateAverageRating(driverStats),
                color: AppTheme.primaryColor,
              ),

              const SizedBox(height: 8),

              _PerformanceIndicator(
                label: 'Completion Rate',
                value: _calculateCompletionRate(driverStats),
                color: AppTheme.successColor,
              ),

              const SizedBox(height: 8),

              _PerformanceIndicator(
                label: 'Utilization',
                value: '${dashboardProvider.dashboardStats['driverUtilization']?.toStringAsFixed(1) ?? '0'}%',
                color: AppTheme.infoColor,
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateAverageRating(List<Map<String, dynamic>> drivers) {
    if (drivers.isEmpty) return 0.0;

    double totalRating = 0;
    int ratedDrivers = 0;

    for (final driver in drivers) {
      final rating = (driver['rating'] ?? 0).toDouble();
      if (rating > 0) {
        totalRating += rating;
        ratedDrivers++;
      }
    }

    return ratedDrivers > 0 ? totalRating / ratedDrivers : 0.0;
  }

  double _calculateCompletionRate(List<Map<String, dynamic>> drivers) {
    if (drivers.isEmpty) return 0.0;

    int totalOrders = 0;
    int completedOrders = 0;

    for (final driver in drivers) {
      totalOrders += (driver['totalOrders'] ?? 0) as int;
      completedOrders += (driver['completedOrders'] ?? 0) as int;
    }

    return totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
  }
}

class _LoadingDriverStatsCard extends StatelessWidget {
  const _LoadingDriverStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DriverListItem extends StatelessWidget {
  final Map<String, dynamic> driver;

  const _DriverListItem({required this.driver});

  @override
  Widget build(BuildContext context) {
    final isOnline = driver['isOnline'] ?? false;
    final status = driver['status'] ?? 'unknown';
    final rating = (driver['rating'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Online Status Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.successColor : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Driver Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: _getStatusColor(status),
            child: Text(
              (driver['fullName'] ?? 'D')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Driver Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['fullName'] ?? 'Unknown Driver',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 12,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${driver['completedOrders'] ?? 0} orders',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'approved':
        return AppTheme.infoColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
      case 'suspended':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}

class _DriverSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _DriverSummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

class _PerformanceIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: _getProgressValue(),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  double _getProgressValue() {
    if (value.contains('%')) {
      final percentage = double.tryParse(value.replaceAll('%', ''));
      return percentage != null ? percentage / 100 : 0.0;
    } else if (value.contains('/')) {
      // For ratings like 4.5/5
      final parts = value.split('/');
      if (parts.length == 2) {
        final current = double.tryParse(parts[0]);
        final total = double.tryParse(parts[1]);
        if (current != null && total != null && total > 0) {
          return current / total;
        }
      }
    } else {
      // For ratings out of 5
      final rating = double.tryParse(value);
      if (rating != null) {
        return rating / 5.0;
      }
    }
    return 0.0;
  }
}
