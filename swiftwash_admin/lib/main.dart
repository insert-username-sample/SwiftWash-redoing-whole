import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_admin/providers/store_provider.dart';
import 'package:swiftwash_admin/providers/admin_provider.dart';
import 'package:swiftwash_admin/screens/admin_dashboard_screen.dart';
import 'package:swiftwash_admin/screens/login_screen.dart';
import 'package:swiftwash_admin/screens/store_management_screen.dart';
import 'package:swiftwash_admin/screens/admin_management_screen.dart';
import 'package:swiftwash_admin/screens/create_store_screen.dart';
import 'package:swiftwash_admin/screens/create_admin_screen.dart';
import 'package:swiftwash_admin/screens/store_details_screen.dart';
import 'package:swiftwash_admin/screens/admin_details_screen.dart';
import 'package:swiftwash_admin/screens/settings_screen.dart';
import 'package:swiftwash_admin/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SwiftWashAdminApp());
}

class SwiftWashAdminApp extends StatelessWidget {
  const SwiftWashAdminApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => StoreProvider()),
        ChangeNotifierProvider(create: (context) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'SwiftWash Admin',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const AdminDashboardScreen(),
          '/stores': (context) => const StoreManagementScreen(),
          '/admins': (context) => const AdminManagementScreen(),
          '/create-store': (context) => const CreateStoreScreen(),
          '/create-admin': (context) => const CreateAdminScreen(),
          '/store-details': (context) => const StoreDetailsScreen(),
          '/admin-details': (context) => const AdminDetailsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
