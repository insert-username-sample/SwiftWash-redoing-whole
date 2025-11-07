import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/providers/operator_provider.dart';
import 'package:swiftwash_operator/models/operator_model.dart';

class CreateOperatorScreen extends StatefulWidget {
  const CreateOperatorScreen({super.key});

  @override
  _CreateOperatorScreenState createState() => _CreateOperatorScreenState();
}

class _CreateOperatorScreenState extends State<CreateOperatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _storeIdController = TextEditingController();

  OperatorRole _selectedRole = OperatorRole.regularOperator;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _storeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Operator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operator Information
              Text(
                'Operator Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter operator full name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter operator name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+91 ',
                  hintText: 'Enter 10-digit phone number',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length != 10) {
                    return 'Please enter valid 10-digit phone number';
                  }
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                    return 'Please enter valid Indian mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Role Selection
              Text(
                'Operator Role',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<OperatorRole>(
                      title: const Text('Regular Operator'),
                      subtitle: const Text('Can manage orders and basic operations'),
                      value: OperatorRole.regularOperator,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const Divider(),
                    RadioListTile<OperatorRole>(
                      title: const Text('Super Operator'),
                      subtitle: const Text('Can manage other operators and advanced features'),
                      value: OperatorRole.superOperator,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Store Assignment (Optional)
              Text(
                'Store Assignment (Optional)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _storeIdController,
                decoration: const InputDecoration(
                  labelText: 'Store ID',
                  hintText: 'Enter store ID to assign operator',
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Leave empty if operator should not be assigned to a specific store',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              ElevatedButton(
                onPressed: _isLoading ? null : _createOperator,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Operator'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createOperator() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final operatorProvider = Provider.of<OperatorProvider>(context, listen: false);
      final currentOperator = operatorProvider.currentOperator;

      // Check if current operator has permission to create operators
      if (currentOperator == null || !currentOperator.isSuperOperator) {
        throw Exception('Only super operators can create new operators');
      }

      final operator = await operatorProvider.createOperator(
        phoneNumber: '+91${_phoneController.text.trim()}',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        storeId: _storeIdController.text.trim().isEmpty ? null : _storeIdController.text.trim(),
        assignedBy: currentOperator.id,
        permissions: _getDefaultPermissions(_selectedRole),
      );

      if (mounted) {
        _showSuccessDialog(operator);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to create operator: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(OperatorModel operator) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Operator Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operator: ${operator.name}'),
            const SizedBox(height: 8),
            Text('Phone: ${operator.phoneNumber}'),
            const SizedBox(height: 8),
            Text('Role: ${operator.roleDisplayName}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operator ID: ${operator.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${operator.statusDisplayName}',
                    style: TextStyle(color: _getStatusColor(operator.status)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ The operator will need to verify their phone number to activate their account.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Map<String, dynamic> _getDefaultPermissions(OperatorRole role) {
    switch (role) {
      case OperatorRole.superOperator:
        return {
          'manage_operators': true,
          'manage_stores': true,
          'view_all_orders': true,
          'manage_settings': true,
          'view_analytics': true,
        };
      case OperatorRole.regularOperator:
        return {
          'manage_own_orders': true,
          'view_assigned_orders': true,
          'update_profile': true,
        };
    }
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
}