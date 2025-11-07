import 'dart:io';
import 'package:flutter/material.dart';
import 'package:swiftwash_driver/models/driver_profile_model.dart';
import './document_upload_section.dart';
import '../../utils/validators.dart';

class VehicleInfoStep extends StatelessWidget {
  final VehicleType? selectedVehicleType;
  final TextEditingController vehicleModelController;
  final TextEditingController vehicleNumberController;
  final TextEditingController vehicleColorController;
  final File? vehiclePhoto;
  final ValueChanged<VehicleType?> onVehicleTypeChanged;
  final VoidCallback onPickVehiclePhoto;

  const VehicleInfoStep({
    super.key,
    required this.selectedVehicleType,
    required this.vehicleModelController,
    required this.vehicleNumberController,
    required this.vehicleColorController,
    required this.vehiclePhoto,
    required this.onVehicleTypeChanged,
    required this.onPickVehiclePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Provide details about your vehicle.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),

        // Vehicle Type
        DropdownButtonFormField<VehicleType>(
          value: selectedVehicleType,
          decoration: const InputDecoration(
            labelText: 'Vehicle Type *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_car),
          ),
          items: VehicleType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: onVehicleTypeChanged,
          validator: (value) => Validators.validateNotEmpty(value?.displayName, 'Vehicle Type'),
        ),
        const SizedBox(height: 16),

        // Vehicle Model
        TextFormField(
          controller: vehicleModelController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Model *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.build),
            hintText: 'e.g., Honda Activa, Hero Splendor',
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'Vehicle Model'),
        ),
        const SizedBox(height: 16),

        // Vehicle Number
        TextFormField(
          controller: vehicleNumberController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Number *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.tag),
            hintText: 'e.g., MH 12 AB 1234',
          ),
          validator: Validators.validateVehicleNumber,
        ),
        const SizedBox(height: 16),

        // Vehicle Color
        TextFormField(
          controller: vehicleColorController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Color *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.color_lens),
            hintText: 'e.g., Black, White, Red',
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'Vehicle Color'),
        ),
        const SizedBox(height: 24),

        // Vehicle Photo
        DocumentUploadSection(
          title: 'Vehicle Photo',
          subtitle: 'Upload a photo of your vehicle',
          file: vehiclePhoto,
          onTap: onPickVehiclePhoto,
          icon: Icons.camera_alt,
        ),
      ],
    );
  }
}
