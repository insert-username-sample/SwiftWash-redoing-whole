import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/screens/coming_soon_screen.dart';
import 'package:intl/intl.dart';



class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {

  @override
  void initState() {
    super.initState();
    // No need for _getAddress() as addresses will be fetched from order data
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 30),
          onPressed: () async {
            // Navigate back properly to orders screen or home screen
            try {
              // First try to pop normally (go back to orders screen)
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If can't pop, navigate to home screen (restart app navigation)
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            } catch (e) {
              // Fallback: Restart app navigation if any error occurs
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            }
          },
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.circleQuestion, color: Colors.black87, size: 24),
            onPressed: () {
              // Handle help action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildOrderSummaryCard(),
              const SizedBox(height: 16),
              _buildOrderItemsCard(),
              const SizedBox(height: 16),
              _buildScheduleCard(),
              const SizedBox(height: 16),
              _buildAddressCard(),
              const SizedBox(height: 16),
              _buildStatusTrackerCard(),
              const SizedBox(height: 16),
              _buildPriceBreakdownCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order ID',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Delivered',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.orderId,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dec 15, 2024 • 10:30 AM',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  children: const [
                    Icon(FontAwesomeIcons.bolt, color: Colors.orange, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Swift',
                      style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        var orderData = snapshot.data!.data() as Map<String, dynamic>;
        var items = (orderData['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items in this Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (items.isNotEmpty)
                ...items.where((item) => item['quantity'] > 0).map((item) {
                  return _buildItemRow(
                    '👕', // You can replace this with a dynamic icon later
                    item['name'],
                    '${item['quantity']} × ₹${item['price']} = ₹${item['quantity'] * item['price']}',
                  );
                }).toList()
              else
                const Text('No items found in this order.'),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                  Text('₹${orderData['itemTotal']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemRow(String emoji, String name, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Text(name),
            ],
          ),
          Text(price, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(FontAwesomeIcons.clock, color: Colors.teal, size: 16),
                    SizedBox(width: 8),
                    Text('Pickup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Today', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Text('10–12 PM', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(FontAwesomeIcons.truck, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Tomorrow', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Text('2–4 PM', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        var orderData = snapshot.data!.data() as Map<String, dynamic>;
        var address = orderData['address'] as Map<String, dynamic>?;

        if (address == null || address.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Address information not available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup & Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(FontAwesomeIcons.mapMarkerAlt, color: Colors.red, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${address['fullName'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address['phoneNumber'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address['flatHouseNo'] ?? ''}, ${address['street'] ?? ''}'.trim(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (address['landmark'] != null && address['landmark'].toString().isNotEmpty)
                          Text(
                            'Near: ${address['landmark']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        Text(
                          'PIN: ${address['pincode'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTrackerCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        var orderData = snapshot.data!.data() as Map<String, dynamic>;
        var statusHistory = (orderData['statusHistory'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDynamicStatusTracker(statusHistory),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicStatusTracker(List<Map<String, dynamic>> statusHistory) {
    // Get current status and processing status
    final currentStatus = _getCurrentOrderStatus(statusHistory);
    final processingStatus = _getCurrentProcessingStatus(statusHistory);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Main Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(currentStatus['title'] as String),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStatus['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentStatus['subtitle'] != null)
                    Text(
                      currentStatus['subtitle'] as String,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Processing Sub-statuses (if applicable)
          if (processingStatus != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Currently Processing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getProcessingIcon(processingStatus['status'] as String),
                        color: Colors.yellowAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        processingStatus['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getCurrentOrderStatus(List<Map<String, dynamic>> statusHistory) {
    if (statusHistory.isEmpty) {
      return {
        'title': 'Order Placed',
        'subtitle': 'Preparing to process your order',
        'status': 'new'
      };
    }

    // Find the latest completed status
    final completedStatuses = statusHistory.where((s) => s['timestamp'] != null).toList()
      ..sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    if (completedStatuses.isEmpty) {
      return {
        'title': 'Order Confirmed',
        'subtitle': 'Your order has been confirmed',
        'status': 'confirmed'
      };
    }

    final latestStatus = completedStatuses.first['status'] as String;

    // Map status to display information
    switch (latestStatus) {
      case 'new':
        return {
          'title': 'Order Placed',
          'subtitle': 'Your order has been received',
          'status': 'new'
        };
      case 'confirmed':
        return {
          'title': 'Order Confirmed',
          'subtitle': 'Your order has been confirmed',
          'status': 'confirmed'
        };
      case 'driver_assigned':
        return {
          'title': 'Driver Assigned',
          'subtitle': 'Driver is on their way to pick up',
          'status': 'driver_assigned'
        };
      case 'out_for_pickup':
        return {
          'title': 'Pickup in Progress',
          'subtitle': 'Driver is heading to your location',
          'status': 'out_for_pickup'
        };
      case 'picked_up':
        return {
          'title': 'Items Collected',
          'subtitle': 'Your items have been picked up',
          'status': 'picked_up'
        };
      case 'transit_to_facility':
        return {
          'title': 'In Transit',
          'subtitle': 'Items are on the way to our facility',
          'status': 'transit_to_facility'
        };
      case 'reached_facility':
        return {
          'title': 'Processing Started',
          'subtitle': 'Your items are now at our facility',
          'status': 'reached_facility'
        };
      case 'ready_for_delivery':
        return {
          'title': 'Ready for Delivery',
          'subtitle': 'Your cleaned items are ready',
          'status': 'ready_for_delivery'
        };
      case 'out_for_delivery':
        return {
          'title': 'Out for Delivery',
          'subtitle': 'Your order is on the way back',
          'status': 'out_for_delivery'
        };
      case 'delivered':
        return {
          'title': 'Delivered',
          'subtitle': 'Your order has been delivered successfully',
          'status': 'delivered'
        };
      default:
        return {
          'title': 'Processing',
          'subtitle': 'Your order is being processed',
          'status': 'processing'
        };
    }
  }

  Map<String, dynamic>? _getCurrentProcessingStatus(List<Map<String, dynamic>> statusHistory) {
    // Check for active processing statuses
    final processingStatuses = [
      {'status': 'sorting', 'title': 'Items Sorted', 'icon': FontAwesomeIcons.sort},
      {'status': 'washing', 'title': 'Washing Clothes', 'icon': FontAwesomeIcons.water},
      {'status': 'cleaning', 'title': 'Cleaning Items', 'icon': FontAwesomeIcons.soap},
      {'status': 'ironing', 'title': 'Ironing Clothes', 'icon': FontAwesomeIcons.shirt},
      {'status': 'drying', 'title': 'Drying Clothes', 'icon': FontAwesomeIcons.wind},
      {'status': 'quality_check', 'title': 'Quality Check', 'icon': FontAwesomeIcons.magnifyingGlass},
    ];

    for (var processing in processingStatuses) {
      if (statusHistory.any((s) =>
          (s['status'] as String?)?.toLowerCase() == processing['status'] &&
          s['timestamp'] != null
      )) {
        return processing;
      }
    }

    return null; // No active processing status
  }

  IconData _getStatusIcon(String title) {
    switch (title) {
      case 'Order Placed':
        return FontAwesomeIcons.receipt;
      case 'Order Confirmed':
        return FontAwesomeIcons.checkCircle;
      case 'Driver Assigned':
        return FontAwesomeIcons.userTie;
      case 'Pickup in Progress':
        return FontAwesomeIcons.walking;
      case 'Items Collected':
        return FontAwesomeIcons.handHolding;
      case 'In Transit':
        return FontAwesomeIcons.truckMoving;
      case 'Processing Started':
        return FontAwesomeIcons.cog;
      case 'Ready for Delivery':
        return FontAwesomeIcons.checkDouble;
      case 'Out for Delivery':
        return FontAwesomeIcons.shippingFast;
      case 'Delivered':
        return FontAwesomeIcons.checkToSlot;
      default:
        return FontAwesomeIcons.infoCircle;
    }
  }

  IconData _getProcessingIcon(String status) {
    switch (status) {
      case 'sorting':
        return FontAwesomeIcons.sort;
      case 'washing':
        return FontAwesomeIcons.water;
      case 'cleaning':
        return FontAwesomeIcons.soap;
      case 'ironing':
        return FontAwesomeIcons.shirt;
      case 'drying':
        return FontAwesomeIcons.wind;
      case 'quality_check':
        return FontAwesomeIcons.magnifyingGlass;
      default:
        return FontAwesomeIcons.cog;
    }
  }


  Widget _buildPriceBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Item Total', '₹218'),
          _buildPriceRow('Swift Express Charge', '₹50'),
          _buildPriceRow('First Time Discount', '-₹20', color: Colors.green),
          _buildPriceRow('Taxes & Fees', '₹37'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Final Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('₹285', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String title, String price, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: color)),
          Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const CircularProgressIndicator();
        }

        var orderData = snapshot.data!.data() as Map<String, dynamic>;
        var orderStatus = orderData['status']?.toLowerCase() ?? 'new';
        bool isCancelled = orderStatus == 'cancelled';

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComingSoonScreen(),
                    ),
                  );
                },
                icon: const Icon(FontAwesomeIcons.phone, size: 16),
                label: const Text('Call Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!isCancelled) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Order'),
                            content: const Text('Are you sure you want to cancel this order?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Cancel the order
                                  await FirebaseFirestore.instance
                                      .collection('orders')
                                      .doc(widget.orderId)
                                      .update({'status': 'Cancelled'});

                                  // Close the dialog first
                                  Navigator.of(context).pop();

                                  // Safely navigate back to orders list with a slight delay
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  });
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // You need to fetch the order items and service name
                        // and pass them to the OrderProcessScreen
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show only Reorder button when cancelled
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // You need to fetch the order items and service name
                    // and pass them to the OrderProcessScreen
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reorder', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }


}
