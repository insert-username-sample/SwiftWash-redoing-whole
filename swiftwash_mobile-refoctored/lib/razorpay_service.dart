import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final BuildContext context;
  Completer<Map<String, dynamic>?> _completer = Completer<Map<String, dynamic>?>();
  String? _paymentId;

  RazorpayService(this.context) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentId = response.paymentId;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );
    _completer.complete({'success': true, 'paymentId': response.paymentId});
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed")),
    );
    _completer.complete({'success': false, 'error': response.message});
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  Future<Map<String, dynamic>?> checkout({
    required int amount,
    required String name,
    required String description,
    required String contact,
    required String email,
  }) {
    _completer = Completer<Map<String, dynamic>?>();
    // Get Razorpay API key from environment variables
    final apiKey = dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_your_key_id';

    var options = {
      'key': apiKey,
      'amount': amount,
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e.toString());
      _completer.complete({'success': false, 'error': e.toString()});
    }
    return _completer.future;
  }
}
