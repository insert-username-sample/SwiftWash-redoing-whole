import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/upi_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:swiftwash_mobile/screens/tracking_screen.dart';
import 'package:swiftwash_mobile/services/enhanced_order_service.dart';

class Step4Widget extends StatefulWidget {
  final PageController pageController;
  final double itemTotal;
  final double swiftCharge;
  final Map<String, dynamic>? selectedAddress;
  final String selectedService;

  const Step4Widget(
      {super.key,
      required this.pageController,
      required this.itemTotal,
      required this.swiftCharge,
      required this.selectedService,
      this.selectedAddress});

  @override
  _Step4WidgetState createState() => _Step4WidgetState();
}

class _Step4WidgetState extends State<Step4Widget> {
  int _selectedPaymentIndex = 0;
  int? _selectedUpiApp;
  final _promoCodeController = TextEditingController();
  final _upiIdController = TextEditingController();
  double _discount = 0;
  String _discountLabel = 'New Customer Discount';
  bool _promoApplied = false;
  late UPIService _upiService;
  final EnhancedOrderService _orderService = EnhancedOrderService();

  @override
  void initState() {
    super.initState();
    _upiService = UPIService(context);
    _checkIfNewCustomer();
  }

  Future<void> _checkIfNewCustomer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasOrdered = prefs.getBool('hasOrdered') ?? false;

    if (!hasOrdered) {
      final orders = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (orders.docs.isEmpty) {
        setState(() {
          _discount = 20;
        });
      }
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  double get _finalTotal => widget.itemTotal - _discount;

  bool get _isPaymentButtonEnabled {
    if (_finalTotal <= 0) {
      return true;
    }
    if (_selectedPaymentIndex == 0) {
      return _selectedUpiApp != null || _upiIdController.text.isNotEmpty;
    }
    return true;
  }

  void _applyPromoCode() {
    final promoCode = _promoCodeController.text.toUpperCase();
    if (promoCode == 'MANASFRIEND2012') {
      setState(() {
        _discount = widget.itemTotal + widget.swiftCharge;
        _discountLabel = 'Manas Friend Discount';
        _promoApplied = true;
      });
    } else if (promoCode == 'MANASRELATIVE2012') {
      setState(() {
        _discount = widget.itemTotal + widget.swiftCharge;
        _discountLabel = 'Manas Relative Discount';
        _promoApplied = true;
      });
    } else if (promoCode == 'AMANFRIEND2012') {
      setState(() {
        _discount = widget.itemTotal + widget.swiftCharge;
        _discountLabel = 'Aman Friend Discount';
        _promoApplied = true;
      });
    } else if (promoCode == 'AMANRELATIVE2012') {
      setState(() {
        _discount = widget.itemTotal + widget.swiftCharge;
        _discountLabel = 'Aman Relative Discount';
        _promoApplied = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid promo code.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promo code applied successfully!')),
    );
  }

  void _handlePayment() async {
    if (_finalTotal <= 0) {
      // Skip payment for zero amount
      final orderId = await _createOrderWithSmartId();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasOrdered', true);
      await prefs.setBool('orderPlaced', true);
      CartService.clearCart();

      if (orderId != null && mounted) {
        // Navigate to tracking screen for free orders
        await Future.delayed(const Duration(milliseconds: 100)); // Allow snackbar to show
        if (!mounted) return;

        Navigator.of(context).popUntil((route) => route.isFirst); // Go back to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TrackingScreen(orderId: orderId),
          ),
        );
      } else {
        // Fallback to home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    // Use UPI payment for all payment methods (for now)
    final paymentSuccess = await _upiService.initiatePayment(
      amount: _finalTotal,
      orderId: await _orderService.generateSmartOrderId(orderType: widget.selectedService),
      customerName: user?.displayName ?? 'Customer',
      customerPhone: user?.phoneNumber,
      customerEmail: user?.email,
    );

    if (mounted) {
      if (paymentSuccess) {
        _handleSuccessfulPayment();
      } else {
        _showPaymentFailedDialog();
      }
    }
  }

  void _showPaymentFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: const Text('Your payment could not be processed. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleSuccessfulPayment() async {
    final orderId = await _createOrderWithSmartId();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasOrdered', true);
    await prefs.setBool('orderPlaced', true);
    CartService.clearCart();

    if (orderId != null && mounted) {
      // Navigate to tracking screen
      await Future.delayed(const Duration(milliseconds: 100)); // Allow time for payment dialog to close
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst); // Go back to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TrackingScreen(orderId: orderId),
        ),
      );
    } else {
      // Fallback to home screen
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<String?> _createOrderWithSmartId() async {
    try {
      // Generate smart order ID first
      final smartOrderId = await _orderService.generateSmartOrderId(
        orderType: widget.selectedService,
        isUrgent: false, // Add your logic for urgent orders
        isReferred: false, // Add your logic for referred orders
        isStudent: false, // Add your logic for student orders
      );

      final cartItems = await CartService.loadCart();

      // Prepare order data
      final orderData = {
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'serviceName': widget.selectedService,
        'pickupAddress': widget.selectedAddress,
        'items': cartItems,
        'totalAmount': _finalTotal,
        'status': 'new',
        // ... other order fields
      };

      // Save order with smart ID
      final result = await _orderService.saveOrderWithSmartId(
        orderId: smartOrderId,
        orderData: orderData,
      );

      if (result['success']) {
        return smartOrderId;
      } else {
        throw Exception('Order creation failed');
      }
    } catch (e) {
      _showErrorDialog('Order creation failed: $e');
      return null;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is the required method that was missing
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Payment Method', style: AppTypography.h1),
                const SizedBox(height: 4),
                Text('Secure payments powered by UPI',
                    style: AppTypography.subtitle),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 16),
                    _buildPriceBreakdown(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isPaymentButtonEnabled ? _handlePayment : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _isPaymentButtonEnabled ? AppColors.brandGradient : null,
                  color: _isPaymentButtonEnabled ? null : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  alignment: Alignment.center,
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          'Pay ₹${_finalTotal.toStringAsFixed(2)} Securely',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      children: [
        _PaymentMethodTile(
          title: 'UPI',
          subtitle: 'Recommended • Instant',
          isSelected: _selectedPaymentIndex == 0,
          onTap: () => setState(() => _selectedPaymentIndex = 0),
        ),
        if (_selectedPaymentIndex == 0)
          _UpiPaymentOptions(
            selectedUpiApp: _selectedUpiApp,
            upiIdController: _upiIdController,
            onUpiAppSelected: (index) {
              setState(() {
                _selectedUpiApp = index;
                _upiIdController.clear();
              });
            },
            onUpiIdChanged: () {
              setState(() {
                _selectedUpiApp = null;
              });
            },
          ),
        const SizedBox(height: 8),
        _PaymentMethodTile(
          title: 'Wallets',
          subtitle: 'Paytm, Amazon Pay, PhonePe',
          isSelected: _selectedPaymentIndex == 1,
          onTap: () => setState(() => _selectedPaymentIndex = 1),
        ),
        const SizedBox(height: 8),
        _PaymentMethodTile(
          title: 'Cards',
          subtitle: 'Debit, Credit & Saved Cards',
          isSelected: _selectedPaymentIndex == 2,
          onTap: () => setState(() => _selectedPaymentIndex = 2),
        ),
        const SizedBox(height: 8),
        _PaymentMethodTile(
          title: 'Net Banking',
          subtitle: 'All major banks supported',
          isSelected: _selectedPaymentIndex == 3,
          onTap: () => setState(() => _selectedPaymentIndex = 3),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Details', style: AppTypography.h2),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Total', style: AppTypography.subtitle),
              Text('₹${widget.itemTotal.toStringAsFixed(2)}',
                  style: AppTypography.subtitle),
            ],
          ),
          const SizedBox(height: 8),
          if (_discount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_discountLabel,
                    style: AppTypography.subtitle.copyWith(color: Colors.green)),
                Text('-₹${_discount.toStringAsFixed(2)}',
                    style: AppTypography.subtitle.copyWith(color: Colors.green)),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCodeController,
                  decoration: InputDecoration(
                    hintText: 'Have a Promo Code?',
                    border: InputBorder.none,
                  ),
                ),
              ),
              _GradientOutlinedButton(
                onPressed: _applyPromoCode,
                text: 'Apply',
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Final Payable', style: AppTypography.h2),
              Text('₹${_finalTotal.toStringAsFixed(2)}',
                  style: AppTypography.h2),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2), // Border width
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.bookingCardGradient : null,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [AppShadows.cardShadow],
        ),
        child: Container(
          padding: const EdgeInsets.all(14.0), // Inner padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.bookingCardGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.white : AppColors.brandBlue,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle),
                  Text(subtitle, style: AppTypography.cardSubtitle),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpiPaymentOptions extends StatelessWidget {
  final int? selectedUpiApp;
  final TextEditingController upiIdController;
  final ValueChanged<int> onUpiAppSelected;
  final VoidCallback onUpiIdChanged;

  const _UpiPaymentOptions({
    this.selectedUpiApp,
    required this.upiIdController,
    required this.onUpiAppSelected,
    required this.onUpiIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              final appName = ['GPay', 'PhonePe', 'Paytm', 'BHIM'][index];
              return GestureDetector(
                onTap: () => onUpiAppSelected(index),
                child: _PaymentLogo(
                  name: appName,
                  isSelected: selectedUpiApp == index,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: upiIdController,
            onChanged: (_) => onUpiIdChanged(),
            decoration: InputDecoration(
              hintText: 'Enter UPI ID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: AppColors.brandBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentLogo extends StatelessWidget {
  final String name;
  final bool isSelected;

  const _PaymentLogo({required this.name, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    // In a real app, you'd use Image.asset() with actual logos
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.bookingCardGradient : null,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: isSelected ? Colors.white : Colors.grey.shade200,
            child: Text(name.substring(0, 1)),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: AppTypography.cardSubtitle),
      ],
    );
  }
}

class _GradientOutlinedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const _GradientOutlinedButton(
      {required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(2), // this will be the border width
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.0), // slightly smaller radius
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: ShaderMask(
            shaderCallback: (bounds) => AppColors.brandGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, // This color is needed, but will be overridden by the shader
              ),
            ),
          ),
        ),
      ),
    );
  }
}
