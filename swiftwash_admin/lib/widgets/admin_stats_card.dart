import 'package:flutter/material.dart';

class AdminStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AdminStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onStoresTap;
  final VoidCallback? onAdminsTap;
  final VoidCallback? onRevenueTap;
  final VoidCallback? onOrdersTap;

  const AdminStatsGrid({
    Key? key,
    required this.stats,
    this.onStoresTap,
    this.onAdminsTap,
    this.onRevenueTap,
    this.onOrdersTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      children: [
        AdminStatsCard(
          title: 'Total Stores',
          value: '${stats['totalStores'] ?? 0}',
          icon: Icons.store,
          color: Colors.blue,
          onTap: onStoresTap,
        ),
        AdminStatsCard(
          title: 'Active Stores',
          value: '${stats['activeStores'] ?? 0}',
          icon: Icons.storefront,
          color: Colors.green,
          onTap: onStoresTap,
        ),
        AdminStatsCard(
          title: 'Total Admins',
          value: '${stats['totalAdmins'] ?? 0}',
          icon: Icons.admin_panel_settings,
          color: Colors.purple,
          onTap: onAdminsTap,
        ),
        AdminStatsCard(
          title: 'Active Admins',
          value: '${stats['activeAdmins'] ?? 0}',
          icon: Icons.people,
          color: Colors.orange,
          onTap: onAdminsTap,
        ),
        AdminStatsCard(
          title: 'Total Revenue',
          value: '₹${stats['totalRevenue'] ?? 0}',
          icon: Icons.currency_rupee,
          color: Colors.green,
          onTap: onRevenueTap,
        ),
        AdminStatsCard(
          title: 'Total Orders',
          value: '${stats['totalOrders'] ?? 0}',
          icon: Icons.shopping_cart,
          color: Colors.blue,
          onTap: onOrdersTap,
        ),
        AdminStatsCard(
          title: 'Pending Stores',
          value: '${stats['pendingStores'] ?? 0}',
          icon: Icons.pending,
          color: Colors.orange,
          onTap: onStoresTap,
        ),
        AdminStatsCard(
          title: 'Suspended Stores',
          value: '${stats['suspendedStores'] ?? 0}',
          icon: Icons.warning,
          color: Colors.red,
          onTap: onStoresTap,
        ),
      ],
    );
  }
}

class AdminActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AdminActivityCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final VoidCallback? onViewAll;

  const AdminActivityList({
    Key? key,
    required this.activities,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length > 5 ? 5 : activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return AdminActivityCard(
              title: activity['title'] ?? 'Unknown Activity',
              subtitle: activity['subtitle'] ?? '',
              time: _formatTime(activity['timestamp']),
              icon: _getActivityIcon(activity['type'] ?? 'general'),
              color: _getActivityColor(activity['type'] ?? 'general'),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return 'Unknown';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'store_created':
        return Icons.store;
      case 'store_updated':
        return Icons.edit;
      case 'admin_created':
        return Icons.person_add;
      case 'admin_login':
        return Icons.login;
      case 'password_reset':
        return Icons.lock_reset;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'store_created':
        return Colors.green;
      case 'store_updated':
        return Colors.blue;
      case 'admin_created':
        return Colors.purple;
      case 'admin_login':
        return Colors.orange;
      case 'password_reset':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}