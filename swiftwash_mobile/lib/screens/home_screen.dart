import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swiftwash_mobile/widgets/iron_icon.dart';
import 'package:swiftwash_mobile/widgets/washing_machine_icon.dart';
import 'package:swiftwash_mobile/screens/order_process_screen.dart';
import 'package:swiftwash_mobile/greetings.dart';
import 'package:swiftwash_mobile/cart_service.dart';
import 'package:swiftwash_mobile/screens/orders_screen.dart';
import 'package:swiftwash_mobile/screens/tracking_screen.dart';
import 'package:swiftwash_mobile/screens/main_screen.dart';
import 'package:swiftwash_mobile/screens/profile_screen.dart';
import 'package:swiftwash_mobile/screens/premium_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  List<DocumentSnapshot> _ongoingOrders = [];
  StreamSubscription<QuerySnapshot>? _ordersStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _setupOngoingOrdersStream();
  }

  @override
  void dispose() {
    _cleanupStreams();
    super.dispose();
  }

  void _cleanupStreams() {
    if (_ordersStreamSubscription != null) {
      _ordersStreamSubscription!.cancel();
      _ordersStreamSubscription = null;
    }

    // Clear order data when streams are cleaned
    if (mounted) {
      setState(() {
        _ongoingOrders = [];
      });
    }
  }

  String _getOrderStatusText(String status, DocumentSnapshot? orderDoc) {
    // Only show processing status for certain order stages, not immediately after placing
    if (orderDoc != null) {
      final data = orderDoc.data() as Map<String, dynamic>;
      final processingStatus = data['currentProcessingStatus'] as String?;
      final orderStatus = status.toLowerCase();

      // Only show processing status if the order is actually being processed at the facility
      if (processingStatus != null && processingStatus.isNotEmpty &&
          ['processing', 'reached_facility', 'washing', 'cleaning', 'drying', 'ironing', 'sorting'].contains(orderStatus)) {
        return _getProcessingStatusText(processingStatus);
      }
    }

    switch (status.toLowerCase()) {
      case 'new':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'driver_assigned':
        return 'Driver Assigned';
      case 'out for pickup':
      case 'out_for_pickup':
        return 'Out for Pickup';
      case 'reached_pickup_location':
      case 'reached pickup location':
        return 'Reached Pickup Location';
      case 'picked up':
      case 'picked_up':
        return 'Picked Up';
      case 'transit_to_facility':
      case 'transit to facility':
        return 'In Transit to Facility';
      case 'reached_facility':
      case 'reached facility':
        return 'Processing Started';
      case 'processing':
        return 'Processing at Facility';
      case 'washing':
        return 'Washing in Progress';
      case 'drying':
        return 'Drying in Progress';
      case 'cleaning':
        return 'Cleaning in Progress';
      case 'ironing':
        return 'Ironing in Progress';
      case 'sorting':
        return 'Sorting in Progress';
      case 'ready_for_delivery':
      case 'ready for delivery':
        return 'Ready for Delivery';
      case 'out_for_delivery':
      case 'out for delivery':
        return 'Out for Delivery';
      case 'reached_delivery_location':
      case 'reached delivery location':
        return 'Reached Your Location';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Order Completed';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return status.replaceAll('_', ' ').split(' ').map((word) =>
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
        ).join(' ');
    }
  }

  String _getProcessingStatusText(String processingStatus) {
    switch (processingStatus.toLowerCase()) {
      case 'sorting':
        return 'Sorting Clothes';
      case 'washing':
        return 'Washing in Progress';
      case 'drying':
        return 'Drying Clothes';
      case 'cleaning':
        return 'Cleaning Items';
      case 'ironing':
        return 'Ironing Clothes';
      case 'quality_check':
        return 'Quality Check';
      case 'ready_for_delivery':
        return 'Ready for Delivery';
      case 'arrived_at_facility':
        return 'Arrived at Facility';
      case 'transit_to_facility':
        return 'In Transit to Facility';
      default:
        return 'Processing Order';
    }
  }

  Future<void> _loadCart() async {
    final items = await CartService.loadCart();
    setState(() {
      _cartItems = items;
    });
  }

  void _setupOngoingOrdersStream() {
    // Cancel any existing stream
    _ordersStreamSubscription?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // More restrictive ongoing statuses - exclude completed and cancelled
      final ongoingStatuses = ['new', 'processing', 'picked_up', 'out for pickup', 'transit to facility', 'reached facility', 'washing', 'cleaning', 'drying', 'ironing', 'sorting', 'ready for delivery', 'out for delivery', 'reached pickup location', 'transit to facility'];

      print('Setting up order stream for user: ${user.uid}');
      print('Ongoing statuses: $ongoingStatuses');

      _ordersStreamSubscription = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(20) // Increased limit to ensure we get all recent orders
          .snapshots()
          .listen((snapshot) {
            // More strict filtering - don't show completed or cancelled orders
            final filteredOrders = snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] as String?)?.toLowerCase() ?? '';
              final isOngoing = ongoingStatuses.any((s) => status.contains(s.toLowerCase()));

              // Exclude completed and cancelled orders explicitly
              if (status.contains('completed') || status.contains('cancelled') || status.contains('delivered')) {
                return false;
              }

              print('Order ${doc.id}: status="${data['status']}", ongoing=${isOngoing}');
              return isOngoing;
            }).toList();

            print('Real-time: Found ${snapshot.docs.length} total orders, showing ${filteredOrders.length} ongoing orders for tracking');

            // Log the status of each order being shown
            for (var order in filteredOrders) {
              final data = order.data() as Map<String, dynamic>;
              print('Showing order ${order.id} with status: "${data['status']}"');
            }

            if (mounted) {
              setState(() {
                _ongoingOrders = filteredOrders;
              });
            }
          }, onError: (error) {
            print('Error in ongoing orders stream: $error');
            // Fallback: Try without ordering
            try {
              _ordersStreamSubscription = FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .limit(20)
                  .snapshots()
                  .listen((snapshot) {
                    final fallbackOrders = snapshot.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = (data['status'] as String?)?.toLowerCase() ?? '';
                      const excluded = ['completed', 'cancelled', 'delivered'];
                      return ongoingStatuses.any((s) => status.contains(s.toLowerCase())) &&
                             excluded.every((ex) => !status.contains(ex));
                    }).toList();

                    print('Fallback: Loaded ${fallbackOrders.length} ongoing orders');
                    if (mounted) {
                      setState(() {
                        _ongoingOrders = fallbackOrders;
                      });
                    }
                  });
            } catch (fallbackError) {
              print('Fallback stream also failed: $fallbackError');
            }
          });
    } else {
      // User logged out, clear orders and reset stream
      if (mounted) {
        setState(() {
          _ongoingOrders = [];
        });
      }
      print('User logged out, no ongoing orders stream set up.');
    }
  }

  Widget _buildHomeContent() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _Greeting(),
                const SizedBox(height: 24),
                _ServiceCard(
                  iconWidget: IronIcon(height: 36, width: 36),
                  title: "Ironing",
                  subtitle: "Crisp, clean, and ready to wear.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderProcessScreen(selectedService: "Ironing"),
                      ),
                    ).then((_) => _loadCart());
                  },
                ),
                const SizedBox(height: 12),
                _ServiceCard(
                  iconWidget: WashingMachineIcon(height: 36, width: 36),
                  title: "Laundry",
                  subtitle: "Fresh clothes, on time - every time.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderProcessScreen(selectedService: "Laundry"),
                      ),
                    ).then((_) => _loadCart());
                  },
                ),
                const SizedBox(height: 12),
                _ServiceCard(
                  iconWidget: Icon(Icons.flash_on, size: 36),
                  title: "Swift",
                  subtitle: "Quick Laundry, delivered in 2-4 hours.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderProcessScreen(selectedService: "Swift"),
                      ),
                    ).then((_) => _loadCart());
                  },
                ),
                const SizedBox(height: 24),
                _ActionButtons(),
                const SizedBox(height: 24),
                _SectionHeader(title: "Special Offers"),
                const SizedBox(height: 16),
                _SpecialOffers(),
                const SizedBox(height: 120), // 🔽 Navigation bar will be below this
              ],
            ),
          ),
        ),
        if (_cartItems.isNotEmpty)
          Positioned(
            bottom: 16, // 🎯 Matching left/right spacing for perfect symmetry
            left: 16,
            right: 16,
            child: _ProceedToOrderCard(
              itemCount: _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int)),
              total: _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int) * (item['price'] as double)),
              serviceName: (_cartItems.first['serviceName'] as String?) ?? '',
              onClear: () {
                setState(() {
                  _cartItems = [];
                  CartService.clearCart();
                });
              },
              onProceed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderProcessScreen(selectedService: (_cartItems.first['serviceName'] as String?) ?? ''),
                  ),
                ).then((_) => _loadCart());
              },
            ),
          )
        else if (_ongoingOrders.isNotEmpty)
          Positioned(
            bottom: 16, // 🎯 Matching left/right spacing for perfect symmetry
            left: 16,
            right: 16,
            child: _StackedTrackOrderCards(
              orders: _ongoingOrders,
              orderStatusTextFunction: _getOrderStatusText,
              onDismissed: (orderId) {
                setState(() {
                  _ongoingOrders.removeWhere((order) => order.id == orderId);
                });
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _HomeHeader(
          itemCount: _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int)),
          total: _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int) * (item['price'] as double)),
        ),
      ),
      body: _buildHomeContent(),
    );
  }
}

class _Greeting extends StatefulWidget {
  @override
  __GreetingState createState() => __GreetingState();
}

class __GreetingState extends State<_Greeting> {
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  void _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.displayName?.split(' ').first ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = getGreeting();
    final message = getUniqueMessage();
    final name = _displayName.isNotEmpty ? ', $_displayName!' : '!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$greeting$name", style: AppTypography.h1),
        const SizedBox(height: 4),
        Text(message, style: AppTypography.subtitle),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandBlue.withOpacity(0.1),
              AppColors.brandGreen.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
        ),
        child: Row(
          children: [
            if (iconWidget != null) iconWidget!,
            if (icon != null) Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.cardSubtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.location_on,
            label: "Track Order",
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            icon: Icons.local_offer,
            label: "View Offers",
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onVewAll;

  const _SectionHeader({required this.title, this.onVewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (onVewAll != null)
          TextButton(
            onPressed: onVewAll,
            child: const Text("View All"),
          ),
      ],
    );
  }
}

class _SpecialOffers extends StatelessWidget {
  final List<Map<String, dynamic>> offers = [
    {
      'color': Colors.purple.shade100,
      'title': "Refer & Earn 50% OFF",
      'subtitle': "Get 50% off Swift Premium membership",
      'buttonText': "Share & Earn",
      'onPressed': null, // Will navigate to Premium screen
    },
    {
      'color': Colors.orange.shade100,
      'title': "New Customer Special",
      'subtitle': "Get first 3 orders at 80% discount",
      'buttonText': "Copy NEWCUSTOMER",
      'onPressed': null, // Will copy promo code
    },
  ];

  void _copyPromoCode(BuildContext context) {
    // Import clipboard functionality
    // For now, we'll show a snackbar with the promo code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 NEWCUSTOMER code copied to clipboard! Use it at payment (Step 3)'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToPremium(BuildContext context) {
    // Navigate to Premium screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index == offers.length - 1 ? 0 : 16),
            child: _OfferCard(
              color: offers[index]['color'],
              title: offers[index]['title'],
              subtitle: offers[index]['subtitle'],
              buttonText: offers[index]['buttonText'],
              onPressed: index == 0
                ? () => _navigateToPremium(context)
                : () => _copyPromoCode(context),
            ),
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onPressed;

  const _OfferCard({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: onPressed ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}



class _StackedTrackOrderCards extends StatefulWidget {
  final List<DocumentSnapshot> orders;
  final String Function(String, DocumentSnapshot?) orderStatusTextFunction;
  final Function(String) onDismissed;

  const _StackedTrackOrderCards({
    required this.orders,
    required this.orderStatusTextFunction,
    required this.onDismissed
  });

  @override
  __StackedTrackOrderCardsState createState() => __StackedTrackOrderCardsState();
}

class __StackedTrackOrderCardsState extends State<_StackedTrackOrderCards> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: List.generate(widget.orders.length, (index) {
        final order = widget.orders[index];
        final orderData = order.data() as Map<String, dynamic>;
        final isTopCard = index == widget.orders.length - 1;

        return Transform.translate(
          offset: Offset(0, (widget.orders.length - 1 - index) * -10.0),
            child: isTopCard
              ? _TrackOrderCard(
                  orderId: order.id,
            orderStatus: widget.orderStatusTextFunction(orderData['status'] ?? 'new', order),
                  onTrack: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackingScreen(orderId: order.id),
                      ),
                    );
                  },
                  onDismiss: () => widget.onDismissed(order.id),
                )
              : _buildStackedCard(),
        );
      }).toList(),
    );
  }

  Widget _buildStackedCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
    );
  }
}

class _TrackOrderCard extends StatelessWidget {
  final String orderId;
  final String orderStatus;
  final VoidCallback onTrack;
  final VoidCallback onDismiss;

  const _TrackOrderCard({
    required this.orderId,
    required this.orderStatus,
    required this.onTrack,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(orderStatus,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: onTrack,
            child: const Text("Track Order", style: TextStyle(color: Color(0xFF003366))),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ProceedToOrderCard extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onClear;
  final String serviceName;
  final VoidCallback onProceed;

  const _ProceedToOrderCard({
    required this.itemCount,
    required this.total,
    required this.onClear,
    required this.serviceName,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$itemCount items added for $serviceName", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Total: ₹${total.toStringAsFixed(0)}", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onProceed,
            child: Text("Proceed to Order", style: TextStyle(color: AppColors.brandBlue)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final int itemCount;
  final double total;

  const _HomeHeader({required this.itemCount, required this.total});

  @override
  Widget build(BuildContext context) {
    final bool hasItems = itemCount > 0;

    return SafeArea(
      child: Container(
        height: 56, // Explicit height to ensure consistent layout
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Always centered logo
            Center(
              child: Image.asset('assets/s_logo.png', height: 28),
            ),
            // Left and right items overlaid on sides
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasItems) _buildIconBadge() else SizedBox.shrink(),
                  if (hasItems) _buildTotalPill() else SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const FaIcon(FontAwesomeIcons.shirt, color: Color(0xFF1F2937), size: 24),
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                itemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPill() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          "₹${total.toStringAsFixed(0)}",
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
