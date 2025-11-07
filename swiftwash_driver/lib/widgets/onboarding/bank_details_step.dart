import 'package:flutter/material.dart';
import '../../utils/validators.dart';

class BankDetailsStep extends StatelessWidget {
  final TextEditingController bankNameController;
  final TextEditingController accountNumberController;
  final TextEditingController ifscCodeController;
  final TextEditingController accountHolderNameController;

  const BankDetailsStep({
    super.key,
    required this.bankNameController,
    required this.accountNumberController,
    required this.ifscCodeController,
    required this.accountHolderNameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Account Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your earnings will be transferred to this account.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),

        // Bank Name
        TextFormField(
          controller: bankNameController,
          decoration: const InputDecoration(
            labelText: 'Bank Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance),
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'Bank Name'),
        ),
        const SizedBox(height: 16),

        // Account Holder Name
        TextFormField(
          controller: accountHolderNameController,
          decoration: const InputDecoration(
            labelText: 'Account Holder Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => Validators.validateNotEmpty(value, 'Account Holder Name'),
        ),
        const SizedBox(height: 16),

        // Account Number
        TextFormField(
          controller: accountNumberController,
          decoration: const InputDecoration(
            labelText: 'Account Number *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_box),
          ),
          keyboardType: TextInputType.number,
          validator: Validators.validateBankAccountNumber,
        ),
        const SizedBox(height: 16),

        // IFSC Code
        TextFormField(
          controller: ifscCodeController,
          decoration: const InputDecoration(
            labelText: 'IFSC Code *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.code),
            hintText: 'e.g., HDFC0001234',
          ),
          validator: Validators.validateIfscCode,
        ),
      ],
    );
  }
}
