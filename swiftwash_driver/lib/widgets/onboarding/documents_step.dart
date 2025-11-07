import 'dart:io';
import 'package:flutter/material.dart';
import './document_upload_section.dart';
import '../../utils/validators.dart';

class DocumentsStep extends StatelessWidget {
  final File? profilePhoto;
  final File? idProof;
  final File? drivingLicense;
  final String? idProofType;
  final TextEditingController idProofNumberController;
  final TextEditingController drivingLicenseNumberController;
  final DateTime? drivingLicenseExpiry;
  final VoidCallback onPickProfilePhoto;
  final VoidCallback onPickIdProof;
  final VoidCallback onPickDrivingLicense;
  final ValueChanged<String?> onIdProofTypeChanged;
  final VoidCallback selectLicenseExpiry;

  const DocumentsStep({
    super.key,
    required this.profilePhoto,
    required this.idProof,
    required this.drivingLicense,
    required this.idProofType,
    required this.idProofNumberController,
    required this.drivingLicenseNumberController,
    required this.drivingLicenseExpiry,
    required this.onPickProfilePhoto,
    required this.onPickIdProof,
    required this.onPickDrivingLicense,
    required this.onIdProofTypeChanged,
    required this.selectLicenseExpiry,
  });

  String? _validateIdProofNumber(String? value) {
    if (idProofType == null) {
      return 'Please select an ID proof type.';
    }
    switch (idProofType) {
      case 'Aadhar Card':
        return Validators.validateAadhar(value);
      case 'PAN Card':
        return Validators.validatePan(value);
      case 'Driving License':
        return Validators.validateDrivingLicense(value);
      default:
        return Validators.validateNotEmpty(value, 'ID Proof Number');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Verification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your documents for verification.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),

        // Profile Photo
        DocumentUploadSection(
          title: 'Profile Photo',
          subtitle: 'Upload a clear photo of yourself',
          file: profilePhoto,
          onTap: onPickProfilePhoto,
          icon: Icons.camera_alt,
        ),
        const SizedBox(height: 24),

        // ID Proof
        DocumentUploadSection(
          title: 'ID Proof',
          subtitle: 'Aadhar Card, PAN Card, or Passport',
          file: idProof,
          onTap: onPickIdProof,
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 16),

        // ID Proof Type
        DropdownButtonFormField<String>(
          value: idProofType,
          decoration: const InputDecoration(
            labelText: 'ID Proof Type',
            border: OutlineInputBorder(),
          ),
          items: ['Aadhar Card', 'PAN Card', 'Passport', 'Driving License'].map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: onIdProofTypeChanged,
          validator: (value) => Validators.validateNotEmpty(value, 'ID Proof Type'),
        ),
        const SizedBox(height: 16),

        // ID Proof Number
        TextFormField(
          controller: idProofNumberController,
          decoration: const InputDecoration(
            labelText: 'ID Proof Number',
            border: OutlineInputBorder(),
          ),
          validator: _validateIdProofNumber,
        ),
        const SizedBox(height: 24),

        // Driving License
        DocumentUploadSection(
          title: 'Driving License',
          subtitle: 'Upload front side of your driving license',
          file: drivingLicense,
          onTap: onPickDrivingLicense,
          icon: Icons.drive_eta,
        ),
        const SizedBox(height: 16),

        // Driving License Number
        TextFormField(
          controller: drivingLicenseNumberController,
          decoration: const InputDecoration(
            labelText: 'Driving License Number',
            border: OutlineInputBorder(),
          ),
          validator: Validators.validateDrivingLicense,
        ),
        const SizedBox(height: 16),

        // Driving License Expiry
        TextFormField(
          controller: TextEditingController(
            text: drivingLicenseExpiry != null
                ? '${drivingLicenseExpiry!.day}/${drivingLicenseExpiry!.month}/${drivingLicenseExpiry!.year}'
                : '',
          ),
          decoration: InputDecoration(
            labelText: 'License Expiry Date',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: selectLicenseExpiry,
            ),
          ),
          readOnly: true,
          validator: (value) => Validators.validateNotEmpty(value, 'License Expiry Date'),
        ),
      ],
    );
  }
}
