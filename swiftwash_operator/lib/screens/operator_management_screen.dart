import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/providers/operator_provider.dart';
import 'package:swiftwash_operator/models/operator_model.dart';
import 'package:swiftwash_operator/widgets/operator_card.dart';

class OperatorManagementScreen extends StatefulWidget {
  const OperatorManagementScreen({super.key});

  @override
  _OperatorManagementScreenState createState() => _OperatorManagementScreenState();
}

class _OperatorManagementScreenState extends State<OperatorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Suspended'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.of(context).pushNamed('/create-operator'),
            tooltip: 'Create Operator',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search operators...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),

          // Operator list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOperatorList(OperatorStatus.active),
                _buildOperatorList(OperatorStatus.active),
                _buildOperatorList(OperatorStatus.pending),
                _buildOperatorList(OperatorStatus.suspended),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/create-operator'),
        child: const Icon(Icons.person_add),
        tooltip: 'Create Operator',
      ),
    );
  }

  Widget _buildOperatorList(OperatorStatus status) {
    return Consumer<OperatorProvider>(
      builder: (context, operatorProvider, child) {
        return StreamBuilder<List<OperatorModel>>(
          stream: operatorProvider.getOperatorsByStatus(status),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final operators = snapshot.data ?? [];

            if (operators.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No operators found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: operators.length,
              itemBuilder: (context, index) {
                final operator = operators[index];
                return OperatorCard(
                  operator: operator,
                  onTap: () => _showOperatorDetails(operator),
                  onEdit: () => _editOperator(operator),
                  onDelete: () => _deleteOperator(operator),
                  onToggleStatus: () => _toggleOperatorStatus(operator),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showOperatorDetails(OperatorModel operator) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                operator.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Phone', operator.phoneNumber),
              _buildDetailRow('Email', operator.email),
              _buildDetailRow('Role', operator.roleDisplayName),
              _buildDetailRow('Status', operator.statusDisplayName),
              _buildDetailRow('Created', _formatDate(operator.createdAt)),
              if (operator.lastLogin != null)
                _buildDetailRow('Last Login', _formatDate(operator.lastLogin!)),
              if (operator.storeId != null)
                _buildDetailRow('Store ID', operator.storeId!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editOperator(OperatorModel operator) {
    // TODO: Implement edit operator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit operator: ${operator.name}')),
    );
  }

  void _deleteOperator(OperatorModel operator) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Operator'),
        content: Text('Are you sure you want to delete ${operator.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<OperatorProvider>(context, listen: false).deleteOperator(operator.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Operator ${operator.name} deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleOperatorStatus(OperatorModel operator) {
    final newStatus = operator.status == OperatorStatus.active ? OperatorStatus.inactive : OperatorStatus.active;
    Provider.of<OperatorProvider>(context, listen: false).updateOperatorStatus(operator.id, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Operator ${operator.name} ${newStatus == OperatorStatus.active ? 'activated' : 'deactivated'}')),
    );
  }
}