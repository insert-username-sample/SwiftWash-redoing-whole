import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/services/enhanced_tracking_service.dart';
import 'package:swiftwash_mobile/screens/home_screen.dart';

class EnhancedTrackingScreen extends StatefulWidget {
  final String orderId;

  const EnhancedTrackingScreen({super.key, required this.orderId});

  @override
  _EnhancedTrackingScreenState createState() => _EnhancedTrackingScreenState();
}

class _EnhancedTrackingScreenState extends State<EnhancedTrackingScreen> {
  final EnhancedTrackingService _trackingService = EnhancedTrackingService();
  GoogleMapController? _mapController;
  StreamSubscription<TrackingData>? _trackingSubscription;

  TrackingData? _currentTrackingData;
  bool _isLoading = true;
  String? _error;

  // Map configuration
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      await _trackingService.initialize();
      _startTracking();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize tracking: $e';
        _isLoading = false;
      });
    }
  }

  void _startTracking() {
    _trackingSubscription = _trackingService.getOrderTracking(widget.orderId).listen(
      (trackingData) {
        setState(() {
          _currentTrackingData = trackingData;
          _isLoading = false;
        });
        _updateCameraPosition(trackingData.driverLocation);
      },
      onError: (error) {
        setState(() {
          _error = 'Tracking error: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _updateCameraPosition(LatLng location) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(location),
      );
    }
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _trackingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text('Track Order'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildOrderInfoCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _currentTrackingData != null
                        ? _buildTrackingMap()
                        : const Center(child: Text('No tracking data available')),
          ),
          _buildTrackingInfoCard(),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.trackingCardBorderGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 60);
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>?;
          if (orderData == null) {
            return const SizedBox(height: 60);
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID', style: AppTypography.cardSubtitle),
                      Text(
                        orderData['orderId'] ?? widget.orderId,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: 8),
                      Text('Status', style: AppTypography.cardSubtitle),
                      Text(
                        _currentTrackingData?.status ?? 'Loading...',
                        style: AppTypography.cardTitle,
                      ),
                    ],
                  ),
                ),
                if (_currentTrackingData != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Distance', style: AppTypography.cardSubtitle),
                        Text(
                          '${_currentTrackingData!.distance.toStringAsFixed(1)} km',
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: 8),
                        Text('ETA', style: AppTypography.cardSubtitle),
                        Text(
                          _currentTrackingData!.estimatedArrival,
                          style: AppTypography.cardTitle,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackingMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: _initialPosition,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: _currentTrackingData?.getMarkers() ?? {},
          polylines: _currentTrackingData?.getPolyline() ?? {},
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildTrackingInfoCard() {
    if (_currentTrackingData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Information',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 12),
          _buildTrackingDetail(
            'Current Phase',
            _getPhaseDescription(_currentTrackingData!.phase),
            _getPhaseIcon(_currentTrackingData!.phase),
          ),
          const SizedBox(height: 8),
          _buildTrackingDetail(
            'Distance Remaining',
            '${_currentTrackingData!.distance.toStringAsFixed(1)} km',
            Icons.straighten,
          ),
          const SizedBox(height: 8),
          _buildTrackingDetail(
            'Estimated Arrival',
            _currentTrackingData!.estimatedArrival,
            Icons.access_time,
          ),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTrackingDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brandBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.cardSubtitle),
              Text(value, style: AppTypography.cardTitle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Call driver functionality
            },
            icon: const Icon(Icons.phone, color: Colors.white),
            label: const Text('Call Driver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // View order details
            },
            icon: const Icon(Icons.info_outline),
            label: const Text('Order Details'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Tracking Error',
            style: AppTypography.h2,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: AppTypography.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _startTracking();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getPhaseDescription(TrackingPhase phase) {
    switch (phase) {
      case TrackingPhase.pickup:
        return 'Driver en route to pickup location';
      case TrackingPhase.toFacility:
        return 'Driver en route to facility';
      case TrackingPhase.toDelivery:
        return 'Driver en route for delivery';
      case TrackingPhase.completed:
        return 'Delivery completed';
    }
  }

  IconData _getPhaseIcon(TrackingPhase phase) {
    switch (phase) {
      case TrackingPhase.pickup:
        return Icons.local_shipping;
      case TrackingPhase.toFacility:
        return Icons.business;
      case TrackingPhase.toDelivery:
        return Icons.delivery_dining;
      case TrackingPhase.completed:
        return Icons.check_circle;
    }
  }
}
