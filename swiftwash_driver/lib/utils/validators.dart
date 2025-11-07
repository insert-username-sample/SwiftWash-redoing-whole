class Validators {
  static final RegExp _pincodeRegExp = RegExp(r'^[1-9]{1}[0-9]{2}\\s{0,1}[0-9]{3});
  static final RegExp _aadharRegExp = RegExp(r'^[2-9][0-9]{3}(?:[\\s-]?[0-9]{4}){2});
  static final RegExp _panRegExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1});
  static final RegExp _drivingLicenseRegExp = RegExp(r'^(([A-Z]{2}[0-9]{2})( )|([A-Z]{2}-[0-9]{2}))((19|20)[0-9][0-9])[0-9]{7});
  static final RegExp _vehicleNumberRegExp = RegExp(r'^[A-Z]{2}[ -]?[0-9]{2}[ -]?[A-Z]{1,2}[ -]?[0-9]{4});
  static final RegExp _bankAccountNumberRegExp = RegExp(r'^\\d{9,18});
  static final RegExp _ifscCodeRegExp = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6});

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required.';
    }
    if (!_pincodeRegExp.hasMatch(value)) {
      return 'Please enter a valid Indian pincode.';
    }
    return null;
  }

  static String? validateAadhar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required.';
    }
    if (!_aadharRegExp.hasMatch(value)) {
      return 'Please enter a valid Aadhar number.';
    }
    return null;
  }

  static String? validatePan(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required.';
    }
    if (!_panRegExp.hasMatch(value)) {
      return 'Please enter a valid PAN number.';
    }
    return null;
  }

  static String? validateDrivingLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'Driving license number is required.';
    }
    if (!_drivingLicenseRegExp.hasMatch(value)) {
      return 'Please enter a valid driving license number.';
    }
    return null;
  }

  static String? validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required.';
    }
    if (!_vehicleNumberRegExp.hasMatch(value)) {
      return 'Please enter a valid vehicle number.';
    }
    return null;
  }

  static String? validateBankAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bank account number is required.';
    }
    if (!_bankAccountNumberRegExp.hasMatch(value)) {
      return 'Please enter a valid bank account number.';
    }
    return null;
  }

  static String? validateIfscCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'IFSC code is required.';
    }
    if (!_ifscCodeRegExp.hasMatch(value)) {
      return 'Please enter a valid IFSC code.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }
    if (!_phoneRegExp.hasMatch(value)) {
      return 'Please enter a valid 10 digit phone number.';
    }
    return null;
  }
}
