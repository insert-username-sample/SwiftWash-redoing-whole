import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'set_pickup_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  _SavedAddressesScreenState createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatHouseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _otherAddressTypeController = TextEditingController();

  bool _isAddingNew = false;
  Map<String, dynamic>? _editingAddress;
  String? _loginProvider;

  // Map related variables
  String _addressType = 'Home';
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(21.1458, 79.0882); // Default to Nagpur
  final Set<Marker> _markers = {};
  Location _location = Location();
  double? _latitude;
  double? _longitude;

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Pre-fill user details if available
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _fullNameController.text = currentUser.displayName ?? '';
      _phoneController.text = currentUser.phoneNumber ?? '';
    }
    _getCurrentLocation();
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
      print("Error getting location: $e");
    }
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Detect login provider
      String provider = 'phone';
      if (user.providerData.isNotEmpty) {
        if (user.providerData.any((providerData) => providerData.providerId == 'google.com')) {
          provider = 'google';
        } else if (user.providerData.any((providerData) => providerData.providerId == 'apple.com')) {
          provider = 'apple';
        } else if (user.providerData.any((providerData) => providerData.providerId == 'password')) {
          provider = 'email';
        } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          provider = 'phone';
        }
      }

      setState(() {
        _loginProvider = provider;
      });
    }
  }

  void _onAddNewAddress() {
    // Navigate to SetPickupAddressScreen first, just like Step3 widget does
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetPickupAddressScreen(),
      ),
    ).then((result) {
      // After returning from SetPickupAddressScreen,
      // switch to address form if location was selected
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _isAddingNew = true;
          // Pre-populate form with returned data
          if (result['latitude'] != null && result['longitude'] != null) {
            _latitude = result['latitude'];
            _longitude = result['longitude'];
            _initialPosition = LatLng(_latitude!, _longitude!);
            _markers.clear();
            _markers.add(
              Marker(
                markerId: const MarkerId('selectedLocation'),
                position: _initialPosition,
                infoWindow: const InfoWindow(title: 'Selected Location'),
              ),
            );
            _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
          }
          if (result['street'] != null) {
            _streetController.text = result['street'];
          }
          if (result['pincode'] != null) {
            _pincodeController.text = result['pincode'];
          }
        });
      }
    });
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

        Map<String, dynamic> addressData = {
          'userId': user.uid,
          'fullName': _fullNameController.text,
          'phoneNumber': _phoneController.text,
          'flatHouseNo': _flatHouseController.text, // B-301 & Building
          'street': _streetController.text,
          'landmark': _landmarkController.text,
          'pincode': _pincodeController.text,
          'addressType': finalAddressType,
          'latitude': _latitude,
          'longitude': _longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_editingAddress != null && _editingAddress!['id'] != null) {
          // Update existing address
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .doc(_editingAddress!['id'])
              .update(addressData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address updated successfully')),
          );
        } else {
          // Add new address
          addressData['createdAt'] = FieldValue.serverTimestamp();
          final docRef = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .add(addressData);
          print('New address added with ID: ${docRef.id}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address added successfully')),
          );
        }

        _resetForm();
        setState(() {});
      } catch (e) {
        print('Error saving address: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    }
  }

  void _resetForm() {
    _fullNameController.clear();
    _phoneController.clear();
    _flatHouseController.clear();
    _streetController.clear();
    _landmarkController.clear();
    _pincodeController.clear();
    _addressType = 'Home';
    _otherAddressTypeController.clear();
    _isAddingNew = false;
    _editingAddress = null;
    _latitude = null;
    _longitude = null;
    _markers.clear();
  }

  void _populateForm(Map<String, dynamic> address) {
    _fullNameController.text = address['fullName'] ?? '';
    _phoneController.text = address['phoneNumber'] ?? '';
    _flatHouseController.text = address['flatHouseNo'] ?? '';
    _streetController.text = address['street'] ?? '';
    _landmarkController.text = address['landmark'] ?? '';
    _pincodeController.text = address['pincode'] ?? '';
    _addressType = address['addressType'] ?? 'Home';

    // Pre-load location if available
    if (address['latitude'] != null && address['longitude'] != null) {
      _latitude = address['latitude'];
      _longitude = address['longitude'];
      _initialPosition = LatLng(_latitude!, _longitude!);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _initialPosition,
          infoWindow: const InfoWindow(title: 'Address Location'),
        ),
      );
      _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
    }
  }

  void _editAddress(Map<String, dynamic> address) {
    setState(() {
      _isAddingNew = true;
      _editingAddress = address;
      _populateForm(address);
    });
  }

  Future<void> _deleteAddress(String addressId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address deleted successfully')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting address: $e')),
      );
    }
  }

  String _getAddressLabel(Map<String, dynamic> address) {
    String label = '';
    if (address['flatHouseNo'] != null && address['flatHouseNo'].isNotEmpty) {
      label += '${address['flatHouseNo']}, ';
    }
    if (address['street'] != null && address['street'].isNotEmpty) {
      label += '${address['street']}, ';
    }
    if (address['landmark'] != null && address['landmark'].isNotEmpty) {
      label += '${address['landmark']}, ';
    }
    if (address['pincode'] != null && address['pincode'].isNotEmpty) {
      label += '${address['pincode']}';
    }
    return label.isEmpty ? 'Address' : label;
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to continue')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isAddingNew)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _onAddNewAddress(),
            ),
        ],
      ),
      body: !_isAddingNew
          ? _buildAddressesList(user.uid)
          : _buildAddressForm(),
    );
  }

  Widget _buildAddressesList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final addresses = snapshot.data?.docs ?? [];
        print('🔍 DEBUG: SavedAddresses Query Results:');
        print('  - User ID: $userId');
        print('  - Found ${addresses.length} addresses');

        if (addresses.isNotEmpty) {
          print('  - Sample address data:');
          print('    ${addresses.first.data()}');
        }

        if (addresses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.grey.shade400,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved addresses',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isAddingNew = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF04D6F7),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Address'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final doc = addresses[index];
            final address = doc.data() as Map<String, dynamic>;
            address['id'] = doc.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        address['addressType'] == 'Work' ? Icons.work :
                        address['addressType'] == 'Other' ? Icons.location_pin :
                        Icons.home,
                        color: const Color(0xFF04D6F7),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address['addressType'] ?? 'Address',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _getAddressLabel(address),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editAddress(address),
                        color: const Color(0xFF04D6F7),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteDialog(address['id']),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact: ${address['fullName']} • ${address['phoneNumber']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddressForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Location on Map',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _flatHouseController,
                    label: 'Flat/House No. & Building',
                    icon: Icons.home,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _streetController,
                    label: 'Street / Locality',
                    icon: Icons.location_city,
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _landmarkController,
                    label: 'Landmark (Optional)',
                    icon: Icons.location_on,
                    required: false,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    icon: Icons.pin_drop,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
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
                        child: Text(
                          _editingAddress != null ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _resetForm(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showDeleteDialog(String addressId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAddress(addressId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
