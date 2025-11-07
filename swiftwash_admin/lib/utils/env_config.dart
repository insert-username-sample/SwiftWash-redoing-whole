import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static const String _envFile = kReleaseMode ? '.env.prod' : '.env.dev';

  // API Keys and Secrets
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // Security Configuration
  static String get encryptionKey => dotenv.env['ENCRYPTION_KEY'] ?? 'default_key_change_in_prod';
  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? 'default_jwt_secret';
  static int get sessionTimeoutMinutes => int.tryParse(dotenv.env['SESSION_TIMEOUT_MINUTES'] ?? '30') ?? 30;

  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.swiftwash.com';
  static int get apiTimeoutSeconds => int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30;

  // Rate Limiting
  static int get maxRequestsPerMinute => int.tryParse(dotenv.env['MAX_REQUESTS_PER_MINUTE'] ?? '60') ?? 60;
  static int get maxLoginAttempts => int.tryParse(dotenv.env['MAX_LOGIN_ATTEMPTS'] ?? '5') ?? 5;

  // Feature Flags
  static bool get enableAnalytics => dotenv.env['ENABLE_ANALYTICS'] == 'true';
  static bool get enableCrashReporting => dotenv.env['ENABLE_CRASH_REPORTING'] == 'true';
  static bool get enableDebugLogging => dotenv.env['ENABLE_DEBUG_LOGGING'] == 'true';

  // Security Headers
  static Map<String, String> get securityHeaders => {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy': "default-src 'self'",
  };

  // Initialize environment configuration
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: _envFile);
      _validateConfiguration();
    } catch (e) {
      debugPrint('Failed to load environment configuration: $e');
      // Load default configuration for development
      await dotenv.load(fileName: '.env.defaults');
    }
  }

  // Validate critical configuration
  static void _validateConfiguration() {
    final requiredKeys = [
      'FIREBASE_PROJECT_ID',
      'ENCRYPTION_KEY',
    ];

    final missingKeys = requiredKeys.where((key) => dotenv.env[key]?.isEmpty ?? true).toList();

    if (missingKeys.isNotEmpty) {
      throw Exception('Missing required environment variables: ${missingKeys.join(', ')}');
    }

    // Validate encryption key strength
    if (encryptionKey.length < 16) {
      throw Exception('Encryption key must be at least 16 characters long');
    }
  }

  // Get environment info for debugging (without sensitive data)
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'environment': kReleaseMode ? 'production' : 'development',
      'debugMode': kDebugMode,
      'firebaseConfigured': firebaseProjectId.isNotEmpty,
      'analyticsEnabled': enableAnalytics,
      'crashReportingEnabled': enableCrashReporting,
      'sessionTimeoutMinutes': sessionTimeoutMinutes,
      'apiTimeoutSeconds': apiTimeoutSeconds,
    };
  }

  // Check if running in production
  static bool get isProduction => kReleaseMode;

  // Check if running in development
  static bool get isDevelopment => kDebugMode;

  // Get sanitized environment variables (remove sensitive data)
  static Map<String, String> getSanitizedEnvironment() {
    final env = Map<String, String>.from(dotenv.env);
    final sensitiveKeys = [
      'FIREBASE_API_KEY',
      'ENCRYPTION_KEY',
      'JWT_SECRET',
    ];

    for (final key in sensitiveKeys) {
      if (env.containsKey(key)) {
        env[key] = '***HIDDEN***';
      }
    }

    return env;
  }
}
