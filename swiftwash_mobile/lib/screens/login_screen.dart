import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swiftwash_mobile/screens/otp_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:swiftwash_mobile/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  String _formatPhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      // Handle numbers like 09359652870
      return '+91${cleaned.substring(1)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      // Handle numbers already starting with 91
      return '+$cleaned';
    } else if (cleaned.length == 13 && cleaned.startsWith('091')) {
      // Handle numbers like 0919359652870
      return '+91${cleaned.substring(2)}';
    } else {
      // Invalid length
      return '';
    }
  }

  bool _validatePhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    // Accept 10 digits, or 12-13 digits starting with 91, or various Indian formats
    if (cleaned.length == 10) {
      return true;
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return true;
    } else if (cleaned.length == 13 && cleaned.startsWith('091')) {
      return true;
    } else if (cleaned.length == 11 && cleaned.startsWith('0')) {
      return true;
    }
    return false;
  }

  void _continueWithPhone() {
    String phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile number');
      return;
    }

    if (!_validatePhoneNumber(phoneText)) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _errorMessage = null);
    String formattedPhone = _formatPhoneNumber(phoneText);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(phoneNumber: formattedPhone),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Prevent multiple simultaneous sign-in attempts

    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      if (googleAuth != null) {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in and let AuthWrapper handle navigation
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Let the AuthWrapper stream handle navigation
        // The AuthWrapper will automatically navigate to MainScreen when user is authenticated
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
      // Check if user is actually signed in despite the error
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred during Google Sign-In. Please try again.'),
          ),
        );
      }
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.brandBlue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo positioned higher - centered above the welcome card
                Image.asset('assets/logo_with_wordmark.png', height: 80),
                const SizedBox(height: 8),
                Text(
                  'Swift. Clean. Hassle Free.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your mobile number to continue',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            prefixText: '+91 ',
                            labelText: 'Mobile Number',
                            errorText: _errorMessage,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _continueWithPhone,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              height: 45,
                              child: Text(
                                'Continue',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const FaIcon(FontAwesomeIcons.google, color: Colors.red),
                  label: _isLoading
                      ? const Text('Signing in...')
                      : const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white),
                  label: const Text('Continue with Apple'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "By continuing, you agree to SwiftWash’s Terms of Service and Privacy Policy.",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
