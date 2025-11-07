import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:swiftwash_operator/auth_wrapper.dart';
import 'package:swiftwash_operator/notification_service.dart';
import 'package:swiftwash_operator/providers/order_provider.dart';
import 'package:swiftwash_operator/providers/support_chat_provider.dart';
import 'package:swiftwash_operator/providers/operator_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:swiftwash_operator/screens/enhanced_operator_home_screen.dart';
// import 'package:swiftwash_operator/screens/google_login_screen.dart';
import 'package:swiftwash_operator/screens/phone_login_screen.dart';
import 'package:swiftwash_operator/screens/operator_home_screen.dart';
import 'package:swiftwash_operator/screens/operator_management_screen.dart';
import 'package:swiftwash_operator/screens/create_operator_screen.dart';
import 'package:swiftwash_operator/screens/otp_screen.dart';

/// Enterprise-grade initialization for Operator App
Future<void> initializeOperatorApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with crash reporting
    await Firebase.initializeApp();

    // Initialize Notification Service
    await NotificationService().initialize();

    // Get and save FCM token with operator role
    await _getAndSaveToken();

    debugPrint('SwiftWash Operator: All services initialized successfully ✅');

  } catch (error, stackTrace) {
    debugPrint('SwiftWash Operator: Initialization error: $error');
    debugPrint('Stack trace: $stackTrace');

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(error, stackTrace);

    // Continue with app initialization even if some services fail
    // This prevents app crashes from non-critical initialization errors
  }
}

/// Secure FCM token management for operators
Future<void> _getAndSaveToken() async {
  try {
    String? token = await NotificationService().getToken();
    if (token != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'role': 'operator', // Explicit role assignment
          'deviceType': 'operator',
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Also update operator-specific collection
        await FirebaseFirestore.instance.collection('operators').doc(user.uid).set({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
          'status': 'online',
        }, SetOptions(merge: true));
      }
    }
  } catch (e) {
    debugPrint('Failed to get and save operator FCM token: $e');
  }
}

void main() async {
  await initializeOperatorApp();

  // Global error handling for zone-level exceptions
  runZonedGuarded(() {
    runApp(const SwiftWashOperatorApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught error in SwiftWash Operator: $error');
    debugPrint('Stack trace: $stackTrace');

    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: 'Uncaught async error in operator main zone'
    );
  });
}

class SwiftWashOperatorApp extends StatelessWidget {
  const SwiftWashOperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider<SupportChatProvider>(
          create: (_) => SupportChatProvider(),
        ),
        ChangeNotifierProvider<OperatorProvider>(
          create: (_) => OperatorProvider(),
        ),
      ],
      child: const OperatorAppContent(),
    );
  }
}

class OperatorAppContent extends StatefulWidget {
  const OperatorAppContent({super.key});

  @override
  OperatorAppContentState createState() => OperatorAppContentState();
}

class OperatorAppContentState extends State<OperatorAppContent> with WidgetsBindingObserver {
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
      // 🚨 CRITICAL: Operator App terminating - cleanup resources for stability
      debugPrint('SwiftWash Operator: App terminating - cleaning up resources...');

      // Cleanup providers
      try {
        // Access order provider and clean it up
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        orderProvider.dispose();
        debugPrint('SwiftWash Operator: Order provider disposed');
      } catch (e) {
        debugPrint('Error disposing order provider: $e');
      }

      debugPrint('SwiftWash Operator: All resources disposed ✅');

    } else if (state == AppLifecycleState.paused) {
      // Update operator status to away
      _updateOperatorStatus('away');

    } else if (state == AppLifecycleState.resumed) {
      // Update operator status to online
      _updateOperatorStatus('online');
    }
  }

  Future<void> _updateOperatorStatus(String status) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('operators').doc(user.uid).update({
          'status': status,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to update operator status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftWash Operator',
      debugShowCheckedModeBanner: false,
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
      routes: {
        '/home': (context) => const OperatorHomeScreen(),
        '/login': (context) => const PhoneLoginScreen(),
        '/phone-login': (context) => const PhoneLoginScreen(),
        '/otp': (context) => OTPScreen(phoneNumber: '+91'),
        '/operators': (context) => const OperatorManagementScreen(),
        '/create-operator': (context) => const CreateOperatorScreen(),
      },
      builder: (context, child) {
        // Add enterprise-level error boundary
        return OperatorErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Enterprise-grade error boundary for Operator App
class OperatorErrorBoundary extends StatefulWidget {
  final Widget child;

  const OperatorErrorBoundary({required this.child, super.key});

  @override
  OperatorErrorBoundaryState createState() => OperatorErrorBoundaryState();
}

class OperatorErrorBoundaryState extends State<OperatorErrorBoundary> {
  bool _hasError = false;
  String? _errorDetails;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Operator App: Flutter framework error - ${details.exception}');
      FirebaseCrashlytics.instance.recordFlutterError(details);
      _recordOperatorIncident(details.exception.toString());

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details.exception.toString();
        });
      }
    };
  }

  Future<void> _recordOperatorIncident(String error) async {
    try {
      // Record operator-specific incidents for monitoring
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('operator_incidents').add({
          'operatorId': user.uid,
          'error': error,
          'timestamp': FieldValue.serverTimestamp(),
          'appVersion': '1.0.0+1',
          'deviceType': 'operator_app',
        });
      }
    } catch (e) {
      debugPrint('Failed to record operator incident: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.orange.shade50,
          appBar: AppBar(
            title: const Text('Operator App Error'),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business_center,
                  color: Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Operator App Encountered an Issue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dashboard error details have been reported and are being investigated.',
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
