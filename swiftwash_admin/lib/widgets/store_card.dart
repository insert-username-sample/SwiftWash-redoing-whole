import 'package:flutter/material.dart';
import 'package:swiftwash_admin/models/store_model.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const StoreCard({
    Key? key,
    required this.store,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with store name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      store.storeName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(store.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(store.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(store.status),
                      style: TextStyle(
                        color: _getStatusColor(store.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Store code
              Text(
                'Store Code: ${store.storeCode}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),

              // Owner information
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${store.ownerName} • ${store.ownerPhone}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Address
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${store.address}, ${store.city}, ${store.state} ${store.pincode}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Email
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store.ownerEmail,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Store details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Created',
                      _formatDate(store.createdAt),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Operators',
                      '${store.operatorIds.length}',
                      Icons.people,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action buttons
              if (onEdit != null || onDelete != null || onToggleStatus != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onToggleStatus != null)
                      TextButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          store.status == StoreStatus.active ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(
                          store.status == StoreStatus.active ? 'Deactivate' : 'Activate',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: store.status == StoreStatus.active
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(StoreStatus status) {
    switch (status) {
      case StoreStatus.active:
        return Colors.green;
      case StoreStatus.inactive:
        return Colors.grey;
      case StoreStatus.pending:
        return Colors.orange;
      case StoreStatus.suspended:
        return Colors.red;
    }
  }

  String _getStatusText(StoreStatus status) {
    switch (status) {
      case StoreStatus.active:
        return 'Active';
      case StoreStatus.inactive:
        return 'Inactive';
      case StoreStatus.pending:
        return 'Pending';
      case StoreStatus.suspended:
        return 'Suspended';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}