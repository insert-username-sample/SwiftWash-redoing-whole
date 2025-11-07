import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/order_status.dart';
import 'package:swiftwash_mobile/screens/order_details_screen.dart';
import 'package:swiftwash_mobile/screens/main_screen.dart';
import 'package:swiftwash_mobile/widgets/dynamic_steps_widget.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final List<OrderStatus> _statuses = [
    OrderStatus(
        title: 'Pending / Requested',
        subtitle: 'Your order has been placed',
        icon: Icons.receipt),
    OrderStatus(
        title: 'Scheduled',
        subtitle: 'Pickup scheduled for 10 PM today.',
        icon: Icons.calendar_today),
    OrderStatus(
        title: 'Picked Up',
        subtitle: 'Your items have been picked up.',
        icon: Icons.inventory_2),
    OrderStatus(
        title: 'In Transit to Facility',
        subtitle: 'Your clothes are on the way to our facility.',
        icon: Icons.local_shipping),
    OrderStatus(
        title: 'Arrived at Facility',
        subtitle: 'Items arrived at our cleaning center.',
        icon: Icons.business),
    OrderStatus(
        title: 'Sorting / Pre-Processing',
        subtitle: 'Sorting clothes by type and color.',
        icon: Icons.style),
    OrderStatus(
        title: 'Washing',
        subtitle: 'Washing in progress.',
        icon: Icons.local_laundry_service),
    OrderStatus(
        title: 'Drying',
        subtitle: 'Drying your clothes.',
        icon: Icons.dry_cleaning),
    OrderStatus(
        title: 'Ironing',
        subtitle: 'Ironing your clothes.',
        icon: Icons.iron),
    OrderStatus(
        title: 'Quality Check',
        subtitle: 'Final inspection for freshness and quality.',
        icon: Icons.check_circle),
    OrderStatus(
        title: 'Ready for Delivery',
        subtitle: 'Packed & ready for dispatch.',
        icon: Icons.inventory),
    OrderStatus(
        title: 'Out for Delivery',
        subtitle: 'Your order is on the way!',
        icon: Icons.delivery_dining),
    OrderStatus(
        title: 'Delivered',
        subtitle: 'Your clothes are delivered.',
        icon: Icons.home),
    OrderStatus(
        title: 'Completed / Closed',
        subtitle: 'Order closed. Thank you for using SwiftWash!',
        icon: Icons.done_all),
  ];
  int _currentStatusIndex = 0;
  late Timer _timer;
  late Stream<LatLng> _driverLocationStream;
  StreamSubscription<LatLng>? _driverLocationSubscription;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        if (_currentStatusIndex < _statuses.length - 1) {
          _currentStatusIndex++;
        } else {
          _timer.cancel();
        }
      });
    });

    // Initialize markers
    _initializeMarkers();
  }

  void _initializeMarkers() {
    // Customer location (simulate Bangalore area)
    _markers.add(
      Marker(
        markerId: const MarkerId('customer'),
        position: const LatLng(12.9716, 77.5946),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
    );

    // Facility location (simulate facility location)
    _markers.add(
      Marker(
        markerId: const MarkerId('facility'),
        position: const LatLng(12.9791, 77.5971),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'SwiftWash Facility'),
      ),
    );
  }

  void _setupDriverTracking(String orderStatus) {
    // Clean up existing subscription
    _driverLocationSubscription?.cancel();

    // Setup driver movement based on order status
    LatLng driverStart;
    LatLng driverEnd;

    switch (orderStatus) {
      case 'out_for_pickup':
        // Driver moving from facility to customer for pickup
        driverStart = const LatLng(12.9791, 77.5971); // Facility
        driverEnd = const LatLng(12.9716, 77.5946); // Customer
        break;
      case 'in_transit_to_facility':
        // Driver moving from customer back to facility
        driverStart = const LatLng(12.9716, 77.5946); // Customer
        driverEnd = const LatLng(12.9791, 77.5971); // Facility
        break;
      case 'out_for_delivery':
        // Driver moving from facility to customer for delivery
        driverStart = const LatLng(12.9791, 77.5971); // Facility
        driverEnd = const LatLng(12.9716, 77.5946); // Customer
        break;
      default:
        return;
    }

    _driverLocationStream = Stream.periodic(const Duration(seconds: 3), (count) {
      // Calculate driver position based on progress
      final progress = (count % 60) / 60.0; // 60 seconds for complete trip
      final lat = driverStart.latitude + (driverEnd.latitude - driverStart.latitude) * progress;
      final lng = driverStart.longitude + (driverEnd.longitude - driverStart.longitude) * progress;
      return LatLng(lat, lng);
    });

    _driverLocationSubscription = _driverLocationStream.listen((location) => _updateDriverMarker(location));
  }

  void _updateDriverMarker(LatLng location) {
    if (mounted) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId.value == 'driver');
        _markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: location,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });
      try {
        _mapController?.animateCamera(CameraUpdate.newLatLng(location));
      } catch (e) {
        // Handle exception
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _driverLocationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return WillPopScope(
            onWillPop: () async {
              // Navigate back to previous screen
              Navigator.pop(context);
              return true; // Prevent default back navigation
            },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      // Navigate back to previous screen
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text('Track Order'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: () {},
                    ),
                  ],
                ),
                body: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final currentStatusTitle = orderData['status'] ?? 'Pending / Requested';
          final currentStatus = _statuses.firstWhere(
              (s) => s.title == currentStatusTitle,
              orElse: () => _statuses.first);

          final showMap = [
            'Out for Pickup',
            'Picked Up',
            'In Transit to Facility',
            'Out for Delivery'
          ].contains(currentStatus.title);

          // Setup driver tracking for GPS statuses
          if (showMap && _driverLocationSubscription == null) {
            _setupDriverTracking(currentStatus.title.toLowerCase().replaceAll(' ', '_'));
          }

          return WillPopScope(
            onWillPop: () async {
              // Navigate back to previous screen
              Navigator.pop(context);
              return true; // Prevent default back navigation
            },
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    // Navigate back to home screen and clear navigation stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (route) => false,
                    );
                  },
                ),
                title: const Text('Track Order'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {},
                  ),
                ],
              ),
              body: SafeArea(
                top: false,
                bottom: true,
                child: Column(
                  children: [
                    _buildOrderSummaryCard(orderData),
                    Expanded(
                      child: _buildMainContent(showMap, currentStatus),
                    ),
                    _buildBottomDrawer(currentStatus),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildOrderSummaryCard(Map<String, dynamic> orderData) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: AppColors.trackingCardBorderGradient,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID', style: AppTypography.cardSubtitle),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final orderData = snapshot.data!.data() as Map<String, dynamic>;
                        final displayOrderId = orderData['orderId'] ?? widget.orderId;
                        return Text(displayOrderId, style: AppTypography.cardTitle);
                      }
                      return Text(widget.orderId, style: AppTypography.cardTitle);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Service', style: AppTypography.cardSubtitle),
                  Text(orderData['serviceName'] ?? 'Wash & Fold',
                      style: AppTypography.cardTitle),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ETA', style: AppTypography.cardSubtitle),
                  Text('45 mins', style: AppTypography.cardTitle),
                  const SizedBox(height: 8),
                  Text('Total', style: AppTypography.cardSubtitle),
                  Text('₹${orderData['finalTotal']?.toStringAsFixed(2) ?? '0.00'}',
                      style: AppTypography.cardTitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool showMap, OrderStatus currentStatus) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Colors.white,
        boxShadow: [AppShadows.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: showMap
              ? _buildMapView()
              : _buildStatusView(currentStatus),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(12.9716, 77.5946), // Initial map center
        zoom: 15,
      ),
      onMapCreated: (controller) => _mapController = controller,
      markers: _markers,
    );
  }

  Widget _buildStatusView(OrderStatus currentStatus) {
    if (currentStatus.title == 'In Transit to Facility') {
      return _buildDriverOnTheWay();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive emoji size based on available height
        final maxEmojiSize = constraints.maxHeight * 0.3; // Max 30% of available height
        final emojiSize = maxEmojiSize > 60 ? 60 : maxEmojiSize;

        return SizedBox.expand(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getEmojiForStatus(currentStatus.title),
                    style: TextStyle(fontSize: emojiSize.toDouble()),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05), // 5% of available height
                  Text(
                    currentStatus.title,
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.03), // 3% of available height
                  Text(
                    currentStatus.subtitle,
                    style: AppTypography.subtitle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverOnTheWay() {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Reduced padding for more space
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delivery_dining,
              size: 80,
              color: AppColors.brandBlue,
            ),
            const SizedBox(height: 24),
            Text(
              'Driver on the way',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your clothes are on the way to our facility.',
              style: AppTypography.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEmojiForStatus(String title) {
    switch (title) {
      case 'Washing':
        return '🌀';
      case 'Quality Check':
        return '✅';
      case 'Delivered':
        return '🎉';
      default:
        return '📦';
    }
  }

  Widget _buildBottomDrawer(OrderStatus currentStatus) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentStatus.title, style: AppTypography.h2),
          const SizedBox(height: 8),
          Text(currentStatus.subtitle, style: AppTypography.subtitle),
          const SizedBox(height: 16),
          _buildActionButtons(currentStatus),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderStatus currentStatus) {
    return Column(
      children: [
        if (['Picked Up', 'In Transit to Facility', 'Out for Delivery']
            .contains(currentStatus.title))
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.bookingButtonGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
              label: const Text('Call Driver', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.bookingButtonGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
              label: const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OrderDetailsScreen(orderId: widget.orderId),
                ),
              );
            },
            child: const Text('View Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
