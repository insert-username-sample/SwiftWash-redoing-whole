import 'package:flutter/material.dart';
import 'package:swiftwash_admin/models/admin_user_model.dart';

class AdminCard extends StatelessWidget {
  final AdminUserModel admin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onResetPassword;

  const AdminCard({
    Key? key,
    required this.admin,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onResetPassword,
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
              // Header with admin name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      admin.name,
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
                      color: _getStatusColor(admin.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(admin.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(admin.status),
                      style: TextStyle(
                        color: _getStatusColor(admin.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(admin.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getRoleColor(admin.role),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRoleText(admin.role),
                  style: TextStyle(
                    color: _getRoleColor(admin.role),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Contact information
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      admin.username,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    admin.phone,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Store assignment (if applicable)
              if (admin.storeId != null)
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Store ID: ${admin.storeId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Admin details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Created',
                      _formatDate(admin.createdAt),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Last Login',
                      admin.lastLogin != null ? _formatDate(admin.lastLogin!) : 'Never',
                      Icons.login,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Permissions preview (if any)
              if (admin.permissions != null && admin.permissions!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissions:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: admin.permissions!.entries
                          .where((entry) => entry.value == true)
                          .take(3) // Show only first 3 permissions
                          .map((entry) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                          .toList(),
                    ),
                    if (admin.permissions!.entries.where((entry) => entry.value == true).length > 3)
                      Text(
                        '+${admin.permissions!.entries.where((entry) => entry.value == true).length - 3} more',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),

              // Action buttons
              if (onEdit != null || onDelete != null || onToggleStatus != null || onResetPassword != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onResetPassword != null)
                      TextButton.icon(
                        onPressed: onResetPassword,
                        icon: const Icon(Icons.lock_reset, size: 16),
                        label: const Text('Reset PW'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    if (onToggleStatus != null)
                      TextButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          admin.status == AdminStatus.active ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(
                          admin.status == AdminStatus.active ? 'Deactivate' : 'Activate',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: admin.status == AdminStatus.active
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

  Color _getStatusColor(AdminStatus status) {
    switch (status) {
      case AdminStatus.active:
        return Colors.green;
      case AdminStatus.inactive:
        return Colors.grey;
      case AdminStatus.suspended:
        return Colors.red;
    }
  }

  String _getStatusText(AdminStatus status) {
    switch (status) {
      case AdminStatus.active:
        return 'Active';
      case AdminStatus.inactive:
        return 'Inactive';
      case AdminStatus.suspended:
        return 'Suspended';
    }
  }

  Color _getRoleColor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return Colors.purple;
      case AdminRole.storeAdmin:
        return Colors.blue;
      case AdminRole.supportAdmin:
        return Colors.orange;
    }
  }

  String _getRoleText(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.storeAdmin:
        return 'Store Admin';
      case AdminRole.supportAdmin:
        return 'Support Admin';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}