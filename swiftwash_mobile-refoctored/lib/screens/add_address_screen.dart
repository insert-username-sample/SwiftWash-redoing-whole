import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:swiftwash_mobile/app_theme.dart';

class AddAddressScreen extends StatefulWidget {
  final String initialStreet;
  final String initialPincode;

  const AddAddressScreen({
    super.key,
    this.initialStreet = '',
    this.initialPincode = '',
  });

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatHouseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _otherAddressTypeController = TextEditingController();
  String _addressType = 'Home';
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(21.1458, 79.0882); // Default to Nagpur
  final Set<Marker> _markers = {};
  Location _location = Location();
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _streetController.text = widget.initialStreet;
    _pincodeController.text = widget.initialPincode;
    // Pre-fill user details if available
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _fullNameController.text = currentUser.displayName ?? '';
      _phoneController.text = currentUser.phoneNumber ?? '';
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _flatHouseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _otherAddressTypeController.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    try {
      var locationData = await _location.getLocation();
      setState(() {
        _initialPosition = LatLng(locationData.latitude!, locationData.longitude!);
        _latitude = locationData.latitude;
        _longitude = locationData.longitude;
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _initialPosition,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    } catch (e) {
      // Handle location permission errors or other issues
      print("Error getting location: $e");
    }
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map.')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save an address.')),
        );
        return;
      }

      try {
        final String finalAddressType;
        if (_addressType == 'Other') {
          if (_otherAddressTypeController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please specify the address type.')),
            );
            return;
          }
          finalAddressType = _otherAddressTypeController.text;
        } else {
          finalAddressType = _addressType;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .add({
          'userId': user.uid,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'flatHouseNo': _flatHouseController.text,
          'street': _streetController.text,
          'landmark': _landmarkController.text,
          'pincode': _pincodeController.text,
          'addressType': finalAddressType,
          'latitude': _latitude,
          'longitude': _longitude,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved successfully!')),
        );
        // Pop twice to go back to the screen before the map
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              SizedBox(
                height: 300,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  onTap: (LatLng latLng) {
                    setState(() {
                      _markers.clear();
                      _markers.add(
                        Marker(
                          markerId: const MarkerId('selectedLocation'),
                          position: latLng,
                        ),
                      );
                      _latitude = latLng.latitude;
                      _longitude = latLng.longitude;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _fullNameController, label: 'Full Name', icon: Icons.person),
              const SizedBox(height: 16),
              _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(controller: _flatHouseController, label: 'Flat/House No. & Building', icon: Icons.home),
              const SizedBox(height: 16),
              _buildTextField(controller: _streetController, label: 'Street / Locality', icon: Icons.location_city),
              const SizedBox(height: 16),
              _buildTextField(controller: _landmarkController, label: 'Landmark (Optional)', icon: Icons.location_on, required: false),
              const SizedBox(height: 16),
              _buildTextField(controller: _pincodeController, label: 'Pincode', icon: Icons.pin_drop, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Text('Address Type', style: AppTypography.h2),
              const SizedBox(height: 16),
              _buildAddressTypeSelector(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAddress,
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
                  child: Container(
                    alignment: Alignment.center,
                    height: 60,
                    child: const Text(
                      'Save Address',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  Widget _buildAddressTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildTypeChip('Home', Icons.home)),
            const SizedBox(width: 8),
            Expanded(child: _buildTypeChip('Work', Icons.work)),
            const SizedBox(width: 8),
            Expanded(child: _buildTypeChip('Other', Icons.location_pin)),
          ],
        ),
        if (_addressType == 'Other')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildTextField(
              controller: _otherAddressTypeController,
              label: 'Specify Other',
              icon: Icons.edit_location_alt_outlined,
            ),
          ),
      ],
    );
  }

  Widget _buildTypeChip(String type, IconData icon) {
    final isSelected = _addressType == type;
    return ChoiceChip(
      label: Text(type),
      avatar: Icon(icon, color: isSelected ? Colors.white : Colors.black),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _addressType = type;
          });
        }
      },
      selectedColor: AppColors.brandBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );
  }
}
