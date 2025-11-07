import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:swiftwash_mobile/screens/add_address_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class SetPickupAddressScreen extends StatefulWidget {
  const SetPickupAddressScreen({super.key});

  @override
  _SetPickupAddressScreenState createState() => _SetPickupAddressScreenState();
}

class _SetPickupAddressScreenState extends State<SetPickupAddressScreen> {
  late GoogleMapController _mapController;
  // Use current location or default to Delhi (more central)
  LatLng _currentLatLng = const LatLng(28.6139, 77.2090); // Delhi coordinates
  String _selectedAddress = 'Getting your location...';
  final loc.Location _location = loc.Location();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingLocation = true;
  // IMPORTANT: It is strongly recommended to secure your API key.
  // This key is exposed in the client-side code.
  final String _apiKey = "AIzaSyD4Bk20e5IvgJFx3_-IZT5_w48JXMbMOIs";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        _updateCameraPosition(LatLng(locationData.latitude!, locationData.longitude!));
      }
    } catch (e) {
      // Handle location permission errors or other issues
      print("Error getting location: $e");
    }
  }

  void _updateCameraPosition(LatLng position) {
    setState(() {
      _currentLatLng = position;
    });
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 15.0,
        ),
      ),
    );
    _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        setState(() {
          _selectedAddress = "${p.name}, ${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}, ${p.country}";
          _searchController.text = _selectedAddress;
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        _selectedAddress = "Could not determine address";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Pickup Address'),
      ),
      extendBodyBehindAppBar: false, // Make body respect safe area
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng,
                    zoom: 11.0,
                  ),
                  onCameraIdle: () {
                    _getAddressFromLatLng(_currentLatLng);
                  },
                  onCameraMove: (CameraPosition position) {
                    _currentLatLng = position.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -25),
              child: const Icon(Icons.location_pin, size: 50, color: Colors.red),
            ),
          ),
          Positioned(
            bottom: 320,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'getCurrentLocation',
                  onPressed: _getCurrentLocation,
                  mini: true,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  onPressed: () => _mapController.animateCamera(CameraUpdate.zoomIn()),
                  mini: true,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  onPressed: () => _mapController.animateCamera(CameraUpdate.zoomOut()),
                  mini: true,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: _apiKey,
                inputDecoration: const InputDecoration(
                  hintText: "Search for an address",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                debounceTime: 400,
                countries: const ["IN"],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    _updateCameraPosition(LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!)));
                  }
                },
                itemClick: (Prediction prediction) {
                  _searchController.text = prediction.description ?? "";
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: prediction.description?.length ?? 0),
                  );
                },
              ),
            ),
          ),
                Positioned(
                  bottom: 320,
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'getCurrentLocation',
                        onPressed: _getCurrentLocation,
                        mini: true,
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: 'zoomIn',
                        onPressed: () => _mapController.animateCamera(CameraUpdate.zoomIn()),
                        mini: true,
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: 'zoomOut',
                        onPressed: () => _mapController.animateCamera(CameraUpdate.zoomOut()),
                        mini: true,
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 15,
                  right: 15,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: GooglePlaceAutoCompleteTextField(
                      textEditingController: _searchController,
                      googleAPIKey: _apiKey,
                      inputDecoration: const InputDecoration(
                        hintText: "Search for an address",
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      debounceTime: 400,
                      countries: const ["IN"],
                      isLatLngRequired: true,
                      getPlaceDetailWithLatLng: (Prediction prediction) {
                        if (prediction.lat != null && prediction.lng != null) {
                          _updateCameraPosition(LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!)));
                        }
                      },
                      itemClick: (Prediction prediction) {
                        _searchController.text = prediction.description ?? "";
                        _searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: prediction.description?.length ?? 0),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      spreadRadius: 5,
                      blurRadius: 7,
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Make the column fit its content
                  children: [
                    Text('Selected Location', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(_selectedAddress),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: AppColors.brandBlue),
                          const SizedBox(width: 8),
                          const Text('Drag the map to adjust pin location'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Extract street and pincode from the address string
                        final addressParts = _selectedAddress.split(',');
                        String street = '';
                        String pincode = '';
                        if (addressParts.length > 1) {
                          street = addressParts.sublist(0, addressParts.length - 2).join(',').trim();
                          final lastPart = addressParts[addressParts.length - 2].trim();
                          if (lastPart.contains(' ')) {
                            pincode = lastPart.split(' ').last;
                          }
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAddressScreen(
                              initialStreet: street,
                              initialPincode: pincode,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const SizedBox(
                          height: 60,
                          child: Center(
                            child: Text(
                              'Confirm Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
