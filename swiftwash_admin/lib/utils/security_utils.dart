import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'env_config.dart';

class SecurityUtils {
  static final SecurityUtils _instance = SecurityUtils._internal();
  factory SecurityUtils() => _instance;
  SecurityUtils._internal();

  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  // Initialize encryption
  void initialize() {
    final key = encrypt.Key.fromUtf8(EnvConfig.encryptionKey.padRight(32, '0').substring(0, 32));
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  // Encrypt sensitive data
  String encryptData(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption failed: $e');
      throw Exception('Failed to encrypt data');
    }
  }

  // Decrypt sensitive data
  String decryptData(String encryptedData) {
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      debugPrint('Decryption failed: $e');
      throw Exception('Failed to decrypt data');
    }
  }

  // Hash sensitive data (one-way)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate secure random string
  String generateSecureToken([int length = 32]) {
    final random = encrypt.IV.fromSecureRandom(length);
    return base64Url.encode(random.bytes).replaceAll('=', '');
  }

  // Validate input data
  static ValidationResult validateInput(String input, ValidationType type) {
    switch (type) {
      case ValidationType.email:
        return _validateEmail(input);
      case ValidationType.password:
        return _validatePassword(input);
      case ValidationType.username:
        return _validateUsername(input);
      case ValidationType.phone:
        return _validatePhone(input);
      case ValidationType.name:
        return _validateName(input);
      case ValidationType.address:
        return _validateAddress(input);
      default:
        return ValidationResult(isValid: true);
    }
  }

  static ValidationResult _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Email is required');
    }
    if (!emailRegex.hasMatch(email)) {
      return ValidationResult(isValid: false, errorMessage: 'Invalid email format');
    }
    if (email.length > 254) {
      return ValidationResult(isValid: false, errorMessage: 'Email is too long');
    }
    return ValidationResult(isValid: true);
  }

  static ValidationResult _validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Password is required');
    }
    if (password.length < 8) {
      return ValidationResult(isValid: false, errorMessage: 'Password must be at least 8 characters');
    }
    if (password.length > 128) {
      return ValidationResult(isValid: false, errorMessage: 'Password is too long');
    }
    // Check for at least one uppercase, lowercase, number, and special character
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasNumbers || !hasSpecialChars) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain uppercase, lowercase, number, and special character'
      );
    }
    return ValidationResult(isValid: true);
  }

  static ValidationResult _validateUsername(String username) {
    if (username.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Username is required');
    }
    if (username.length < 3) {
      return ValidationResult(isValid: false, errorMessage: 'Username must be at least 3 characters');
    }
    if (username.length > 50) {
      return ValidationResult(isValid: false, errorMessage: 'Username is too long');
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(username)) {
      return ValidationResult(isValid: false, errorMessage: 'Username can only contain letters, numbers, underscores, and hyphens');
    }
    return ValidationResult(isValid: true);
  }

  static ValidationResult _validatePhone(String phone) {
    if (phone.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Phone number is required');
    }
    // Remove all non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return ValidationResult(isValid: false, errorMessage: 'Phone number must be 10-15 digits');
    }
    return ValidationResult(isValid: true);
  }

  static ValidationResult _validateName(String name) {
    if (name.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Name is required');
    }
    if (name.length < 2) {
      return ValidationResult(isValid: false, errorMessage: 'Name must be at least 2 characters');
    }
    if (name.length > 100) {
      return ValidationResult(isValid: false, errorMessage: 'Name is too long');
    }
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(name)) {
      return ValidationResult(isValid: false, errorMessage: 'Name can only contain letters, spaces, hyphens, and apostrophes');
    }
    return ValidationResult(isValid: true);
  }

  static ValidationResult _validateAddress(String address) {
    if (address.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Address is required');
    }
    if (address.length < 10) {
      return ValidationResult(isValid: false, errorMessage: 'Address must be at least 10 characters');
    }
    if (address.length > 500) {
      return ValidationResult(isValid: false, errorMessage: 'Address is too long');
    }
    return ValidationResult(isValid: true);
  }

  // Sanitize input data
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potential script tags and HTML
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Remove potential SQL injection patterns
    sanitized = sanitized.replaceAll(RegExp(r'(\b(union|select|insert|delete|update|drop|create|alter|exec|execute)\b)', caseSensitive: false), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    return sanitized;
  }

  // Rate limiting helper
  static bool shouldAllowRequest(DateTime lastRequest, int maxRequestsPerMinute) {
    final now = DateTime.now();
    final timeDiff = now.difference(lastRequest).inSeconds;
    return timeDiff >= (60 ~/ maxRequestsPerMinute);
  }

  // Secure error message (don't expose internal details)
  static String getSecureErrorMessage(dynamic error) {
    if (EnvConfig.isProduction) {
      // In production, return generic error messages
      return 'An error occurred. Please try again later.';
    } else {
      // In development, return actual error for debugging
      return error.toString();
    }
  }

  // Validate file upload
  static ValidationResult validateFileUpload(String fileName, int fileSize, List<String> allowedExtensions) {
    if (fileName.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'File name is required');
    }

    // Check file extension
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'File type not allowed. Allowed types: ${allowedExtensions.join(', ')}'
      );
    }

    // Check file size (max 10MB)
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    if (fileSize > maxSize) {
      return ValidationResult(isValid: false, errorMessage: 'File size must be less than 10MB');
    }

    return ValidationResult(isValid: true);
  }

  // Generate CSRF token
  static String generateCSRFToken() {
    return generateSecureToken(32);
  }

  // Validate CSRF token
  static bool validateCSRFToken(String token, String storedToken) {
    return token == storedToken && token.isNotEmpty;
  }
}

enum ValidationType {
  email,
  password,
  username,
  phone,
  name,
  address,
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
