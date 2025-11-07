import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Advanced image caching service for large-scale performance
class ImageCacheService {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'swiftwash_images',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 1000,
      repo: JsonCacheInfoRepository(databaseName: 'swiftwash_images'),
    ),
  );

  static final CacheManager _profileCacheManager = CacheManager(
    Config(
      'swiftwash_profiles',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: 'swiftwash_profiles'),
    ),
  );

  /// Get cached network image widget with optimized settings
  static Widget getCachedNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool isProfileImage = false,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: isProfileImage ? _profileCacheManager : _cacheManager,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(width, height),
      memCacheWidth: width.toInt(),
      memCacheHeight: height.toInt(),
      maxWidthDiskCache: (width * 2).toInt(),
      maxHeightDiskCache: (height * 2).toInt(),
    );
  }

  /// Preload images for better performance
  static Future<void> preloadImages(List<String> imageUrls, {bool isProfileImages = false}) async {
    final cacheManager = isProfileImages ? _profileCacheManager : _cacheManager;

    for (final url in imageUrls) {
      try {
        await cacheManager.getSingleFile(url);
      } catch (e) {
        // Silently fail for preloading errors
        debugPrint('Failed to preload image: $url');
      }
    }
  }

  /// Clear cache for specific patterns
  static Future<void> clearCache({String? pattern}) async {
    if (pattern == null) {
      await _cacheManager.emptyCache();
      await _profileCacheManager.emptyCache();
    } else {
      // Clear specific cache entries matching pattern
      final keys = _cacheManager.store.store.keys.where((key) => key.contains(pattern));
      for (final key in keys) {
        await _cacheManager.removeFile(key);
      }
    }
  }

  /// Get cache size information
  static Future<Map<String, int>> getCacheSize() async {
    final imageCacheSize = await _cacheManager.store.getFileCount();
    final profileCacheSize = await _profileCacheManager.store.getFileCount();

    return {
      'imageCache': imageCacheSize,
      'profileCache': profileCacheSize,
      'total': imageCacheSize + profileCacheSize,
    };
  }

  static Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );
  }

  static Widget _buildErrorWidget(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}

/// Optimized image widget for service icons
class ServiceImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool isLocal;

  const ServiceImage({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocal) {
      return Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: size * 0.5,
            ),
          );
        },
      );
    }

    return ImageCacheService.getCachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
