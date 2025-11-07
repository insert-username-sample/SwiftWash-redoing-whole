import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftwash_driver/models/driver_profile_model.dart';
import 'package:swiftwash_driver/services/driver_service.dart';

class DriverOnboardingProvider extends ChangeNotifier {
  final DriverService _driverService = DriverService();
  final ImagePicker _imagePicker = ImagePicker();

  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<GlobalKey<FormState>> _formKeys = List.generate(5, (index) => GlobalKey<FormState>());
  List<GlobalKey<FormState>> get formKeys => _formKeys;

  // Personal Information
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  String? _selectedGender;
  String? get selectedGender => _selectedGender;

  // Documents
  File? _profilePhoto;
  File? get profilePhoto => _profilePhoto;
  File? _idProof;
  File? get idProof => _idProof;
  File? _drivingLicense;
  File? get drivingLicense => _drivingLicense;
  String? _idProofType;
  String? get idProofType => _idProofType;
  final TextEditingController idProofNumberController = TextEditingController();
  final TextEditingController drivingLicenseNumberController = TextEditingController();
  DateTime? _drivingLicenseExpiry;
  DateTime? get drivingLicenseExpiry => _drivingLicenseExpiry;

  // Vehicle Information
  VehicleType? _selectedVehicleType;
  VehicleType? get selectedVehicleType => _selectedVehicleType;
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController vehicleColorController = TextEditingController();
  File? _vehiclePhoto;
  File? get vehiclePhoto => _vehiclePhoto;

  // Bank Details
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  final TextEditingController accountHolderNameController = TextEditingController();

  // Emergency Contact
  final TextEditingController emergencyContactNameController = TextEditingController();
  final TextEditingController emergencyContactPhoneController = TextEditingController();

  final List<String> _steps = [
    'Personal Info',
    'Documents',
    'Vehicle Info',
    'Bank Details',
    'Emergency Contact',
  ];
  List<String> get steps => _steps;

  void nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      if (_currentStep < _steps.length - 1) {
        _currentStep++;
        notifyListeners();
      }
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void onGenderChanged(String? value) {
    _selectedGender = value;
    notifyListeners();
  }

  void onIdProofTypeChanged(String? value) {
    _idProofType = value;
    notifyListeners();
  }

  void onVehicleTypeChanged(VehicleType? value) {
    _selectedVehicleType = value;
    notifyListeners();
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );

    if (picked != null) {
      dateOfBirthController.text = '${picked.day}/${picked.month}/${picked.year}';
      notifyListeners();
    }
  }

  Future<void> selectLicenseExpiry(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null) {
      _drivingLicenseExpiry = picked;
      notifyListeners();
    }
  }

  Future<void> pickImage(ImageSource source, Function(File) onImagePicked) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        onImagePicked(File(pickedFile.path));
        notifyListeners();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void setProfilePhoto(File file) {
    _profilePhoto = file;
    notifyListeners();
  }

  void setIdProof(File file) {
    _idProof = file;
    notifyListeners();
  }

  void setDrivingLicense(File file) {
    _drivingLicense = file;
    notifyListeners();
  }

  void setVehiclePhoto(File file) {
    _vehiclePhoto = file;
    notifyListeners();
  }

  Future<void> submitApplication(BuildContext context) async {
    bool allFormsValid = true;
    for (final key in _formKeys) {
      if (!(key.currentState?.validate() ?? false)) {
        allFormsValid = false;
      }
    }
    if (!allFormsValid) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create driver profile
      final profile = await _driverService.createDriverProfile(
        phoneNumber: user.phoneNumber ?? '',
        email: user.email,
      );

      // Upload documents
      String? profilePhotoUrl, idProofUrl, drivingLicenseUrl, vehiclePhotoUrl;

      if (_profilePhoto != null) {
        profilePhotoUrl = await _driverService.uploadDocument(_profilePhoto!, 'profile_photo', user.uid);
      }
      if (_idProof != null) {
        idProofUrl = await _driverService.uploadDocument(_idProof!, 'id_proof', user.uid);
      }
      if (_drivingLicense != null) {
        drivingLicenseUrl = await _driverService.uploadDocument(_drivingLicense!, 'driving_license', user.uid);
      }
      if (_vehiclePhoto != null) {
        vehiclePhotoUrl = await _driverService.uploadDocument(_vehiclePhoto!, 'vehicle_photo', user.uid);
      }

      // Update all information
      await _driverService.updatePersonalInfo(
        fullName: fullNameController.text,
        dateOfBirth: dateOfBirthController.text,
        gender: _selectedGender!,
        address: addressController.text,
        city: cityController.text,
        pincode: pincodeController.text,
      );

      await _driverService.updateDocuments(
        profilePhotoUrl: profilePhotoUrl,
        idProofUrl: idProofUrl,
        idProofType: _idProofType,
        idProofNumber: idProofNumberController.text,
        drivingLicenseUrl: drivingLicenseUrl,
        drivingLicenseNumber: drivingLicenseNumberController.text,
        drivingLicenseExpiry: _drivingLicenseExpiry,
      );

      await _driverService.updateVehicleInfo(
        vehicleType: _selectedVehicleType!,
        vehicleModel: vehicleModelController.text,
        vehicleNumber: vehicleNumberController.text,
        vehicleColor: vehicleColorController.text,
        vehiclePhotoUrl: vehiclePhotoUrl,
      );

      await _driverService.updateBankDetails(
        bankName: bankNameController.text,
        accountNumber: accountNumberController.text,
        ifscCode: ifscCodeController.text,
        accountHolderName: accountHolderNameController.text,
      );

      await _driverService.updateEmergencyContact(
        emergencyContactName: emergencyContactNameController.text,
        emergencyContactPhone: emergencyContactPhoneController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully! You will be notified once approved.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      print('Error submitting application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while submitting the application. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
