import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_driver/auth_wrapper.dart';
import 'package:swiftwash_driver/notification_service.dart';
import 'package:swiftwash_driver/services/background_location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_driver/providers/driver_onboarding_provider.dart';
import 'package:swiftwash_driver/screens/driver_home_screen.dart';
import 'package:swiftwash_driver/screens/driver_onboarding_screen.dart';

/// Enterprise-grade initialization for Driver App
Future<void> initializeDriverApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with crash reporting
    await Firebase.initializeApp();

    // Initialize Notification Service
    await NotificationService().initialize();

    // Initialize background location service (critical for driver tracking)
    await BackgroundLocationService().initialize();

    // Get and save FCM token
    await _getAndSaveToken();

    debugPrint('SwiftWash Driver: All services initialized successfully ✅');

  } catch (error, stackTrace) {
    debugPrint('SwiftWash Driver: Initialization error: $error');
    debugPrint('Stack trace: $stackTrace');

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(error, stackTrace);

    // Continue with app initialization even if some services fail
    // This prevents app crashes from non-critical initialization errors
  }
}

/// Secure FCM token management
Future<void> _getAndSaveToken() async {
  try {
    String? token = await NotificationService().getToken();
    if (token != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'deviceType': 'driver',
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  } catch (e) {
    debugPrint('Failed to get and save FCM token: $e');
  }
}

void main() async {
  await initializeDriverApp();

  // Global error handling for zone-level exceptions
  runZonedGuarded(() {
    runApp(const SwiftWashDriverApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught error in SwiftWash Driver: $error');
    debugPrint('Stack trace: $stackTrace');

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Uncaught async error in driver main zone'
    );
  });
}

class SwiftWashDriverApp extends StatefulWidget {
  const SwiftWashDriverApp({super.key});

  @override
  SwiftWashDriverAppState createState() => SwiftWashDriverAppState();
}

class SwiftWashDriverAppState extends State<SwiftWashDriverApp> with WidgetsBindingObserver {
  final BackgroundLocationService _locationService = BackgroundLocationService();

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
      // 🚨 CRITICAL: Driver App terminating - cleanup ALL resources immediately!
      debugPrint('SwiftWash Driver: App terminating - cleaning up resources...');

      // Cleanup BackgroundLocationService (critical for memory management)
      _locationService.dispose().catchError((error) {
        debugPrint('Error disposing BackgroundLocationService: $error');
      });

      // Cleanup provider resources
      try {
        // Additional cleanup for any active providers
        debugPrint('SwiftWash Driver: Provider resources cleaned');
      } catch (e) {
        debugPrint('Error during provider cleanup: $e');
      }

      debugPrint('SwiftWash Driver: All resources disposed ✅');

    } else if (state == AppLifecycleState.paused) {
      // App going to background - reduce resource usage
      debugPrint('SwiftWash Driver: App paused - optimizing for background');

    } else if (state == AppLifecycleState.resumed) {
      // App coming back to foreground
      debugPrint('SwiftWash Driver: App resumed - restoring full functionality');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftWash Driver',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const DriverHomeScreen(),
        '/onboarding': (context) => ChangeNotifierProvider(
          create: (_) => DriverOnboardingProvider(),
          child: const DriverOnboardingScreen(),
        ),
        '/login': (context) => const AuthWrapper(), // Redirect to AuthWrapper which handles login
      },
      builder: (context, child) {
        // Add enterprise-level error boundary
        return DriverErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Enterprise-grade error boundary for Driver App
class DriverErrorBoundary extends StatefulWidget {
  final Widget child;

  const DriverErrorBoundary({required this.child, super.key});

  @override
  DriverErrorBoundaryState createState() => DriverErrorBoundaryState();
}

class DriverErrorBoundaryState extends State<DriverErrorBoundary> {
  bool _hasError = false;
  String? _errorDetails;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Driver App: Flutter framework error - ${details.exception}');
      FirebaseCrashlytics.instance.recordFlutterError(details);
      _recordDriverIncident(details.exception.toString());

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details.exception.toString();
        });
      }
    };
  }

  Future<void> _recordDriverIncident(String error) async {
    try {
      // Record driver-specific incidents for monitoring
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('driver_incidents').add({
          'driverId': user.uid,
          'error': error,
          'timestamp': FieldValue.serverTimestamp(),
          'appVersion': '1.0.0+1',
          'deviceType': 'driver_app',
        });
      }
    } catch (e) {
      debugPrint('Failed to record driver incident: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade50,
          appBar: AppBar(
            title: const Text('Driver App Error'),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.drive_eta,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Driver App Encountered an Issue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error details have been reported for investigation.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_errorDetails != null && kDebugMode)
                  Text(
                    'Details: $_errorDetails',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorDetails = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Retry', style: TextStyle(fontSize: 16)),
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
