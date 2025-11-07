import 'package:flutter/material.dart';
import '../../utils/validators.dart';

class EmergencyContactStep extends StatelessWidget {
  final TextEditingController emergencyContactNameController;
  final TextEditingController emergencyContactPhoneController;

  const EmergencyContactStep({
    super.key,
    required this.emergencyContactNameController,
    required this.emergencyContactPhoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Contact',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Provide emergency contact information.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),

        // Emergency Contact Name
        TextFormField(
          controller: emergencyContactNameController,
          decoration: const InputDecoration(
            labelText: 'Emergency Contact Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.contact_phone),
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'Emergency Contact Name'),
        ),
        const SizedBox(height: 16),

        // Emergency Contact Phone
        TextFormField(
          controller: emergencyContactPhoneController,
          decoration: const InputDecoration(
            labelText: 'Emergency Contact Phone *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: Validators.validatePhone,
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📋 Review Your Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please ensure all information is accurate. Once submitted, your application will be reviewed by our team. You will receive a notification once approved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
