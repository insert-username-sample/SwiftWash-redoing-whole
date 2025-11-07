import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/providers/order_provider.dart';
import 'package:swiftwash_operator/models/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProcessingStatusScreen extends StatefulWidget {
  final OrderModel order;

  const ProcessingStatusScreen({
    super.key,
    required this.order,
  });

  @override
  _ProcessingStatusScreenState createState() => _ProcessingStatusScreenState();
}

class _ProcessingStatusScreenState extends State<ProcessingStatusScreen> {
  String? _currentProcessingStatus;
  String _selectedStatus = '';
  final TextEditingController _notesController = TextEditingController();

  // Processing status options
  final List<Map<String, dynamic>> _processingStatuses = [
    {
      'value': 'sorting',
      'label': 'Sorting / Pre-Processing',
      'description': 'Sorting clothes by type and color',
      'icon': Icons.style,
      'color': Colors.orange,
    },
    {
      'value': 'washing',
      'label': 'Washing',
      'description': 'Machine washing in progress',
      'icon': Icons.local_laundry_service,
      'color': Colors.blue,
    },
    {
      'value': 'drying',
      'label': 'Drying',
      'description': 'Industrial drying process',
      'icon': Icons.dry_cleaning,
      'color': Colors.green,
    },
    {
      'value': 'ironing',
      'label': 'Ironing',
      'description': 'Steam ironing and folding',
      'icon': Icons.iron,
      'color': Colors.red,
    },
    {
      'value': 'quality_check',
      'label': 'Quality Check',
      'description': 'Final inspection and quality assurance',
      'icon': Icons.check_circle,
      'color': Colors.purple,
    },
    {
      'value': 'ready_for_delivery',
      'label': 'Ready for Delivery',
      'description': 'Quality check complete, packed for delivery',
      'icon': Icons.inventory,
      'color': Colors.teal,
    },
    {
      'value': 'facilities_maintenance',
      'label': 'Facilities Maintenance',
      'description': 'Equipment maintenance or facility cleaning',
      'icon': Icons.build,
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentProcessingStatus();
  }

  Future<void> _loadCurrentProcessingStatus() async {
    final status = await Provider.of<OrderProvider>(context, listen: false)
        .getCurrentProcessingStatus(widget.order.id);

    if (mounted) {
      setState(() {
        _currentProcessingStatus = status;
        if (status != null) {
          _selectedStatus = status.toLowerCase();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Management'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showProcessingHistory,
            tooltip: 'View History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Order Summary Card
          _buildOrderSummaryCard(),

          // Current Processing Status
          if (_currentProcessingStatus != null)
            _buildCurrentStatusCard(),

          // Processing Status Selection
          Expanded(
            child: _buildProcessingStatusGrid(),
          ),

          // Update Button
          if (_selectedStatus.isNotEmpty)
            _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Processing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.order.orderId}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Service: ${widget.order.serviceName}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getMainStatusColor(widget.order.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Notes Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Processing Notes (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add any processing notes or observations...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Processing Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _getProcessingStatusLabel(_currentProcessingStatus!),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStatusGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select New Processing Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: _processingStatuses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final status = _processingStatuses[index];
                final isSelected = _selectedStatus == status['value'];

                return _buildStatusCard(status, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> status, bool isSelected) {
    return Card(
      elevation: isSelected ? 6 : 2,
      color: isSelected ? status['color'].withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? status['color'] : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = status['value'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status['icon'],
                size: 32,
                color: status['color'],
              ),
              const SizedBox(height: 8),
              Text(
                status['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? status['color'] : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                status['description'],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
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

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _updateProcessingStatus,
        icon: const Icon(Icons.update, size: 20),
        label: const Text(
          'Update Processing Status',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProcessingStatus() async {
    if (_selectedStatus.isEmpty) return;

    final provider = Provider.of<OrderProvider>(context, listen: false);

    try {
      await provider.updateProcessingStatus(
        widget.order.id,
        _selectedStatus,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        operatorId: 'current-operator-id', // TODO: Add actual operator ID
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing status updated to ${_getProcessingStatusLabel(_selectedStatus)}'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the order details
        await _loadCurrentProcessingStatus();

        // Clear the notes after successful update
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showProcessingHistory() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final history = await provider.getProcessingHistory(widget.order.id);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Processing History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text('No processing history available'),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            final timestamp = entry['timestamp'] as Timestamp?;
                            final status = entry['status'] as String?;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(
                                    Icons.timelapse,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(_getProcessingStatusLabel(status ?? 'unknown')),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timestamp != null
                                          ? _formatTimestamp(timestamp)
                                          : 'Unknown time',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (entry['description'] != null)
                                      Text(
                                        entry['description'],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getProcessingStatusLabel(String status) {
    final statusData = _processingStatuses.firstWhere(
      (s) => s['value'] == status.toLowerCase(),
      orElse: () => {'label': status.toUpperCase()},
    );
    return statusData['label'];
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getMainStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'out_for_pickup':
        return Colors.orange;
      case 'picked_up':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.yellow.shade800;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
