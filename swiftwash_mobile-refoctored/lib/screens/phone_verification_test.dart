import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class PhoneVerificationTestScreen extends StatefulWidget {
  const PhoneVerificationTestScreen({Key? key}) : super(key: key);

  @override
  _PhoneVerificationTestScreenState createState() => _PhoneVerificationTestScreenState();
}

class _PhoneVerificationTestScreenState extends State<PhoneVerificationTestScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = [];
  final List<FocusNode> _otpFocusNodes = [];
  String _currentText = '';
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _codeSent = false;
  bool _otpVerified = false;
  String _verificationId = '';
  int _resendCountdown = 0;

  final String _testOtp = '123456';

  @override
  void initState() {
    super.initState();

    // Initialize OTP controllers and focus nodes
    for (int i = 0; i < 6; i++) {
      _otpControllers.add(TextEditingController());
      _otpFocusNodes.add(FocusNode());
    }

    // Initialize with logged-in user's phone number if available and valid
    final phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phoneNumber != null && phoneNumber.isNotEmpty && phoneNumber.length > 3) {
      // Remove +91 prefix to show just the 10-digit number
      _phoneController.text = phoneNumber.substring(3);
    }

    // Listen to text changes and update the display counter
    _phoneController.addListener(() {
      setState(() {
        _currentText = _phoneController.text;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _codeSent ? 'Enter OTP' : 'Phone Verification',
          style: AppTypography.h1,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.brandBlue.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Section
                  const SizedBox(height: 20),
                  Image.asset('assets/logo_with_wordmark.png', height: 60),
                  const SizedBox(height: 8),
                  Text(
                    'Verify Your Phone',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Enter the 6-digit code sent to +91$_currentText'
                        : 'Enter your phone number to receive OTP',
                    style: AppTypography.subtitle.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Content Card
                  Card(
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    shadowColor: AppColors.brandBlue.withOpacity(0.2),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        gradient: AppColors.serviceCardGradient,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1: Phone Input (if not yet sent)
                          if (!_codeSent) ...[
                            Text(
                              '📱 Phone Number',
                              style: AppTypography.cardTitle,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              buildCounter: null,
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                prefixText: '+91 ',
                                prefixStyle: AppTypography.cardTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.actionBlue,
                                ),
                                labelText: '10-digit mobile number',
                                labelStyle: AppTypography.subtitle,
                                hintText: 'Enter your phone number',
                                hintStyle: AppTypography.subtitle,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(color: AppColors.brandBlue, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Validation Indicator
                            if (_currentText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _currentText.length == 10
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _currentText.length == 10
                                          ? Icons.check_circle
                                          : Icons.warning,
                                      color: _currentText.length == 10
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentText.length == 10
                                          ? '✅ Ready to send OTP'
                                          : '📱 Enter $_currentText.length digit(s) more',
                                      style: AppTypography.cardSubtitle.copyWith(
                                        color: _currentText.length == 10
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Send OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _currentText.length == 10 ? _sendOtp : null,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  backgroundColor: _currentText.length == 10
                                      ? AppColors.brandBlue
                                      : AppColors.divider,
                                  disabledBackgroundColor: AppColors.divider,
                                  elevation: _currentText.length == 10 ? 4 : 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: _currentText.length == 10
                                              ? AppColors.brandGradient
                                              : null,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        alignment: Alignment.center,
                                        height: 56,
                                        child: Text(
                                          _isLoading ? 'Sending...' : 'Send OTP',
                                          style: AppTypography.h2.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],

                          // Step 2: OTP Input (if code sent)
                          if (_codeSent && !_otpVerified) ...[
                            Text(
                              '🔐 Enter 6-digit OTP',
                              style: AppTypography.cardTitle,
                            ),
                            const SizedBox(height: 16),

                            // OTP Display and Test Info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.brandBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Sent to: +91$_currentText',
                                    style: AppTypography.cardSubtitle.copyWith(
                                      color: AppColors.actionBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Test OTP: $_testOtp',
                                    style: AppTypography.cardSubtitle.copyWith(
                                      color: Colors.green[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // OTP Input Fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                6,
                                (index) => Container(
                                  width: 45,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _otpFocusNodes[index].hasFocus
                                          ? AppColors.brandBlue
                                          : AppColors.divider,
                                      width: _otpFocusNodes[index].hasFocus ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    boxShadow: _otpFocusNodes[index].hasFocus
                                        ? [
                                            BoxShadow(
                                              color: AppColors.brandBlue.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _otpFocusNodes[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(1),
                                    ],
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) {
                                      if (value.length == 1 && index < 5) {
                                        _otpFocusNodes[index + 1].requestFocus();
                                      }
                                      if (value.length == 1 && index == 5) {
                                        // Auto-verify when all digits entered
                                        _verifyOtp();
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Resend Timer
                            if (_resendCountdown > 0)
                              Text(
                                'Resend OTP in $_resendCountdown seconds',
                                style: AppTypography.subtitle,
                              )
                            else
                              TextButton(
                                onPressed: _sendOtp,
                                child: Text(
                                  'Resend OTP',
                                  style: AppTypography.cardTitle.copyWith(
                                    color: AppColors.actionBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Verify OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _getOtpString().length == 6 ? _verifyOtp : null,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  backgroundColor: _getOtpString().length == 6
                                      ? AppColors.actionBlue
                                      : AppColors.divider,
                                  disabledBackgroundColor: AppColors.divider,
                                  elevation: _getOtpString().length == 6 ? 4 : 0,
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: _getOtpString().length == 6
                                              ? AppColors.bookingButtonGradient
                                              : null,
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        alignment: Alignment.center,
                                        height: 56,
                                        child: Text(
                                          _isVerifying ? 'Verifying...' : 'Verify OTP',
                                          style: AppTypography.h2.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],

                          // Step 3: Success State
                          if (_otpVerified) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green, width: 2),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Phone Verified Successfully!',
                                    style: AppTypography.h2.copyWith(color: Colors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You can now proceed with the app.',
                                    style: AppTypography.subtitle.copyWith(color: Colors.green[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getOtpString() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _sendOtp() async {
    if (_currentText.isEmpty || _currentText.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate OTP sending delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _codeSent = true;
    });

    // Start resend countdown
    _startResendCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP sent successfully to +91$_currentText'),
        backgroundColor: Colors.green,
      ),
    );

    print('OTP Sent to: +91$_currentText');

    // Focus on first OTP field
    _otpFocusNodes[0]?.requestFocus();
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtpString();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    // Simulate verification delay
    await Future.delayed(const Duration(seconds: 1));

    if (otp == _testOtp) {
      setState(() {
        _isVerifying = false;
        _otpVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop with success result
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop({'verified': true, 'phoneNumber': '+91$_currentText'});
      });
    } else {
      setState(() => _isVerifying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );

      // Clear OTP fields and refocus
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0]?.requestFocus();
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 30);
    Future.delayed(const Duration(seconds: 1), _updateResendCountdown);
  }

  void _updateResendCountdown() {
    if (_resendCountdown > 0) {
      setState(() => _resendCountdown--);
      Future.delayed(const Duration(seconds: 1), _updateResendCountdown);
    }
  }

  void _onVerificationComplete() {
    setState(() {
      _isVerifying = false;
      _otpVerified = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone verified automatically!'),
        backgroundColor: Colors.green,
      ),
    );

    // Pop with success result
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop({
        'verified': true,
        'phoneNumber': '+91$_currentText'
      });
    });
  }
}
