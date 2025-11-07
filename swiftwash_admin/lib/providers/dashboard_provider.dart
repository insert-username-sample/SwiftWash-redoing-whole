import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _driverStats = [];
  Map<String, dynamic> _revenueData = {};

  bool get isLoading => _isLoading;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get recentOrders => _recentOrders;
  List<Map<String, dynamic>> get driverStats => _driverStats;
  Map<String, dynamic> get revenueData => _revenueData;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadDashboardStats(),
        _loadRecentOrders(),
        _loadDriverStats(),
        _loadRevenueData(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Get total orders
      final ordersSnapshot = await _firestore.collection('orders').get();
      final totalOrders = ordersSnapshot.docs.length;

      // Get orders by status
      final pendingOrders = ordersSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;
      final activeOrders = ordersSnapshot.docs
          .where((doc) => doc.data()['status'] == 'in_progress' ||
                          doc.data()['status'] == 'picked_up' ||
                          doc.data()['status'] == 'out_for_delivery')
          .length;
      final completedOrders = ordersSnapshot.docs
          .where((doc) => doc.data()['status'] == 'delivered' ||
                          doc.data()['status'] == 'completed')
          .length;

      // Get total users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Get total drivers
      final driversSnapshot = await _firestore.collection('drivers').get();
      final totalDrivers = driversSnapshot.docs.length;
      final activeDrivers = driversSnapshot.docs
          .where((doc) => doc.data()['isOnline'] == true)
          .length;

      // Calculate today's revenue
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todayOrders = ordersSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(startOfDay);
      });

      double todayRevenue = 0;
      for (final doc in todayOrders) {
        final data = doc.data();
        todayRevenue += (data['finalTotal'] ?? 0).toDouble();
      }

      // Calculate this month's revenue
      final startOfMonth = DateTime(today.year, today.month, 1);
      final monthOrders = ordersSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(startOfMonth);
      });

      double monthRevenue = 0;
      for (final doc in monthOrders) {
        final data = doc.data();
        monthRevenue += (data['finalTotal'] ?? 0).toDouble();
      }

      _dashboardStats = {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'activeOrders': activeOrders,
        'completedOrders': completedOrders,
        'totalUsers': totalUsers,
        'totalDrivers': totalDrivers,
        'activeDrivers': activeDrivers,
        'todayRevenue': todayRevenue,
        'monthRevenue': monthRevenue,
        'completionRate': totalOrders > 0 ? (completedOrders / totalOrders * 100) : 0,
        'driverUtilization': totalDrivers > 0 ? (activeDrivers / totalDrivers * 100) : 0,
      };

    } catch (e) {
      print('Error loading dashboard stats: $e');
      _dashboardStats = {};
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _recentOrders = ordersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'orderId': data['orderId'] ?? 'N/A',
          'status': data['status'] ?? 'unknown',
          'finalTotal': data['finalTotal'] ?? 0,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'customerName': data['customerName'] ?? 'Unknown',
          'serviceType': data['serviceType'] ?? 'N/A',
        };
      }).toList();

    } catch (e) {
      print('Error loading recent orders: $e');
      _recentOrders = [];
    }
  }

  Future<void> _loadDriverStats() async {
    try {
      final driversSnapshot = await _firestore.collection('drivers').get();

      _driverStats = driversSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'fullName': data['fullName'] ?? 'Unknown',
          'isOnline': data['isOnline'] ?? false,
          'totalOrders': data['totalOrders'] ?? 0,
          'completedOrders': data['completedOrders'] ?? 0,
          'rating': data['rating'] ?? 0,
          'status': data['status'] ?? 'pending',
          'lastActiveAt': (data['lastActiveAt'] as Timestamp?)?.toDate(),
        };
      }).toList();

      // Sort by online status and then by rating
      _driverStats.sort((a, b) {
        if (a['isOnline'] != b['isOnline']) {
          return b['isOnline'] ? 1 : -1; // Online drivers first
        }
        return (b['rating'] as double).compareTo(a['rating'] as double);
      });

    } catch (e) {
      print('Error loading driver stats: $e');
      _driverStats = [];
    }
  }

  Future<void> _loadRevenueData() async {
    try {
      final now = DateTime.now();
      final last30Days = List.generate(30, (index) {
        return now.subtract(Duration(days: 29 - index));
      });

      final revenueByDay = <String, double>{};

      for (final day in last30Days) {
        final startOfDay = DateTime(day.year, day.month, day.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final dayOrders = await _firestore
            .collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
            .where('status', whereIn: ['delivered', 'completed'])
            .get();

        double dayRevenue = 0;
        for (final doc in dayOrders.docs) {
          final data = doc.data();
          dayRevenue += (data['finalTotal'] ?? 0).toDouble();
        }

        final dayKey = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        revenueByDay[dayKey] = dayRevenue;
      }

      // Calculate revenue by service type
      final serviceRevenue = <String, double>{};
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: ['delivered', 'completed'])
          .get();

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final serviceType = data['serviceType'] ?? 'Other';
        final revenue = (data['finalTotal'] ?? 0).toDouble();

        serviceRevenue[serviceType] = (serviceRevenue[serviceType] ?? 0) + revenue;
      }

      _revenueData = {
        'dailyRevenue': revenueByDay,
        'serviceRevenue': serviceRevenue,
        'totalRevenue': revenueByDay.values.fold(0, (sum, value) => sum + value),
        'averageDailyRevenue': revenueByDay.values.fold(0, (sum, value) => sum + value) / 30,
      };

    } catch (e) {
      print('Error loading revenue data: $e');
      _revenueData = {};
    }
  }

  Future<Map<String, dynamic>> getOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final orders = ordersSnapshot.docs.map((doc) => doc.data()).toList();

      // Calculate analytics
      final totalRevenue = orders.fold<double>(0, (sum, order) {
        return sum + (order['finalTotal'] ?? 0).toDouble();
      });

      final orderCount = orders.length;
      final completedOrders = orders.where((order) =>
          order['status'] == 'delivered' || order['status'] == 'completed').length;

      final completionRate = orderCount > 0 ? (completedOrders / orderCount) * 100 : 0;

      // Group by service type
      final serviceBreakdown = <String, int>{};
      for (final order in orders) {
        final serviceType = order['serviceType'] ?? 'Other';
        serviceBreakdown[serviceType] = (serviceBreakdown[serviceType] ?? 0) + 1;
      }

      // Group by status
      final statusBreakdown = <String, int>{};
      for (final order in orders) {
        final status = order['status'] ?? 'unknown';
        statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
      }

      return {
        'totalRevenue': totalRevenue,
        'orderCount': orderCount,
        'completedOrders': completedOrders,
        'completionRate': completionRate,
        'serviceBreakdown': serviceBreakdown,
        'statusBreakdown': statusBreakdown,
        'averageOrderValue': orderCount > 0 ? totalRevenue / orderCount : 0,
      };

    } catch (e) {
      print('Error getting order analytics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getDriverAnalytics() async {
    try {
      final driversSnapshot = await _firestore.collection('drivers').get();
      final drivers = driversSnapshot.docs.map((doc) => doc.data()).toList();

      final totalDrivers = drivers.length;
      final activeDrivers = drivers.where((driver) => driver['isOnline'] == true).length;
      final approvedDrivers = drivers.where((driver) => driver['status'] == 'active').length;

      // Calculate average rating
      double totalRating = 0;
      int ratedDrivers = 0;
      for (final driver in drivers) {
        final rating = (driver['rating'] ?? 0).toDouble();
        if (rating > 0) {
          totalRating += rating;
          ratedDrivers++;
        }
      }
      final averageRating = ratedDrivers > 0 ? totalRating / ratedDrivers : 0;

      // Calculate total orders and completion rate
      int totalOrders = 0;
      int completedOrders = 0;
      for (final driver in drivers) {
        totalOrders += (driver['totalOrders'] ?? 0) as int;
        completedOrders += (driver['completedOrders'] ?? 0) as int;
      }

      final overallCompletionRate = totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0;

      return {
        'totalDrivers': totalDrivers,
        'activeDrivers': activeDrivers,
        'approvedDrivers': approvedDrivers,
        'averageRating': averageRating,
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'overallCompletionRate': overallCompletionRate,
        'driverUtilizationRate': totalDrivers > 0 ? (activeDrivers / totalDrivers) * 100 : 0,
      };

    } catch (e) {
      print('Error getting driver analytics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs.map((doc) => doc.data()).toList();

      final totalUsers = users.length;

      // Calculate user registration over time (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final recentUsers = users.where((user) {
        final createdAt = (user['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(thirtyDaysAgo);
      }).length;

      // Calculate average orders per user
      final ordersSnapshot = await _firestore.collection('orders').get();
      final totalOrders = ordersSnapshot.docs.length;
      final averageOrdersPerUser = totalUsers > 0 ? totalOrders / totalUsers : 0;

      return {
        'totalUsers': totalUsers,
        'recentUsers': recentUsers,
        'averageOrdersPerUser': averageOrdersPerUser,
        'userRetentionRate': 85.0, // Placeholder - would need more complex calculation
      };

    } catch (e) {
      print('Error getting user analytics: $e');
      return {};
    }
  }

  void refreshData() {
    loadDashboardData();
  }
}
