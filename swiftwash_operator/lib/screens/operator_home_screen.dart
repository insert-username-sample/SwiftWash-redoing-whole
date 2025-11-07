import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/providers/operator_provider.dart';
import 'package:swiftwash_operator/models/operator_model.dart';
import 'package:swiftwash_operator/screens/operator_management_screen.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  _OperatorHomeScreenState createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<OperatorProvider>(
      builder: (context, operatorProvider, child) {
        final operator = operatorProvider.currentOperator;

        if (operator == null) {
          return const Scaffold(
            body: Center(
              child: Text('No operator data available'),
            ),
          );
        }

        // Different screens based on operator role
        final List<Widget> screens = operator.isSuperOperator
            ? [
                const DashboardScreen(),
                const OperatorManagementScreen(),
                const OrdersScreen(),
                const ProfileScreen(),
              ]
            : [
                const DashboardScreen(),
                const OrdersScreen(),
                const ProfileScreen(),
              ];

        final List<BottomNavigationBarItem> items = operator.isSuperOperator
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Operators',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ];

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome, ${operator.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // TODO: Implement notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleLogout,
              ),
            ],
          ),
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: items,
            type: operator.isSuperOperator ? BottomNavigationBarType.fixed : BottomNavigationBarType.fixed,
          ),
          floatingActionButton: operator.isSuperOperator && _currentIndex == 1
              ? FloatingActionButton(
                  onPressed: () => Navigator.of(context).pushNamed('/create-operator'),
                  child: const Icon(Icons.person_add),
                  tooltip: 'Create Operator',
                )
              : null,
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final operatorProvider = Provider.of<OperatorProvider>(context, listen: false);
    await operatorProvider.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OperatorProvider>(
      builder: (context, operatorProvider, child) {
        final operator = operatorProvider.currentOperator;

        if (operator == null) {
          return const Center(child: Text('Loading...'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _getRoleColor(operator.role),
                            child: Text(
                              operator.name.isNotEmpty ? operator.name[0].toUpperCase() : 'O',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${DateTime.now().hour < 12 ? 'morning' : DateTime.now().hour < 17 ? 'afternoon' : 'evening'}!',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  operator.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(operator.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(operator.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          operator.roleDisplayName,
                          style: TextStyle(
                            color: _getStatusColor(operator.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick stats
              Text(
                'Quick Stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Status',
                      operator.statusDisplayName,
                      _getStatusColor(operator.status),
                      Icons.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Role',
                      operator.roleDisplayName,
                      _getRoleColor(operator.role),
                      Icons.work,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent activity
              Text(
                'Recent Activity',
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
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('Activity will be shown here'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(OperatorRole role) {
    switch (role) {
      case OperatorRole.superOperator:
        return Colors.purple;
      case OperatorRole.regularOperator:
        return Colors.blue;
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

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Orders Screen - Coming Soon'),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OperatorProvider>(
      builder: (context, operatorProvider, child) {
        final operator = operatorProvider.currentOperator;

        if (operator == null) {
          return const Center(child: Text('Loading...'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: _getRoleColor(operator.role),
                        child: Text(
                          operator.name.isNotEmpty ? operator.name[0].toUpperCase() : 'O',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        operator.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        operator.phoneNumber,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(operator.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(operator.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          operator.roleDisplayName,
                          style: TextStyle(
                            color: _getStatusColor(operator.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Profile details
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildProfileItem('Email', operator.email),
                    const Divider(),
                    _buildProfileItem('Phone', operator.phoneNumber),
                    const Divider(),
                    _buildProfileItem('Status', operator.statusDisplayName),
                    const Divider(),
                    _buildProfileItem('Role', operator.roleDisplayName),
                    if (operator.storeId != null) ...[
                      const Divider(),
                      _buildProfileItem('Store ID', operator.storeId!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement edit profile
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(OperatorRole role) {
    switch (role) {
      case OperatorRole.superOperator:
        return Colors.purple;
      case OperatorRole.regularOperator:
        return Colors.blue;
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