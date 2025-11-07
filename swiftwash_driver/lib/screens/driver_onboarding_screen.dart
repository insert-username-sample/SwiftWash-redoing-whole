import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swiftwash_driver/providers/driver_onboarding_provider.dart';
import 'package:swiftwash_driver/widgets/onboarding/bank_details_step.dart';
import 'package:swiftwash_driver/widgets/onboarding/documents_step.dart';
import 'package:swiftwash_driver/widgets/onboarding/emergency_contact_step.dart';
import 'package:swiftwash_driver/widgets/onboarding/personal_info_step.dart';
import 'package:swiftwash_driver/widgets/onboarding/vehicle_info_step.dart';
import 'package:image_picker/image_picker.dart';

class DriverOnboardingScreen extends StatelessWidget {
  const DriverOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Onboarding',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: Consumer<DriverOnboardingProvider>(
          builder: (context, provider, child) {
            return provider.currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => provider.previousStep(),
                  )
                : null;
          },
        ),
      ),
      body: SafeArea(
        child: Consumer<DriverOnboardingProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                _buildProgressIndicator(context, provider),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildCurrentStep(context, provider),
                  ),
                ),
                _buildBottomButtons(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, DriverOnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(
              provider.steps.length,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index <= provider.currentStep
                        ? const Color(0xFF1E88E5)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.steps[provider.currentStep],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, DriverOnboardingProvider provider) {
    return Form(
      key: provider.formKeys[provider.currentStep],
      child: _buildStepContent(context, provider),
    );
  }

  Widget _buildStepContent(BuildContext context, DriverOnboardingProvider provider) {
    switch (provider.currentStep) {
      case 0:
        return PersonalInfoStep(
          fullNameController: provider.fullNameController,
          dateOfBirthController: provider.dateOfBirthController,
          addressController: provider.addressController,
          cityController: provider.cityController,
          pincodeController: provider.pincodeController,
          selectedGender: provider.selectedGender,
          selectDateOfBirth: () => provider.selectDateOfBirth(context),
          onGenderChanged: (value) => provider.onGenderChanged(value),
        );
      case 1:
        return DocumentsStep(
          profilePhoto: provider.profilePhoto,
          idProof: provider.idProof,
          drivingLicense: provider.drivingLicense,
          idProofType: provider.idProofType,
          idProofNumberController: provider.idProofNumberController,
          drivingLicenseNumberController: provider.drivingLicenseNumberController,
          drivingLicenseExpiry: provider.drivingLicenseExpiry,
          onPickProfilePhoto: () => provider.pickImage(ImageSource.camera, provider.setProfilePhoto),
          onPickIdProof: () => provider.pickImage(ImageSource.gallery, provider.setIdProof),
          onPickDrivingLicense: () => provider.pickImage(ImageSource.gallery, provider.setDrivingLicense),
          onIdProofTypeChanged: (value) => provider.onIdProofTypeChanged(value),
          selectLicenseExpiry: () => provider.selectLicenseExpiry(context),
        );
      case 2:
        return VehicleInfoStep(
          selectedVehicleType: provider.selectedVehicleType,
          vehicleModelController: provider.vehicleModelController,
          vehicleNumberController: provider.vehicleNumberController,
          vehicleColorController: provider.vehicleColorController,
          vehiclePhoto: provider.vehiclePhoto,
          onVehicleTypeChanged: (value) => provider.onVehicleTypeChanged(value),
          onPickVehiclePhoto: () => provider.pickImage(ImageSource.camera, provider.setVehiclePhoto),
        );
      case 3:
        return BankDetailsStep(
          bankNameController: provider.bankNameController,
          accountNumberController: provider.accountNumberController,
          ifscCodeController: provider.ifscCodeController,
          accountHolderNameController: provider.accountHolderNameController,
        );
      case 4:
        return EmergencyContactStep(
          emergencyContactNameController: provider.emergencyContactNameController,
          emergencyContactPhoneController: provider.emergencyContactPhoneController,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomButtons(BuildContext context, DriverOnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (provider.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.previousStep(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (provider.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : (provider.currentStep == provider.steps.length - 1
                      ? () => provider.submitApplication(context)
                      : () => provider.nextStep()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(provider.currentStep == provider.steps.length - 1 ? 'Submit Application' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
