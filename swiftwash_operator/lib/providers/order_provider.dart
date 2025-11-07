import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:swiftwash_operator/models/order_model.dart';
import 'package:swiftwash_operator/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  List<OrderModel> _newOrders = [];
  List<OrderModel> _processingOrders = [];
  List<OrderModel> _completedOrders = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> _stats = {};

  List<OrderModel> get orders => _orders;
  List<OrderModel> get newOrders => _newOrders;
  List<OrderModel> get processingOrders => _processingOrders;
  List<OrderModel> get completedOrders => _completedOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;

  // Stream subscriptions
  StreamSubscription<List<OrderModel>>? _allOrdersSubscription;
  StreamSubscription<List<OrderModel>>? _newOrdersSubscription;
  StreamSubscription<List<OrderModel>>? _processingOrdersSubscription;
  StreamSubscription<List<OrderModel>>? _completedOrdersSubscription;

  OrderProvider() {
    _initializeStreams();
  }

  Set<String> _notifiedOrders = {}; // Track orders we've already notified for

  void _initializeStreams() {
    // All orders stream
    _allOrdersSubscription = _orderService.getAllOrders().listen(
          (orders) {
            _orders = orders;

            // Check for new orders that need notification
            final newOrders = orders.where((order) =>
                order.status == 'new' &&
                !_notifiedOrders.contains(order.id));

            // Trigger ringing for new urgent orders
            for (final order in newOrders) {
              _triggerNewOrderNotification(order);
              _notifiedOrders.add(order.id);
            }

            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );

    // New orders stream
    _newOrdersSubscription = _orderService.getOrdersByStatus('new').listen(
          (orders) {
            _newOrders = orders;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );

    // Processing orders stream
    _processingOrdersSubscription = _orderService.getOrdersByStatus('processing').listen(
          (orders) {
            _processingOrders = orders;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );

    // Completed orders stream
    _completedOrdersSubscription = _orderService.getOrdersByStatus('completed').listen(
          (orders) {
            _completedOrders = orders;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.updateOrderStatus(orderId, newStatus);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Assign driver to order
  Future<void> assignDriverToOrder(String orderId, String driverId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.assignDriverToOrder(orderId, driverId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get order statistics
  Future<void> loadOrderStats() async {
    try {
      _isLoading = true;
      notifyListeners();

      _stats = await _orderService.getOrderStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search orders
  Future<List<OrderModel>> searchOrders(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      return await _orderService.searchOrders(query.trim());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Bulk update order status
  Future<void> bulkUpdateOrderStatus(List<String> orderIds, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.bulkUpdateOrderStatus(orderIds, newStatus);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.cancelOrder(orderId, reason);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update order priority
  Future<void> updateOrderPriority(String orderId, String priority) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.updateOrderPriority(orderId, priority);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get priority orders
  List<OrderModel> getPriorityOrders() {
    return _orders.where((order) => order.priority == 'high').toList();
  }

  // Get urgent orders
  List<OrderModel> getUrgentOrders() {
    return _orders.where((order) => order.priority == 'urgent').toList();
  }

  // Update processing status
  Future<void> updateProcessingStatus(
    String orderId,
    String processingStatus, {
    String? description,
    String? notes,
    String? operatorId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.updateProcessingStatus(
        orderId,
        processingStatus,
        description: description,
        notes: notes,
        operatorId: operatorId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Bulk update processing status
  Future<void> bulkUpdateProcessingStatus(
    List<String> orderIds,
    String processingStatus, {
    String? description,
    String? notes,
    String? operatorId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _orderService.bulkUpdateProcessingStatus(
        orderIds,
        processingStatus,
        description: description,
        notes: notes,
        operatorId: operatorId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get processing history for an order
  Future<List<Map<String, dynamic>>> getProcessingHistory(String orderId) async {
    try {
      return await _orderService.getProcessingHistory(orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Get current processing status for an order
  Future<String?> getCurrentProcessingStatus(String orderId) async {
    try {
      return await _orderService.getCurrentProcessingStatus(orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get processing status description helper
  String getProcessingStatusDescription(String status) {
    return _orderService.getProcessingStatusDescription(status);
  }

  // Trigger new order ringing notification
  Future<void> _triggerNewOrderNotification(OrderModel order) async {
    try {
      await _orderService.triggerNewOrderNotification(order.id, order.toFirestore());
    } catch (e) {
      // Don't fail the provider if notification fails
      debugPrint('Failed to trigger new order notification: $e');
    }
  }

  // Refresh data
  void refresh() {
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _allOrdersSubscription?.cancel();
    _newOrdersSubscription?.cancel();
    _processingOrdersSubscription?.cancel();
    _completedOrdersSubscription?.cancel();
    super.dispose();
  }
}
