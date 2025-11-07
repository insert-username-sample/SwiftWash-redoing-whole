import 'package:flutter/material.dart';
import 'package:swiftwash_operator/models/operator_model.dart';

class OperatorCard extends StatelessWidget {
  final OperatorModel operator;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const OperatorCard({
    Key? key,
    required this.operator,
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
              // Header with operator name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      operator.name,
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
                      color: _getStatusColor(operator.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(operator.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(operator.status),
                      style: TextStyle(
                        color: _getStatusColor(operator.status),
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
                  color: _getRoleColor(operator.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getRoleColor(operator.role),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRoleText(operator.role),
                  style: TextStyle(
                    color: _getRoleColor(operator.role),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Contact information
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      operator.phoneNumber,
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
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      operator.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Store assignment (if applicable)
              if (operator.storeId != null)
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Store ID: ${operator.storeId}',
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

              // Operator details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Created',
                      _formatDate(operator.createdAt),
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Last Login',
                      operator.lastLogin != null ? _formatDate(operator.lastLogin!) : 'Never',
                      Icons.login,
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
                          operator.status == OperatorStatus.active ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(
                          operator.status == OperatorStatus.active ? 'Deactivate' : 'Activate',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: operator.status == OperatorStatus.active
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

  Color _getStatusColor(OperatorStatus status) {
    switch (status) {
      case OperatorStatus.active:
        return Colors.green;
      case OperatorStatus.inactive:
        return Colors.grey;
      case OperatorStatus.suspended:
        return Colors.red;
      case OperatorStatus.pending:
        return Colors.orange;
    }
  }

  String _getStatusText(OperatorStatus status) {
    switch (status) {
      case OperatorStatus.active:
        return 'Active';
      case OperatorStatus.inactive:
        return 'Inactive';
      case OperatorStatus.suspended:
        return 'Suspended';
      case OperatorStatus.pending:
        return 'Pending';
    }
  }

  Color _getRoleColor(OperatorRole role) {
    switch (role) {
      case OperatorRole.superOperator:
        return Colors.purple;
      case OperatorRole.regularOperator:
        return Colors.blue;
    }
  }

  String _getRoleText(OperatorRole role) {
    switch (role) {
      case OperatorRole.superOperator:
        return 'Super Operator';
      case OperatorRole.regularOperator:
        return 'Regular Operator';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}