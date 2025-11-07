import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UPIService {
  final BuildContext context;

  UPIService(this.context);

  // Generate UPI payment URL
  String _generateUPIUrl({
    required double amount,
    required String orderId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    final upiHandle = dotenv.env['UPI_HANDLE'] ?? 'manas-kashinath@ptaxis';
    final merchantName = dotenv.env['MERCHANT_NAME'] ?? 'SwiftWash Laundry';
    final currency = dotenv.env['CURRENCY'] ?? 'INR';

    // UPI deeplink format: upi://pay?pa=UPI_ID&pn=MERCHANT_NAME&am=AMOUNT&cu=CURRENCY&tn=ORDER_ID
    final uri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiHandle, // Payee address (UPI ID)
        'pn': merchantName, // Payee name
        'am': amount.toStringAsFixed(2), // Amount
        'cu': currency, // Currency
        'tn': 'Payment for Order #$orderId', // Transaction note
        if (customerName.isNotEmpty) 'tr': orderId, // Transaction reference
        if (customerPhone != null && customerPhone.isNotEmpty) 'tn': '$customerName - $customerPhone',
      },
    );

    return uri.toString();
  }

  // Initiate UPI payment
  Future<bool> initiatePayment({
    required double amount,
    required String orderId,
    required String customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      final upiUrl = _generateUPIUrl(
        amount: amount,
        orderId: orderId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
      );

      // Show loading dialog
      _showPaymentDialog('Initiating UPI Payment...');

      // Attempt to launch UPI app
      final canLaunch = await canLaunchUrl(Uri.parse(upiUrl));

      if (canLaunch) {
        final launched = await launchUrl(
          Uri.parse(upiUrl),
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          // Show success message
          _showPaymentDialog('UPI payment initiated successfully!\n\nPlease complete the payment in your UPI app.');

          // For demo purposes, we'll simulate a successful payment after a delay
          // In production, you would verify payment status from your backend
          await Future.delayed(const Duration(seconds: 3));

          return true;
        } else {
          _showError('Could not launch UPI app. Please ensure you have a UPI-enabled app installed.');
          return false;
        }
      } else {
        _showError('No UPI app found on your device. Please install a UPI-enabled app like Google Pay, PhonePe, Paytm, etc.');
        return false;
      }
    } catch (e) {
      _showError('Error initiating UPI payment: $e');
      return false;
    }
  }

  // Show payment dialog
  void _showPaymentDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SwiftWash Laundry'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Get list of installed UPI apps (for selection)
  Future<List<String>> getInstalledUPIApps() async {
    // Common UPI package names
    final upiApps = [
      'com.google.android.apps.nbu.paisa.user', // Google Pay
      'com.phonepe.app', // PhonePe
      'net.one97.paytm', // Paytm
      'in.org.npci.upiapp', // BHIM
      'com.freecharge.android', // FreeCharge
      'com.mobikwik_new', // MobiKwik
      'com.icicibank.pockets', // Pockets
    ];

    return upiApps;
  }

  // Check if UPI is supported on the device
  Future<bool> isUPISupported() async {
    const upiUrl = 'upi://pay?pa=test@upi&pn=Test&am=1&cu=INR';
    return await canLaunchUrl(Uri.parse(upiUrl));
  }
}
