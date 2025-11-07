import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:swiftwash_admin/utils/env_config.dart';
import 'package:swiftwash_admin/utils/security_utils.dart';

class SecureApiService {
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  final http.Client _client = http.Client();
  DateTime _lastRequestTime = DateTime.now();
  int _requestCount = 0;

  // Rate limiting
  bool _checkRateLimit() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastRequestTime).inSeconds;

    if (timeDiff >= 60) {
      // Reset counter every minute
      _requestCount = 0;
      _lastRequestTime = now;
      return true;
    }

    if (_requestCount >= EnvConfig.maxRequestsPerMinute) {
      return false;
    }

    _requestCount++;
    return true;
  }

  // Secure GET request
  Future<Map<String, dynamic>> secureGet(String endpoint, {Map<String, String>? headers}) async {
    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }

    try {
      final url = Uri.parse('${EnvConfig.apiBaseUrl}$endpoint');
      final secureHeaders = _buildSecureHeaders(headers);

      debugPrint('Making GET request to: $url');

      final response = await _client.get(url, headers: secureHeaders).timeout(
        Duration(seconds: EnvConfig.apiTimeoutSeconds),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception(SecurityUtils.getSecureErrorMessage(e));
    }
  }

  // Secure POST request
  Future<Map<String, dynamic>> securePost(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers
  }) async {
    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }

    try {
      final url = Uri.parse('${EnvConfig.apiBaseUrl}$endpoint');
      final secureHeaders = _buildSecureHeaders(headers);
      final sanitizedBody = _sanitizeRequestBody(body);

      debugPrint('Making POST request to: $url');

      final response = await _client.post(
        url,
        headers: secureHeaders,
        body: jsonEncode(sanitizedBody),
      ).timeout(
        Duration(seconds: EnvConfig.apiTimeoutSeconds),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception(SecurityUtils.getSecureErrorMessage(e));
    }
  }

  // Secure PUT request
  Future<Map<String, dynamic>> securePut(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers
  }) async {
    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }

    try {
      final url = Uri.parse('${EnvConfig.apiBaseUrl}$endpoint');
      final secureHeaders = _buildSecureHeaders(headers);
      final sanitizedBody = _sanitizeRequestBody(body);

      debugPrint('Making PUT request to: $url');

      final response = await _client.put(
        url,
        headers: secureHeaders,
        body: jsonEncode(sanitizedBody),
      ).timeout(
        Duration(seconds: EnvConfig.apiTimeoutSeconds),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception(SecurityUtils.getSecureErrorMessage(e));
    }
  }

  // Secure DELETE request
  Future<Map<String, dynamic>> secureDelete(String endpoint, {Map<String, String>? headers}) async {
    if (!_checkRateLimit()) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }

    try {
      final url = Uri.parse('${EnvConfig.apiBaseUrl}$endpoint');
      final secureHeaders = _buildSecureHeaders(headers);

      debugPrint('Making DELETE request to: $url');

      final response = await _client.delete(url, headers: secureHeaders).timeout(
        Duration(seconds: EnvConfig.apiTimeoutSeconds),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception(SecurityUtils.getSecureErrorMessage(e));
    }
  }

  // Build secure headers
  Map<String, String> _buildSecureHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-API-Key': EnvConfig.encryptionKey, // Use encryption key as API key
      'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'X-Client-Version': '1.0.0',
      'X-Platform': 'admin',
    };

    // Add security headers
    EnvConfig.securityHeaders.forEach((key, value) {
      headers[key] = value;
    });

    // Add CSRF token if available
    final csrfToken = SecurityUtils().generateCSRFToken();
    headers['X-CSRF-Token'] = csrfToken;

    // Add additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // Sanitize request body
  Map<String, dynamic> _sanitizeRequestBody(Map<String, dynamic> body) {
    final sanitized = <String, dynamic>{};

    body.forEach((key, value) {
      if (value is String) {
        sanitized[key] = SecurityUtils.sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeRequestBody(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return SecurityUtils.sanitizeInput(item);
          } else if (item is Map<String, dynamic>) {
            return _sanitizeRequestBody(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      } catch (e) {
        throw Exception('Invalid response format');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized access');
    } else if (response.statusCode == 403) {
      throw Exception('Access forbidden');
    } else if (response.statusCode == 404) {
      throw Exception('Resource not found');
    } else if (response.statusCode == 429) {
      throw Exception('Too many requests. Please try again later.');
    } else if (response.statusCode >= 500) {
      throw Exception('Server error. Please try again later.');
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }

  // Validate SSL certificate (for custom certificate pinning)
  bool _validateSSLCertificate(String host, String certificate) {
    // In production, implement certificate pinning
    // For now, accept all certificates in development
    return !EnvConfig.isProduction || _isValidCertificate(host, certificate);
  }

  bool _isValidCertificate(String host, String certificate) {
    // Implement certificate pinning logic here
    // Compare certificate with known good certificates
    return true; // Placeholder
  }

  // Clean up resources
  void dispose() {
    _client.close();
  }

  // Get current rate limit status
  Map<String, dynamic> getRateLimitStatus() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastRequestTime).inSeconds;
    final remainingRequests = EnvConfig.maxRequestsPerMinute - _requestCount;
    final resetTime = 60 - timeDiff;

    return {
      'currentCount': _requestCount,
      'maxRequests': EnvConfig.maxRequestsPerMinute,
      'remainingRequests': remainingRequests > 0 ? remainingRequests : 0,
      'resetInSeconds': resetTime > 0 ? resetTime : 0,
      'isLimited': _requestCount >= EnvConfig.maxRequestsPerMinute,
    };
  }
}
