import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_admin/providers/admin_provider.dart';
import 'package:swiftwash_admin/providers/auth_provider.dart';
import 'package:swiftwash_admin/providers/dashboard_provider.dart';
import 'package:swiftwash_admin/utils/app_theme.dart';
import 'package:swiftwash_admin/widgets/dashboard/analytics_cards.dart';
import 'package:swiftwash_admin/widgets/dashboard/recent_orders_card.dart';
import 'package:swiftwash_admin/widgets/dashboard/driver_stats_card.dart';
import 'package:swiftwash_admin/widgets/dashboard/revenue_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final adminProvider = context.read<AdminProvider>();

    await Future.wait([
      dashboardProvider.loadDashboardData(),
      adminProvider.loadAllData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _selectedIndex == 0 ? _buildDashboardView() : _buildManagementView(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SwiftWash Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Text(
                    authProvider.getDisplayName(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.primaryTextColor),
          onPressed: _loadDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppTheme.primaryTextColor),
          onPressed: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Here\'s your business overview',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insights,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Analytics Cards
          const AnalyticsCards(),

          const SizedBox(height: 24),

          // Revenue Chart
          const RevenueChart(),

          const SizedBox(height: 24),

          // Recent Orders and Driver Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: const RecentOrdersCard(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const DriverStatsCard(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildManagementView() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              tabs: [
                Tab(text: 'Users', icon: Icon(Icons.people)),
                Tab(text: 'Drivers', icon: Icon(Icons.drive_eta)),
                Tab(text: 'Orders', icon: Icon(Icons.shopping_cart)),
                Tab(text: 'Settings', icon: Icon(Icons.settings)),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.secondaryTextColor,
              indicatorColor: AppTheme.primaryColor,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersManagement(),
                _buildDriversManagement(),
                _buildOrdersManagement(),
                _buildSettingsManagement(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersManagement() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = adminProvider.users;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Users Management (${users.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddUserDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserListItem(user);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriversManagement() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final drivers = adminProvider.drivers;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Drivers Management (${drivers.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showDriverActions(),
                    icon: const Icon(Icons.more_vert),
                    label: const Text('Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return _buildDriverListItem(driver);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersManagement() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = adminProvider.orders;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Text(
                'Orders Management (${orders.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderListItem(order);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Pricing Settings
          _buildSettingsCard(
            title: 'Pricing Configuration',
            icon: Icons.attach_money,
            onTap: () => _showPricingSettings(),
          ),

          // System Settings
          _buildSettingsCard(
            title: 'System Configuration',
            icon: Icons.settings_system_daydream,
            onTap: () => _showSystemSettings(),
          ),

          // Analytics Settings
          _buildSettingsCard(
            title: 'Analytics & Reports',
            icon: Icons.analytics,
            onTap: () => _showAnalyticsSettings(),
          ),

          // Security Settings
          _buildSettingsCard(
            title: 'Security Settings',
            icon: Icons.security,
            onTap: () => _showSecuritySettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh Data',
                  onTap: _loadDashboardData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.download,
                  label: 'Export Report',
                  onTap: _exportReport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.notifications,
                  label: 'Send Notification',
                  onTap: _sendNotification,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.backup,
                  label: 'Backup Data',
                  onTap: _backupData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            (user['fullName'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user['fullName'] ?? 'Unknown'),
        subtitle: Text(user['email'] ?? user['phoneNumber'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _editUser(user),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: user['isActive'] == true ? AppTheme.errorColor : Colors.grey,
              ),
              onPressed: () => _toggleUserStatus(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverListItem(Map<String, dynamic> driver) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(driver['status']),
          child: const Icon(Icons.drive_eta, color: Colors.white),
        ),
        title: Text(driver['fullName'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${driver['status'] ?? 'unknown'}'),
            Text('Orders: ${driver['totalOrders'] ?? 0}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _editDriver(driver),
            ),
            IconButton(
              icon: Icon(
                Icons.assignment,
                color: driver['currentOrderId'] != null ? AppTheme.successColor : Colors.grey,
              ),
              onPressed: () => _assignOrderToDriver(driver),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderListItem(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getOrderStatusColor(order['status']),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
        ),
        title: Text('Order #${order['orderId'] ?? 'N/A'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${order['status'] ?? 'unknown'}'),
            Text('₹${order['finalTotal'] ?? 0}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: AppTheme.primaryColor),
              onPressed: () => _viewOrderDetails(order),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _editOrderStatus(order),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  Color _getOrderStatusColor(String? status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
      case 'picked_up':
      case 'out_for_delivery':
        return AppTheme.infoColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
          icon: Icon(Icons.manage_accounts),
          label: 'Management',
        ),
      ],
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.secondaryTextColor,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickActionsMenu,
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.add),
    );
  }

  // Action Methods
  void _showLogoutDialog() {
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: () {
                      Navigator.of(context).pop();
                      _loadDashboardData();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionItem(
                    icon: Icons.analytics,
                    label: 'Reports',
                    onTap: () {
                      Navigator.of(context).pop();
                      _generateReport();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    icon: Icons.notifications,
                    label: 'Alerts',
                    onTap: () {
                      Navigator.of
