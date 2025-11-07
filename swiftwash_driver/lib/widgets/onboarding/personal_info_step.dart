import 'package:flutter/material.dart';
import '../../utils/validators.dart';

class PersonalInfoStep extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController dateOfBirthController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController pincodeController;
  final String? selectedGender;
  final VoidCallback selectDateOfBirth;
  final ValueChanged<String?> onGenderChanged;

  const PersonalInfoStep({
    super.key,
    required this.fullNameController,
    required this.dateOfBirthController,
    required this.addressController,
    required this.cityController,
    required this.pincodeController,
    required this.selectedGender,
    required this.selectDateOfBirth,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please provide your personal details to get started.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),

        // Full Name
        TextFormField(
          controller: fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'Full Name'),
        ),
        const SizedBox(height: 16),

        // Date of Birth
        TextFormField(
          controller: dateOfBirthController,
          decoration: InputDecoration(
            labelText: 'Date of Birth *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: selectDateOfBirth,
            ),
          ),
          readOnly: true,
          validator: (value) => Validators.validateNotEmpty(value, 'Date of Birth'),
        ),
        const SizedBox(height: 16),

        // Gender
        DropdownButtonFormField<String>(
          value: selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people),
          ),
          items: ['Male', 'Female', 'Other'].map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: onGenderChanged,
          validator: (value) => Validators.validateNotEmpty(value, 'Gender'),
        ),
        const SizedBox(height: 16),

        // Address
        TextFormField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Address *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home),
          ),
          maxLines: 3,
          validator: (value) => Validators.validateNotEmpty(value, 'Address'),
        ),
        const SizedBox(height: 16),

        // City
        TextFormField(
          controller: cityController,
          decoration: const InputDecoration(
            labelText: 'City *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'City'),
        ),
        const SizedBox(height: 16),

        // Pincode
        TextFormField(
          controller: pincodeController,
          decoration: const InputDecoration(
            labelText: 'Pincode *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_drop),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: Validators.validatePincode,
        ),
      ],
    );
  }
}
