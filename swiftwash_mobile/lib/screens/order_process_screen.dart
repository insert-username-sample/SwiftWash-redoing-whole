import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swiftwash_mobile/widgets/gradient_progress_bar.dart';
import 'package:swiftwash_mobile/widgets/step_1_widget.dart';
import 'package:swiftwash_mobile/widgets/step_2_widget.dart';
import 'package:swiftwash_mobile/widgets/step_3_widget.dart';
import 'package:swiftwash_mobile/widgets/step_4_widget.dart';
import 'package:swiftwash_mobile/cart_service.dart';

class OrderProcessScreen extends StatefulWidget {
  final String selectedService;
  const OrderProcessScreen({super.key, required this.selectedService});

  @override
  _OrderProcessScreenState createState() => _OrderProcessScreenState();
}

class _OrderProcessScreenState extends State<OrderProcessScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Future<void> _initFuture;

  List<Map<String, dynamic>> _items = [];
  String _pickupDate = '';
  String _pickupTime = '';
  String _deliveryDate = '';
  String _deliveryTime = '';
  String _serviceName = '';
  double _swiftCharge = 0.0;
  Map<String, dynamic>? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  Future<void> _initialize() async {
    await _checkAndClearCart();
    await _loadCart();
  }

  Future<void> _checkAndClearCart() async {
    final items = await CartService.loadCart();
    if (items.isNotEmpty && items.first['serviceName'] != widget.selectedService) {
      await CartService.clearCart();
    }
  }

  Future<void> _loadCart() async {
    final items = await CartService.loadCart();
    if (mounted) {
      setState(() {
        _items = items;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ClipOval(
                clipBehavior: Clip.antiAlias,
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF475467)),
                    onPressed: () {
                      print('Back button tapped, current page: $_currentPage');
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Text('Step ${_currentPage + 1} of 4', style: TextStyle(fontSize: 16, color: Color(0xFF475467))),
                  const SizedBox(width: 8),
                  Badge(
                    label: Text(_items.fold(0, (sum, item) => sum + (item['quantity'] as int)).toString()),
                    child: const FaIcon(FontAwesomeIcons.shirt, color: Color(0xFF475467)),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GradientProgressBar(value: (_currentPage + 1) / 4),
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading cart'));
          }
          return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swiping
            children: [
              Step1Widget(
                pageController: _pageController,
                selectedService: widget.selectedService,
                initialItems: _items,
                onUpdate: (items, service) {
                  setState(() {
                    _items = items;
                    _serviceName = service;
                  });
                },
              ),
              Step2Widget(
                pageController: _pageController,
                selectedService: widget.selectedService,
                onUpdate: (pickupDate, pickupTime, deliveryDate, deliveryTime, swiftCharge) {
                  setState(() {
                    _pickupDate = pickupDate;
                    _pickupTime = pickupTime;
                    _deliveryDate = deliveryDate;
                    _deliveryTime = deliveryTime;
                    _swiftCharge = swiftCharge;
                  });
                },
              ),
              Step3Widget(
                pageController: _pageController,
                items: _items,
                selectedService: widget.selectedService,
                pickupDate: _pickupDate,
                pickupTime: _pickupTime,
                deliveryDate: _deliveryDate,
                deliveryTime: _deliveryTime,
                swiftCharge: _swiftCharge,
                onAddressSelected: (address) {
                  setState(() {
                    _selectedAddress = address;
                  });
                },
              ),
              Step4Widget(
                pageController: _pageController,
                itemTotal: _items.fold(0, (sum, item) => sum + (item['price'] * item['quantity'])),
                swiftCharge: _swiftCharge,
                selectedAddress: _selectedAddress,
              ),
            ],
          );
        },
      ),
    );
  }
}
