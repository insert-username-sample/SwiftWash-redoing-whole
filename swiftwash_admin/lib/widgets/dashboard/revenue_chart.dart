import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_admin/providers/dashboard_provider.dart';
import 'package:swiftwash_admin/utils/app_theme.dart';

class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return const _LoadingRevenueChart();
        }

        final revenueData = dashboardProvider.revenueData;
        final dailyRevenue = revenueData['dailyRevenue'] as Map<String, dynamic>? ?? {};
        final serviceRevenue = revenueData['serviceRevenue'] as Map<String, dynamic>? ?? {};

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
                    'Revenue Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${revenueData['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Revenue Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _RevenueSummaryCard(
                      title: 'Today',
                      amount: revenueData['dailyRevenue']?.values.last?.toString() ?? '0',
                      change: '+12.5%',
                      changeColor: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RevenueSummaryCard(
                      title: 'This Month',
                      amount: revenueData['totalRevenue']?.toStringAsFixed(0) ?? '0',
                      change: '+8.2%',
                      changeColor: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RevenueSummaryCard(
                      title: 'Avg Daily',
                      amount: revenueData['averageDailyRevenue']?.toStringAsFixed(0) ?? '0',
                      change: '+5.1%',
                      changeColor: AppTheme.successColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Service Breakdown
              const Text(
                'Revenue by Service',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              if (serviceRevenue.isNotEmpty)
                ...serviceRevenue.entries.map((entry) {
                  final percentage = revenueData['totalRevenue'] != null && revenueData['totalRevenue'] > 0
                      ? (entry.value / revenueData['totalRevenue']) * 100
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceRevenueItem(
                      service: entry.key,
                      amount: entry.value.toStringAsFixed(0),
                      percentage: percentage,
                    ),
                  );
                }).toList()
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No revenue data available',
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Simple Bar Chart Placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Revenue Trend Chart',
                    style: TextStyle(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingRevenueChart extends StatelessWidget {
  const _LoadingRevenueChart();

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

class _RevenueSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String change;
  final Color changeColor;

  const _RevenueSummaryCard({
    required this.title,
    required this.amount,
    required this.change,
    required this.changeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹$amount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 12,
                color: changeColor,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 11,
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceRevenueItem extends StatelessWidget {
  final String service;
  final String amount;
  final double percentage;

  const _ServiceRevenueItem({
    required this.service,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            service,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            '₹$amount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
