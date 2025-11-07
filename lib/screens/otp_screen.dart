import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:apple_sign_in/apple_sign_in.dart';

class OTPScreen extends StatefulWidget {
  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AppleSignIn _appleSignIn = AppleSignIn();

  void _handlePhoneAuth() async {
    // Implement phone authentication logic here
  }

  void _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } catch (error) {
      print('Error signing in with Google: $error');
    }
  }

  void _handleAppleSignIn() async {
    try {
      final AuthorizationResult result = await _appleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      if (result.status == AuthorizationStatus.authorized) {
        final AuthCredential credential = OAuthProvider('apple.com').credential(
          idToken: String.fromCharCodes(result.credential.identityToken),
          accessToken: String.fromCharCodes(result.credential.authorizationCode),
        );

        await _auth.signInWithCredential(credential);
      } else {
        print('Error signing in with Apple: ${result.error.localizedDescription}');
      }
    } catch (error) {
      print('Error signing in with Apple: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OTP Verification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handlePhoneAuth,
              child: Text('Continue with Phone'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              child: Text('Continue with Google'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleAppleSignIn,
              child: Text('Continue with Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
