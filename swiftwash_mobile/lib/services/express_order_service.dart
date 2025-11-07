import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Express ordering service for one-tap reordering and favorites
class ExpressOrderService {
  static const String _favoritesKey = 'favorite_orders';
  static const String _recentOrdersKey = 'recent_orders';
  static const String _maxFavorites = 5;
  static const String _maxRecentOrders = 10;

  /// Save order as favorite for quick reordering
  static Future<void> saveAsFavorite(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavorites();

      // Create favorite entry
      final favoriteEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'orderData': orderData,
        'savedAt': DateTime.now().toIso8601String(),
        'usageCount': 1,
        'lastUsed': DateTime.now().toIso8601String(),
      };

      // Check if this service type is already a favorite
      final existingIndex = favorites.indexWhere(
        (fav) => fav['orderData']['serviceType'] == orderData['serviceType']
      );

      if (existingIndex != -1) {
        // Update existing favorite
        favorites[existingIndex]['usageCount'] = (favorites[existingIndex]['usageCount'] ?? 1) + 1;
        favorites[existingIndex]['lastUsed'] = DateTime.now().toIso8601String();
      } else {
        // Add new favorite
        favorites.add(favoriteEntry);

        // Keep only top favorites
        if (favorites.length > _maxFavorites) {
          favorites.sort((a, b) => (b['usageCount'] as int).compareTo(a['usageCount'] as int));
          favorites.removeRange(_maxFavorites, favorites.length);
        }
      }

      await prefs.setString(_favoritesKey, jsonEncode(favorites));

      debugPrint('Order saved as favorite: ${orderData['serviceType']}');
    } catch (e) {
      debugPrint('Failed to save favorite: $e');
    }
  }

  /// Get all favorite orders
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final favorites = await _getFavorites();

      // Sort by usage count and recency
      favorites.sort((a, b) {
        final aCount = a['usageCount'] as int? ?? 0;
        final bCount = b['usageCount'] as int? ?? 0;

        if (aCount != bCount) {
          return bCount.compareTo(aCount);
        }

        // If usage count is same, sort by last used
        final aLastUsed = DateTime.parse(a['lastUsed'] ?? a['savedAt']);
        final bLastUsed = DateTime.parse(b['lastUsed'] ?? b['savedAt']);
        return bLastUsed.compareTo(aLastUsed);
      });

      return favorites;
    } catch (e) {
      debugPrint('Failed to get favorites: $e');
      return [];
    }
  }

  /// Remove favorite
  static Future<void> removeFavorite(String favoriteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavorites();

      favorites.removeWhere((fav) => fav['id'] == favoriteId);

      await prefs.setString(_favoritesKey, jsonEncode(favorites));

      debugPrint('Favorite removed: $favoriteId');
    } catch (e) {
      debugPrint('Failed to remove favorite: $e');
    }
  }

  /// Save completed order to recent orders
  static Future<void> saveRecentOrder(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentOrders = await _getRecentOrders();

      // Create recent order entry
      final recentEntry = {
        'id': orderData['orderId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'orderData': orderData,
        'completedAt': DateTime.now().toIso8601String(),
      };

      // Remove if already exists (to avoid duplicates)
      recentOrders.removeWhere((order) => order['id'] == recentEntry['id']);

      // Add to beginning
      recentOrders.insert(0, recentEntry);

      // Keep only recent orders
      if (recentOrders.length > _maxRecentOrders) {
        recentOrders.removeRange(_maxRecentOrders, recentOrders.length);
      }

      await prefs.setString(_recentOrdersKey, jsonEncode(recentOrders));

      debugPrint('Order saved to recent: ${orderData['orderId']}');
    } catch (e) {
      debugPrint('Failed to save recent order: $e');
    }
  }

  /// Get recent orders for quick reordering
  static Future<List<Map<String, dynamic>>> getRecentOrders() async {
    try {
      return await _getRecentOrders();
    } catch (e) {
      debugPrint('Failed to get recent orders: $e');
      return [];
    }
  }

  /// Create express order from favorite
  static Future<Map<String, dynamic>> createExpressOrderFromFavorite(
    Map<String, dynamic> favorite,
    {
      Map<String, dynamic>? modifications, // Allow modifications like different address
    }
  ) async {
    try {
      final originalOrder = favorite['orderData'] as Map<String, dynamic>;

      // Create new order based on favorite
      final expressOrder = Map<String, dynamic>.from(originalOrder);

      // Update timestamps and IDs
      expressOrder['orderId'] = 'SW${DateTime.now().millisecondsSinceEpoch}';
      expressOrder['createdAt'] = DateTime.now().toIso8601String();
      expressOrder['status'] = 'pending';

      // Apply modifications if provided
      if (modifications != null) {
        expressOrder.addAll(modifications);
      }

      // Update favorite usage
      await _updateFavoriteUsage(favorite['id']);

      debugPrint('Express order created from favorite: ${expressOrder['orderId']}');

      return expressOrder;
    } catch (e) {
      debugPrint('Failed to create express order: $e');
      rethrow;
    }
  }

  /// Create express order from recent order
  static Future<Map<String, dynamic>> createExpressOrderFromRecent(
    Map<String, dynamic> recentOrder,
    {
      Map<String, dynamic>? modifications,
    }
  ) async {
    try {
      final originalOrder = recentOrder['orderData'] as Map<String, dynamic>;

      // Create new order based on recent order
      final expressOrder = Map<String, dynamic>.from(originalOrder);

      // Update timestamps and IDs
      expressOrder['orderId'] = 'SW${DateTime.now().millisecondsSinceEpoch}';
      expressOrder['createdAt'] = DateTime.now().toIso8601String();
      expressOrder['status'] = 'pending';

      // Apply modifications if provided
      if (modifications != null) {
        expressOrder.addAll(modifications);
      }

      debugPrint('Express order created from recent: ${expressOrder['orderId']}');

      return expressOrder;
    } catch (e) {
      debugPrint('Failed to create express order from recent: $e');
      rethrow;
    }
  }

  /// Get smart order suggestions based on user behavior
  static Future<List<Map<String, dynamic>>> getSmartSuggestions() async {
    try {
      final favorites = await getFavorites();
      final recentOrders = await getRecentOrders();

      final suggestions = <Map<String, dynamic>>[];

      // Add top favorites
      suggestions.addAll(favorites.take(2).map((fav) => {
        ...fav,
        'type': 'favorite',
        'title': 'Quick Repeat',
        'subtitle': '${fav['orderData']['serviceType']} - Your favorite!',
      }));

      // Add recent orders (excluding those already in favorites)
      final favoriteServiceTypes = favorites
          .map((fav) => fav['orderData']['serviceType'])
          .toSet();

      final recentSuggestions = recentOrders
          .where((order) => !favoriteServiceTypes.contains(order['orderData']['serviceType']))
          .take(2)
          .map((order) => {
            ...order,
            'type': 'recent',
            'title': 'Order Again',
            'subtitle': '${order['orderData']['serviceType']} - Last ordered recently',
          });

      suggestions.addAll(recentSuggestions);

      return suggestions.take(4).toList(); // Max 4 suggestions
    } catch (e) {
      debugPrint('Failed to get smart suggestions: $e');
      return [];
    }
  }

  /// Get express order statistics
  static Future<Map<String, dynamic>> getExpressOrderStats() async {
    try {
      final favorites = await _getFavorites();
      final recentOrders = await _getRecentOrders();

      final totalFavorites = favorites.length;
      final totalRecentOrders = recentOrders.length;

      // Calculate most popular service types
      final serviceTypeCount = <String, int>{};
      for (final order in recentOrders) {
        final serviceType = order['orderData']['serviceType'] ?? 'Unknown';
        serviceTypeCount[serviceType] = (serviceTypeCount[serviceType] ?? 0) + 1;
      }

      final mostPopularService = serviceTypeCount.isNotEmpty
          ? serviceTypeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;

      return {
        'totalFavorites': totalFavorites,
        'totalRecentOrders': totalRecentOrders,
        'mostPopularService': mostPopularService,
        'serviceTypeStats': serviceTypeCount,
      };
    } catch (e) {
      debugPrint('Failed to get express order stats: $e');
      return {};
    }
  }

  /// Clear all express order data
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      await prefs.remove(_recentOrdersKey);
      debugPrint('Express order data cleared');
    } catch (e) {
      debugPrint('Failed to clear express order data: $e');
    }
  }

  /// Private helper methods
  static Future<List<Map<String, dynamic>>> _getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson == null) return [];

      final favorites = jsonDecode(favoritesJson) as List;
      return favorites.map((fav) => fav as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get favorites: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _getRecentOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getString(_recentOrdersKey);
      if (recentJson == null) return [];

      final recent = jsonDecode(recentJson) as List;
      return recent.map((order) => order as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Failed to get recent orders: $e');
      return [];
    }
  }

  static Future<void> _updateFavoriteUsage(String favoriteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getFavorites();

      final favoriteIndex = favorites.indexWhere((fav) => fav['id'] == favoriteId);
      if (favoriteIndex != -1) {
        favorites[favoriteIndex]['usageCount'] = (favorites[favoriteIndex]['usageCount'] ?? 1) + 1;
        favorites[favoriteIndex]['lastUsed'] = DateTime.now().toIso8601String();

        await prefs.setString(_favoritesKey, jsonEncode(favorites));
      }
    } catch (e) {
      debugPrint('Failed to update favorite usage: $e');
    }
  }
}

/// Quick action buttons for express ordering
class ExpressOrderButtons {
  static const double buttonSize = 60;
  static const double iconSize = 24;

  /// Create favorite button widget
  static Widget createFavoriteButton({
    required Map<String, dynamic> orderData,
    required VoidCallback onAdded,
  }) {
    return GestureDetector(
      onTap: () async {
        await ExpressOrderService.saveAsFavorite(orderData);
        onAdded();
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite_border,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  /// Create reorder button widget
  static Widget createReorderButton({
    required Map<String, dynamic> orderData,
    required VoidCallback onReorder,
  }) {
    return GestureDetector(
      onTap: onReorder,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}
