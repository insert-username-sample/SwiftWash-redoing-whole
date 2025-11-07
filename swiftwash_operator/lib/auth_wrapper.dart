import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/providers/operator_provider.dart';
import 'package:swiftwash_operator/screens/operator_home_screen.dart';
import 'package:swiftwash_operator/screens/phone_login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OperatorProvider>(
      builder: (context, operatorProvider, child) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show loading state while checking authentication
            if (snapshot.connectionState == ConnectionState.waiting || operatorProvider.isLoading) {
              return Scaffold(
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1976D2),
                        Color(0xFF42A5F5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.phone_android,
                            size: 64,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading SwiftWash Operator...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // If user is authenticated, show home screen
            if (snapshot.hasData && snapshot.data != null) {
              // Check if operator data is loaded
              if (operatorProvider.currentOperator != null) {
                return const OperatorHomeScreen();
              } else {
                // Try to load operator data
                operatorProvider.getCurrentOperator();
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            }

            // If not authenticated or error, show login screen
            return const PhoneLoginScreen();
          },
        );
      },
    );
  }
}
