import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_admin/models/admin_user_model.dart';
import 'package:swiftwash_admin/providers/admin_provider.dart';
import 'package:swiftwash_admin/screens/store_management_screen.dart';
import 'package:swiftwash_admin/screens/admin_management_screen.dart';
import 'package:swiftwash_admin/widgets/admin_stats_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const StoreManagementScreen(),
    const AdminManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SwiftWash Admin'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Stores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admins',
          ),
        ],
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 0: // Dashboard
        return FloatingActionButton(
          onPressed: () {
            // TODO: Quick actions
          },
          backgroundColor: const Color(0xFF1E88E5),
          child: const Icon(Icons.add),
        );
      case 1: // Stores
        return FloatingActionButton(
          onPressed: () {
            _showCreateStoreDialog();
          },
          backgroundColor: const Color(0xFF1E88E5),
          child: const Icon(Icons.add_business),
        );
      case 2: // Admins
        return FloatingActionButton(
          onPressed: () {
            _showCreateAdminDialog();
          },
          backgroundColor: const Color(0xFF1E88E5),
          child: const Icon(Icons.person_add),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCreateStoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Store'),
        content: const Text('Navigate to store management to create a new store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 1; // Switch to stores tab
              });
            },
            child: const Text('Go to Stores'),
          ),
        ],
      ),
    );
  }

  void _showCreateAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Admin'),
        content: const Text('Navigate to admin management to create a new admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 2; // Switch to admins tab
              });
            },
            child: const Text('Go to Admins'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement logout logic
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final admin = adminProvider.currentAdmin;
        if (admin == null) {
          return const Center(
            child: Text('No admin data available'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${admin.name}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Role: ${admin.role.displayName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        admin.roleDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Stats Cards
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // FutureBuilder for stats
              FutureBuilder<Map<String, dynamic>>(
                future: adminProvider.getDashboardStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading stats: ${snapshot.error}'),
                    );
                  }

                  final stats = snapshot.data ?? {};
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      AdminStatsCard(
                        title: 'Total Stores',
                        value: stats['totalStores']?.toString() ?? '0',
                        icon: Icons.store,
                        color: Colors.blue,
                      ),
                      AdminStatsCard(
                        title: 'Active Stores',
                        value: stats['activeStores']?.toString() ?? '0',
                        icon: Icons.storefront,
                        color: Colors.green,
                      ),
                      AdminStatsCard(
                        title: 'Total Operators',
                        value: stats['totalOperators']?.toString() ?? '0',
                        icon: Icons.people,
                        color: Colors.orange,
                      ),
                      AdminStatsCard(
                        title: 'Total Orders',
                        value: stats['totalOrders']?.toString() ?? '0',
                        icon: Icons.shopping_bag,
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 1,
                child: Column(
                  children: [
                    if (admin.canManageStores)
                      ListTile(
                        leading: const Icon(Icons.add_business, color: Colors.blue),
                        title: const Text('Create New Store'),
                        subtitle: const Text('Add a new store to the system'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).pushNamed('/create-store');
                        },
                      ),
                    if (admin.isSuperAdmin)
                      ListTile(
                        leading: const Icon(Icons.person_add, color: Colors.green),
                        title: const Text('Create New Admin'),
                        subtitle: const Text('Add a new admin user'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).pushNamed('/create-admin');
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.analytics, color: Colors.purple),
                      title: const Text('View Reports'),
                      subtitle: const Text('Analytics and reports'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pushNamed('/reports');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}