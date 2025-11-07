import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/screens/set_pickup_address_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftwash_mobile/widgets/iron_icon.dart';
import 'package:swiftwash_mobile/widgets/washing_machine_icon.dart';
import 'package:swiftwash_mobile/widgets/custom_icons.dart';

class Step3Widget extends StatefulWidget {
  final PageController pageController;
  final List<Map<String, dynamic>> items;
  final String selectedService;
  final String pickupDate;
  final String pickupTime;
  final String deliveryDate;
  final String deliveryTime;
  final double swiftCharge;
  final Function(Map<String, dynamic>?)? onAddressSelected;

  const Step3Widget({
    super.key,
    required this.pageController,
    required this.items,
    required this.selectedService,
    required this.pickupDate,
    required this.pickupTime,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.swiftCharge,
    this.onAddressSelected,
  });

  @override
  _Step3WidgetState createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<Step3Widget>
    with SingleTickerProviderStateMixin {
  int _selectedAddressIndex = -1;
  Map<String, dynamic>? _selectedAddress;

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  int _animationCount = 0;

  late Stream<List<Map<String, dynamic>>> _addressesStream;

  @override
  void initState() {
    super.initState();
    _addressesStream = _getAddressesStream();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.05),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_animationCount < 2) {
          _animationController.forward();
          _animationCount++;
        }
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getAddressesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> _deleteAddress(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(docId)
          .delete();
    } catch (e) {
      print("Error deleting address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete address: $e')),
      );
    }
  }

  double get _itemTotal => widget.items.fold(0, (sum, item) => sum + (item['quantity'] as int) * (item['price'] as double));
  double get _discount => 20;
  double get _finalTotal => _itemTotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review Your Order', style: AppTypography.h1),
                    const SizedBox(height: 4),
                    Text('Check your items and confirm pickup address.',
                        style: AppTypography.subtitle),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SlideTransition(
                    position: _offsetAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          _buildOrderSummary(),
                          const SizedBox(height: 16),
                        _buildAddressSection(),
                        const SizedBox(height: 16),
                        _buildAddressDetails(),
                        const SizedBox(height: 16),
                        _buildSpecialInstructions(),
                          const SizedBox(height: 16),
                          _buildPriceBreakdown(),
                          const SizedBox(height: 120), // For bottom button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _selectedAddressIndex != -1
                            ? () {
                                widget.pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _selectedAddressIndex != -1
                                ? AppColors.bookingCardGradient
                                : null,
                            color: _selectedAddressIndex != -1
                                ? null
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            height: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Proceed to Payment',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Final Total: ₹${_finalTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 16.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_forward,
                                          color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    Widget serviceIcon;
    switch (widget.selectedService) {
      case 'Ironing':
        serviceIcon = IronIcon(height: 24, width: 24, color: AppColors.actionBlue);
        break;
      case 'Swift':
        serviceIcon = Icon(Icons.flash_on, color: AppColors.swiftOrange);
        break;
      default:
        serviceIcon = WashingMachineIcon(height: 24, width: 24, color: AppColors.actionBlue);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  serviceIcon,
                  const SizedBox(width: 8),
                  Text(widget.selectedService, style: AppTypography.cardTitle),
                ],
              ),
            ],
          ),
          const Divider(),
          ...widget.items.where((item) => item['quantity'] > 0).map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item['name']} × ${item['quantity']}'),
                  Text('₹${(item['price'] as double) * (item['quantity'] as int)}'),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.actionBlue),
                  const SizedBox(width: 8),
                  Text('Schedule', style: AppTypography.cardTitle),
                ],
              ),
              GestureDetector(
                onTap: () {
                  widget.pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Chip(
                  label: Text('Edit'),
                  avatar: Icon(Icons.edit, size: 16),
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.shopping_basket),
              const SizedBox(width: 8),
              Text('Pickup: ${widget.pickupDate}, ${widget.pickupTime}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.moped),
              const SizedBox(width: 8),
              Text('Delivery: ${widget.deliveryDate}, ${widget.deliveryTime}'),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₹${_itemTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pickup & Delivery Address', style: AppTypography.h2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print('Add address button tapped');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SetPickupAddressScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.actionBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.actionBlue,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _addressesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Text('No addresses found. Please add a new address.'),
              );
            }

            final addresses = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _AddressCard(
                    title: address['addressType'] ?? 'Address',
                    address: '${address['flatHouseNo']}, ${address['street']}, ${address['pincode']}',
                    isSelected: _selectedAddressIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedAddressIndex = index;
                        _selectedAddress = address;
                      });
                      widget.onAddressSelected?.call(address);
                    },
                    onDelete: () => _deleteAddress(address['id']),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddressDetails() {
    if (_selectedAddressIndex == -1) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _addressesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty || _selectedAddressIndex >= snapshot.data!.length) {
          return const SizedBox.shrink();
        }

        final selectedAddress = snapshot.data![_selectedAddressIndex];
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Address Details', style: AppTypography.h2),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: selectedAddress['fullName'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  // Update the address in the selected address
                  // This would typically be saved to the database
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: selectedAddress['phoneNumber'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  // Update the address in the selected address
                  // This would typically be saved to the database
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: selectedAddress['flatHouseNo'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Flat/House No. & Building',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  // Update the address in the selected address
                  // This would typically be saved to the database
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: selectedAddress['landmark'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Landmark (Optional)',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (value) {
                  // Update the address in the selected address
                  // This would typically be saved to the database
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Building Information:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                selectedAddress['flatHouseNo'] ?? 'Building details will be added',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialInstructions() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Any special instructions? (e.g., delicate fabrics, starch preference)',
          border: InputBorder.none,
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Breakdown', style: AppTypography.cardTitle),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Total'),
              Text('₹${_itemTotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('New Customer Discount', style: TextStyle(color: Colors.green)),
              Text('-₹${_discount.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Final Total', style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
              Text('₹${_finalTotal.toStringAsFixed(2)}', style: AppTypography.h2.copyWith(color: AppColors.brandBlue, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String title;
  final String address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.title,
    required this.address,
    this.isSelected = false,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.bookingCardGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? Colors.white : AppColors.brandBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
                  Text(address, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: isSelected ? Colors.white : Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
