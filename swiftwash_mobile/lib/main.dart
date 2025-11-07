import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/auth_wrapper.dart';
import 'package:swiftwash_mobile/notification_service.dart';
import 'package:swiftwash_mobile/services/audio_ring_service.dart';
import 'package:swiftwash_mobile/gps_tracking_service.dart';
import 'package:swiftwash_mobile/services/enhanced_tracking_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Global error handling for production crash prevention
Future<void> initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase FIRST before any other Firebase services
    await Firebase.initializeApp();

    // Load environment variables (optional - don't crash if file missing)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('SwiftWash Mobile: .env file not found, continuing without environment variables: $e');
    }

    // Initialize Notification Service
    await NotificationService().initialize();

    // Get and save FCM token
    await _getAndSaveToken();

    // Initialize audio ringing service (prevents memory leaks)
    await AudioRingService.initialize();

    debugPrint('SwiftWash Mobile: All services initialized successfully ✅');

  } catch (error, stackTrace) {
    debugPrint('SwiftWash Mobile: Initialization error: $error');
    debugPrint('Stack trace: $stackTrace');

    // Send to Firebase Crashlytics only if Firebase is initialized
    try {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } catch (e) {
      debugPrint('SwiftWash Mobile: Could not send crash report - Firebase not initialized: $e');
    }

    // Continue with app initialization even if some services fail
    // This prevents app crashes from non-critical initialization errors
  }
}

Future<void> _getAndSaveToken() async {
  try {
    String? token = await NotificationService().getToken();
    if (token != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    }
  } catch (e) {
    debugPrint('Failed to get and save FCM token: $e');
  }
}

void main() async {
  await initializeApp();

  // Global error handling for zone-level exceptions
  runZonedGuarded(() {
    runApp(const SwiftWashApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught error in SwiftWash Mobile: $error');
    debugPrint('Stack trace: $stackTrace');

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Uncaught async error in main zone'
    );

    // In production, you might want to show a user-friendly error screen
    // For now, we continue running the app to prevent complete crashes
  });
}

class SwiftWashApp extends StatefulWidget {
  const SwiftWashApp({super.key});

  @override
  SwiftWashAppState createState() => SwiftWashAppState();
}

class SwiftWashAppState extends State<SwiftWashApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.detached) {
      // 🚨 CRITICAL: App is being terminated - cleanup ALL resources immediately!
      debugPrint('SwiftWash Mobile: App terminating - cleaning up resources...');

      // Cleanup AudioRingService (prevents memory leaks)
      AudioRingService.disposeAll().catchError((error) {
        debugPrint('Error disposing AudioRingService: $error');
      });

      // Cleanup GPS tracking service
      try {
        GPSTrackingService().dispose();
      } catch (error) {
        debugPrint('Error disposing GPS tracking service: $error');
      }

      // Cleanup enhanced tracking service
      try {
        EnhancedTrackingService().dispose();
      } catch (error) {
        debugPrint('Error disposing enhanced tracking service: $error');
      }

      debugPrint('SwiftWash Mobile: All resources disposed ✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftWash Mobile',
      theme: AppTheme.theme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const AuthWrapper(), // Redirect to AuthWrapper which handles login
      },
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Add error boundary around the entire app
        return ErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Global error boundary to prevent app crashes
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({required this.child, super.key});

  @override
  ErrorBoundaryState createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter framework error caught: ${details.exception}');
      FirebaseCrashlytics.instance.recordFlutterError(details);

      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
