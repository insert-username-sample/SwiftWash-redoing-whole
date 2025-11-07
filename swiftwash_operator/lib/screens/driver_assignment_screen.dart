import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_operator/models/driver_model.dart';
import 'package:swiftwash_operator/models/order_model.dart';
import 'package:swiftwash_operator/providers/order_provider.dart';
import 'package:swiftwash_operator/services/driver_service.dart';

class DriverAssignmentScreen extends StatefulWidget {
  final OrderModel order;

  const DriverAssignmentScreen({
    super.key,
    required this.order,
  });

  @override
  _DriverAssignmentScreenState createState() => _DriverAssignmentScreenState();
}

class _DriverAssignmentScreenState extends State<DriverAssignmentScreen> {
  final DriverService _driverService = DriverService();
  List<DriverModel> _availableDrivers = [];
  bool _isLoading = true;
  String? _error;
  DriverModel? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _loadAvailableDrivers();
  }

  Future<void> _loadAvailableDrivers() async {
    try {
      setState(() => _isLoading = true);

      // Get available drivers stream
      await for (final drivers in _driverService.getAvailableDrivers().take(1)) {
        setState(() {
          _availableDrivers = drivers;
          _isLoading = false;
        });
        break;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Driver'),
        actions: [
          if (_selectedDriver != null)
            TextButton(
              onPressed: _assignDriver,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('ASSIGN'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Order Details Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order: ${widget.order.orderId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Service: ${widget.order.serviceName}'),
                Text('Amount: ₹${widget.order.totalAmount}'),
                Text('Address: ${widget.order.getFormattedAddress()}'),
              ],
            ),
          ),

          // Drivers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            ElevatedButton(
                              onPressed: _loadAvailableDrivers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _availableDrivers.isEmpty
                        ? const Center(
                            child: Text('No available drivers found'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAvailableDrivers,
                            child: ListView.builder(
                              itemCount: _availableDrivers.length,
                              itemBuilder: (context, index) {
                                final driver = _availableDrivers[index];
                                final isSelected = _selectedDriver?.id == driver.id;

                                return DriverCard(
                                  driver: driver,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedDriver = isSelected ? null : driver;
                                    });
                                  },
                                  distance: _calculateDistance(widget.order, driver),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _assignDriver() async {
    if (_selectedDriver == null) return;

    try {
      setState(() => _isLoading = true);

      await context.read<OrderProvider>().assignDriverToOrder(
        widget.order.id,
        _selectedDriver!.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Driver ${_selectedDriver!.name} assigned to order ${widget.order.orderId}',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign driver: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(OrderModel order, DriverModel driver) {
    // This is a simplified calculation - in production, you would use
    // proper geocoding and distance calculation
    if (driver.currentLocation == null || order.location == null) {
      return 0.0;
    }

    // Simplified distance calculation (haversine formula)
    const double earthRadius = 6371.0; // km

    final lat1 = driver.currentLocation!.latitude * (3.141592653589793 / 180.0);
    final lon1 = driver.currentLocation!.longitude * (3.141592653589793 / 180.0);
    final lat2 = order.location!['latitude'] * (3.141592653589793 / 180.0);
    final lon2 = order.location!['longitude'] * (3.141592653589793 / 180.0);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = (dLat * dLat) +
        (dLon * dLon) * (math.cos(lat1) * math.cos(lat2));
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }
}

class DriverCard extends StatelessWidget {
  final DriverModel driver;
  final bool isSelected;
  final VoidCallback onTap;
  final double distance;

  const DriverCard({
    super.key,
    required this.driver,
    required this.isSelected,
    required this.onTap,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Driver Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: driver.isAvailable ? Colors.green.shade100 : Colors.grey.shade100,
                child: Icon(
                  Icons.person,
                  color: driver.isAvailable ? Colors.green : Colors.grey,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              // Driver Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Phone: ${driver.phone}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    if (driver.vehicleType != null)
                      Text(
                        '${driver.vehicleType} (${driver.vehicleNumber ?? 'N/A'})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.green,
                        ),
                        Text(
                          '${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status and Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: driver.status == 'available'
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      driver.getStatusText(),
                      style: TextStyle(
                        color: driver.status == 'available'
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${driver.totalOrders} orders',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
