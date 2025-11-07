import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:flutter/services.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with WidgetsBindingObserver {
  String _smsCode = '';
  String _verificationId = '';
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  bool _isVerificationStarted = false;
  String? _errorMessage;
  int _retryCount = 0;

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _otpController.addListener(_handleOtpChange);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    SmsAutoFill().unregisterListener();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleOtpChange() {
    setState(() {
      _smsCode = _otpController.text;
      _isButtonEnabled = _smsCode.length == 6;
    });
  }

  void _updateSmsCode(String code) {
    setState(() {
      _smsCode = code;
      _isButtonEnabled = code.length == 6;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only start verification after initial build is complete
    if (!_isVerificationStarted && mounted) {
      _isVerificationStarted = true;
      _startVerification();
    }
  }

  void _listenForCode() async {
    await SmsAutoFill().listenForCode;
  }

  Future<void> _startVerification() async {
    await _verifyPhoneNumber();
    _listenForCode();
  }

  Future<void> _verifyPhoneNumber() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          _handleVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          _handleVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          _handleCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          _handleCodeSent(verificationId);
        },
      );
    } catch (e) {
      if (!mounted) return;
      _handleVerificationError(e.toString());
    }
  }

  void _handleVerificationCompleted(PhoneAuthCredential credential) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await FirebaseAuth.instance.signInWithCredential(credential);

      // AuthWrapper will handle navigation automatically when auth state changes
      // No need to manually navigate

    } catch (e) {
      print('Error signing in with credential: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred during login. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleVerificationFailed(FirebaseAuthException e) {
    String errorMsg;
    if (e.message?.contains('blocked') == true || e.message?.contains('unusual activity') == true) {
      errorMsg = 'Too many attempts. Wait 24 hours or try a different device.';
    } else {
      errorMsg = 'An error occurred during verification. Please try again.';
    }

    setState(() {
      _isLoading = false;
      _errorMessage = errorMsg;
    });

    print('Firebase verification failed: ${e.message}');
  }

  void _handleCodeSent(String verificationId) {
    setState(() {
      _verificationId = verificationId;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _handleVerificationError(String error) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Network error. Check connection and try again.';
    });

    print('Verification error: $error');
  }

  Future<void> _signInWithOTP() async {
    if (_verificationId.isEmpty) {
      setState(() {
        _errorMessage = 'Verification ID is missing. Please request a new code.';
      });
      return;
    }

    if (_smsCode.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(_smsCode)) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // AuthWrapper will handle navigation automatically
      // No need to manually navigate here

    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          errorMessage = 'Invalid OTP. Please check the code and try again.';
          break;
        case 'expired-action-code':
          errorMessage = 'OTP has expired. Please request a new code.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please wait before trying again.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        default:
          errorMessage = 'Verification failed. Please try again.';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      print('Unexpected error during OTP verification: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(60),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 60,
                            child: Image.asset(
                              'assets/s_logo.png',
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Verify Your Number',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the 6-digit code sent to ${widget.phoneNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_isLoading)
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Sending verification code...'),
                            ],
                          ),
                        ),

                      if (!_isLoading)
                        Column(
                          children: [
                            // Make the entire boxes row clickable and focusable
                            GestureDetector(
                              onTap: () {
                                _otpFocusNode.requestFocus();
                              },
                              child: Column(
                                children: [
                                  // Invisible input field that handles typing
                                  Opacity(
                                    opacity: 0.0,
                                    child: Container(
                                      height: 40,
                                      child: TextField(
                                        controller: _otpController,
                                        focusNode: _otpFocusNode,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        autofocus: false, // Remove auto-focus to prevent conflicts
                                        enableInteractiveSelection: true,
                                        showCursor: true,
                                        cursorColor: AppColors.brandBlue,
                                        cursorWidth: 2,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 8,
                                          color: Colors.transparent,
                                        ),
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          focusedErrorBorder: InputBorder.none,
                                          filled: false,
                                        ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                        ],
                                        onChanged: (value) {
                                          // Handle autofill detection
                                          if (value.length == 6 && _smsCode != value) {
                                            // This might be an autofill - verify it's all digits
                                            if (RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                                              _updateSmsCode(value);
                                            }
                                          } else {
                                            _updateSmsCode(value);
                                          }
                                        },
                                        onSubmitted: (value) {
                                          if (value.length == 6) {
                                            _signInWithOTP();
                                          }
                                        },
                                      ),
                                    ),
                                  ),

                                  // Visual OTP input boxes
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      6,
                                      (index) => GestureDetector(
                                        onTap: () {
                                          _otpFocusNode.requestFocus();
                                        },
                                        child: Container(
                                          width: 45,
                                          height: 55,
                                          margin: const EdgeInsets.symmetric(horizontal: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: _otpFocusNode.hasFocus && index == _smsCode.length
                                                  ? AppColors.brandBlue
                                                  : index < _smsCode.length
                                                      ? AppColors.brandBlue
                                                      : Colors.grey.shade300,
                                              width: _otpFocusNode.hasFocus && index == _smsCode.length
                                                  ? 2
                                                  : index < _smsCode.length
                                                      ? 2
                                                      : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.white,
                                            boxShadow: [
                                              if (_otpFocusNode.hasFocus && index == _smsCode.length)
                                                BoxShadow(
                                                  color: AppColors.brandBlue.withOpacity(0.2),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                )
                                              else if (index < _smsCode.length)
                                                BoxShadow(
                                                  color: AppColors.brandBlue.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              index < _smsCode.length ? _smsCode[index] : '',
                                              style: GoogleFonts.poppins(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: index < _smsCode.length
                                                    ? AppColors.brandBlue
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Show hint when no code entered
                                  if (_smsCode.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: GestureDetector(
                                        onTap: () {
                                          _otpFocusNode.requestFocus();
                                        },
                                        child: Text(
                                          'Tap to start typing',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      if (_smsCode.length != 6 && _smsCode.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Enter all 6 digits',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () => _verifyPhoneNumber(),
                        child: Text(
                          _isLoading ? 'Resending...' : 'Resend Code',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _isLoading ? Colors.grey : AppColors.brandBlue,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isButtonEnabled ? _signInWithOTP : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          disabledBackgroundColor: const Color(0xFFCCCCCC),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _isButtonEnabled ? AppColors.brandGradient : null,
                            borderRadius: BorderRadius.circular(12.0),
                            color: _isButtonEnabled ? null : const Color(0xFFCCCCCC),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            height: 56,
                            child: Text(
                              'Verify & Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Wrong number? Change it',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),  // Bottom spacing
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
