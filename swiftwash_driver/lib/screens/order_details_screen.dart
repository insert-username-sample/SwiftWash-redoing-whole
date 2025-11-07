import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final Location _location = Location();
  LatLng? _driverLocation;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
  }

  void _initializeLocationTracking() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted && currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _driverLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });

        // Update driver location in Firebase
        if (FirebaseAuth.instance.currentUser != null) {
          FirebaseFirestore.instance.collection('drivers')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .set({
                'currentLocation': GeoPoint(currentLocation.latitude!, currentLocation.longitude!),
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
    });

    setState(() => _isTracking = true);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  // Helper function to format status text
  String _formatStatusText(String status) {
    return status.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Get context-aware action buttons based on current status
  List<Widget> _getActionButtons(String currentStatus, String orderId) {
    // Pickup Phase
    if (currentStatus == 'out_for_pickup') {
      return [
        _buildActionButton('Reached Customer Location', 'reached_pickup_location', orderId),
      ];
    }
    if (currentStatus == 'reached_pickup_location') {
      return [
        _buildActionButton('Picked Up', 'picked_up', orderId),
      ];
    }
    if (currentStatus == 'picked_up') {
      return [
        _buildActionButton('Start Transit to Facility', 'transit_to_facility', orderId),
      ];
    }
    if (currentStatus == 'transit_to_facility') {
      return [
        _buildActionButton('Reached Facility', 'reached_facility', orderId),
      ];
    }

    // Delivery Phase
    if (currentStatus == 'out_for_delivery') {
      return [
        _buildActionButton('Reached Customer Location', 'reached_delivery_location', orderId),
      ];
    }
    if (currentStatus == 'reached_delivery_location') {
      return [
        _buildActionButton('Delivered', 'delivered', orderId),
      ];
    }

    return [];
  }

  Widget _buildActionButton(String label, String status, String orderId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _updateOrderStatus(orderId, status),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': status,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'driverId': FirebaseAuth.instance.currentUser!.uid,
      });

      // Add to status history
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('statusHistory')
          .add({
            'status': status,
            'timestamp': FieldValue.serverTimestamp(),
            'updatedBy': FirebaseAuth.instance.currentUser!.uid,
            'location': _driverLocation != null
                ? GeoPoint(_driverLocation!.latitude, _driverLocation!.longitude)
                : null,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${_formatStatusText(status)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Order Details'),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: () {
              setState(() => _isTracking = !_isTracking);
              if (_isTracking) {
                _initializeLocationTracking();
              } else {
                _locationSubscription?.cancel();
              }
            },
            color: _isTracking ? Colors.green : Colors.grey,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final currentStatus = orderData['status'] ?? 'unknown';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${widget.orderId}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(currentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(currentStatus).withOpacity(0.3)),
                          ),
                          child: Text(
                            _formatStatusText(currentStatus),
                            style: TextStyle(
                              color: _getStatusColor(currentStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Details Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (orderData['customerName'] != null)
                          Text('Name: ${orderData['customerName']}'),
                        if (orderData['customerPhone'] != null)
                          Text('Phone: ${orderData['customerPhone']}'),
                        if (orderData['totalAmount'] != null)
                          Text('Amount: ₹${orderData['totalAmount']}'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Address Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup/Delivery Address',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(orderData['address']?['fullAddress'] ?? 'Address not available'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // GPS Location Display
                if (_driverLocation != null)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'GPS Tracking Active',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Lat: ${_driverLocation!.latitude.toStringAsFixed(6)}'),
                          Text('Lng: ${_driverLocation!.longitude.toStringAsFixed(6)}'),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Action Buttons
                ..._getActionButtons(currentStatus, widget.orderId),

                const SizedBox(height: 24),

                // Call Support Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Implement call support functionality
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'confirmed':
        return Colors.blue;
      case 'out_for_pickup':
      case 'picked_up':
      case 'out_for_delivery':
        return Colors.orange;
      case 'transit_to_facility':
      case 'reached_facility':
        return Colors.brown;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
