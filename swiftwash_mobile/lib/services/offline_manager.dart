import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Advanced offline management for large-scale usage
class OfflineManager {
  static const String _pendingOrdersKey = 'pending_orders';
  static const String _cachedDataKey = 'cached_data';
  static const String _syncQueueKey = 'sync_queue';

  static final Connectivity _connectivity = Connectivity();
  static bool _isOnline = true;

  static Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none)
      .distinct();

  /// Initialize offline manager
  static Future<void> initialize() async {
    // Monitor connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        // Came back online, sync pending data
        _syncPendingData();
      }
    });

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }

  /// Check if device is online
  static bool get isOnline => _isOnline;

  /// Queue order for later sync when offline
  static Future<void> queueOrderForSync(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrders = await _getPendingOrders();

      orderData['queuedAt'] = DateTime.now().toIso8601String();
      orderData['syncAttempts'] = 0;

      pendingOrders.add(orderData);

      await prefs.setString(_pendingOrdersKey, jsonEncode(pendingOrders));

      debugPrint('Order queued for sync: ${orderData['orderId']}');
    } catch (e) {
      debugPrint('Failed to queue order: $e');
    }
  }

  /// Get all pending orders
  static Future<List<Map<String, dynamic>>> getPendingOrders() async {
    return await _getPendingOrders();
  }

  /// Remove order from pending queue after successful sync
  static Future<void> removeFromPendingQueue(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrders = await _getPendingOrders();

      pendingOrders.removeWhere((order) => order['orderId'] == orderId);

      await prefs.setString(_pendingOrdersKey, jsonEncode(pendingOrders));

      debugPrint('Order removed from pending queue: $orderId');
    } catch (e) {
      debugPrint('Failed to remove order from queue: $e');
    }
  }

  /// Cache data for offline access
  static Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'expiry': expiry != null ? DateTime.now().add(expiry).toIso8601String() : null,
      };

      final cachedData = await _getCachedData();
      cachedData[key] = cacheEntry;

      await prefs.setString(_cachedDataKey, jsonEncode(cachedData));
    } catch (e) {
      debugPrint('Failed to cache data: $e');
    }
  }

  /// Get cached data if available and not expired
  static Future<dynamic> getCachedData(String key) async {
    try {
      final cachedData = await _getCachedData();
      final entry = cachedData[key];

      if (entry == null) return null;

      // Check expiry
      if (entry['expiry'] != null) {
        final expiryDate = DateTime.parse(entry['expiry']);
        if (DateTime.now().isAfter(expiryDate)) {
          // Remove expired data
          await removeCachedData(key);
          return null;
        }
      }

      return entry['data'];
    } catch (e) {
      debugPrint('Failed to get cached data: $e');
      return null;
    }
  }

  /// Remove cached data
  static Future<void> removeCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = await _getCachedData();

      cachedData.remove(key);

      await prefs.setString(_cachedDataKey, jsonEncode(cachedData));
    } catch (e) {
      debugPrint('Failed to remove cached data: $e');
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedDataKey);
      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Add action to sync queue
  static Future<void> addToSyncQueue({
    required String action,
    required Map<String, dynamic> data,
    String? priority = 'normal', // 'high', 'normal', 'low'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueue = await _getSyncQueue();

      final queueItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': action,
        'data': data,
        'priority': priority,
        'createdAt': DateTime.now().toIso8601String(),
        'attempts': 0,
      };

      syncQueue.add(queueItem);

      // Sort by priority
      syncQueue.sort((a, b) {
        final priorityOrder = {'high': 0, 'normal': 1, 'low': 2};
        final aPriority = priorityOrder[a['priority']] ?? 1;
        final bPriority = priorityOrder[b['priority']] ?? 1;
        return aPriority.compareTo(bPriority);
      });

      await prefs.setString(_syncQueueKey, jsonEncode(syncQueue));

      debugPrint('Action added to sync queue: $action');
    } catch (e) {
      debugPrint('Failed to add to sync queue: $e');
    }
  }

  /// Get sync queue items
  static Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return await _getSyncQueue();
  }

  /// Remove item from sync queue
  static Future<void> removeFromSyncQueue(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncQueue = await _getSyncQueue();

      syncQueue.removeWhere((item) => item['id'] == itemId);

      await prefs.setString(_syncQueueKey, jsonEncode(syncQueue));
    } catch (e) {
      debugPrint('Failed to remove from sync queue: $e');
    }
  }

  /// Get offline statistics
  static Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final pendingOrders = await _getPendingOrders();
      final syncQueue = await _getSyncQueue();
      final cachedData = await _getCachedData();

      return {
        'pendingOrdersCount': pendingOrders.length,
        'syncQueueCount': syncQueue.length,
        'cachedItemsCount': cachedData.length,
        'isOnline': _isOnline,
        'lastSyncAttempt': await _getLastSyncAttempt(),
      };
    } catch (e) {
      debugPrint('Failed to get offline stats: $e');
      return {};
    }
  }

  /// Private helper methods
  static Future<List<Map<String, dynamic>>> _getPendingOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString(_pendingOrdersKey);
      if (ordersJson == null) return [];

      final orders = jsonDecode(ordersJson) as List;
      return orders.map((order) => order as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get pending orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> _getCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cachedDataKey);
      if (cacheJson == null) return {};

      return jsonDecode(cacheJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to get cached data: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> _getSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey);
      if (queueJson == null) return [];

      final queue = jsonDecode(queueJson) as List;
      return queue.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get sync queue: $e');
      return [];
    }
  }

  static Future<String?> _getLastSyncAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('lastSyncAttempt');
    } catch (e) {
      return null;
    }
  }

  static Future<void> _setLastSyncAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSyncAttempt', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to set last sync attempt: $e');
    }
  }

  /// Sync pending data when coming back online
  static Future<void> _syncPendingData() async {
    try {
      await _setLastSyncAttempt();

      final pendingOrders = await _getPendingOrders();
      final syncQueue = await _getSyncQueue();

      debugPrint('Starting sync of ${pendingOrders.length} orders and ${syncQueue.length} actions');

      // Sync would be implemented here with actual API calls
      // For now, just log the sync attempt

      debugPrint('Sync completed');

    } catch (e) {
      debugPrint('Failed to sync pending data: $e');
    }
  }
}
