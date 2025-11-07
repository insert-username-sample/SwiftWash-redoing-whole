import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/screens/order_details_screen.dart';
import 'package:swiftwash_mobile/screens/tracking_screen.dart';
import 'package:swiftwash_mobile/widgets/order_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _ordersStream;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupOrdersStream(); // Initial setup
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _setupOrdersStream(); // Re-setup on auth change
        });
      }
    });
  }

  void _setupOrdersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Setting up orders stream for user: ${user.uid}');
      _ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      print('No user logged in, setting up empty stream.');
      _ordersStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87, size: 30),
            onPressed: () {
              // Handle search action
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: _tabController,
            indicator: _GradientUnderlineTabIndicator(
              gradient: AppColors.bookingCardGradient,
              thickness: 5.0,
            ),
            labelStyle: const TextStyle(fontSize: 18),
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey.shade600,
            tabs: const [
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error in orders stream: ${snapshot.error}');
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('No orders found for the current user.');
            return const Center(child: Text('No orders found.'));
          }
          if (FirebaseAuth.instance.currentUser == null) {
            return const Center(child: Text('Please log in to see your orders.'));
          }

          final allOrders = snapshot.data!.docs;
          print('Fetched ${allOrders.length} orders.');

          // Comprehensive status filtering including all new statuses
          final ongoingStatuses = [
            'new', 'confirmed', 'driver_assigned', 'out_for_pickup', 'out for pickup',
            'reached_pickup_location', 'picked_up', 'transit_to_facility', 'reached_facility',
            'processing', 'sorting', 'washing', 'cleaning', 'ironing', 'drying',
            'quality_check', 'ready_for_delivery', 'ready for delivery', 'out_for_delivery',
            'out for delivery', 'reached_delivery_location'
          ];
          final completedStatuses = ['delivered', 'completed'];
          final cancelledStatuses = ['cancelled', 'pickup_failed', 'pickup failed', 'failed', 'returned', 'issue_reported'];

          final ongoingOrders = allOrders.where((doc) {
            final status = (doc['status'] as String?)?.toLowerCase() ?? '';
            return ongoingStatuses.any((s) => status.contains(s.toLowerCase()));
          }).toList();

          final completedOrders = allOrders.where((doc) {
            final status = (doc['status'] as String?)?.toLowerCase() ?? '';
            return completedStatuses.any((s) => status.contains(s.toLowerCase()));
          }).toList();

          final cancelledOrders = allOrders.where((doc) {
            final status = (doc['status'] as String?)?.toLowerCase() ?? '';
            return cancelledStatuses.any((s) => status.contains(s.toLowerCase()));
          }).toList();

          print('Ongoing: ${ongoingOrders.length}, Completed: ${completedOrders.length}, Cancelled: ${cancelledOrders.length}');

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(ongoingOrders),
              _buildOrdersList(completedOrders),
              _buildOrdersList(cancelledOrders),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> orders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final orderData = order.data() as Map<String, dynamic>;

        // Safely get the timestamp and format it
        final Timestamp? timestamp = orderData['createdAt'] as Timestamp?;
        final String formattedTime = timestamp != null
            ? DateFormat('MMM d, yyyy, h:mm a').format(timestamp.toDate())
            : 'No date';

        // Safely get the items
        final itemsList = orderData['items'] as List<dynamic>? ?? [];
        final String items = itemsList.map((item) => item['name']).join(', ');

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(orderId: order.id)));
          },
          child: OrderCard(
            orderId: orderData['orderId'] ?? order.id, // Use server-generated OrderID or fallback to document ID
            status: orderData['status'] ?? 'Unknown',
            items: items,
            price: (orderData['finalTotal'] ?? 0).toString(),
            time: formattedTime,
            onTrack: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      TrackingScreen(orderId: order.id)));
            },
            onReorder: orderData['status'] == 'Completed' ? () {} : null,
            orderData: orderData, // Pass the full order data for detailed status display
          ),
        );
      },
    );
  }
}

class _GradientUnderlineTabIndicator extends Decoration {
  final Gradient gradient;
  final double thickness;

  const _GradientUnderlineTabIndicator({
    required this.gradient,
    this.thickness = 4.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _GradientUnderlinePainter(gradient, thickness);
  }
}

class _GradientUnderlinePainter extends BoxPainter {
  final Gradient gradient;
  final double thickness;

  _GradientUnderlinePainter(this.gradient, this.thickness);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0.0, 0.0, rect.width, rect.height))
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(
          rect.left,
          rect.bottom - thickness,
          rect.width,
          thickness,
        ),
        topLeft: const Radius.circular(4.0),
        topRight: const Radius.circular(4.0),
      ));

    canvas.drawPath(path, paint);
  }
}
