import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum DriverStatus {
  pending('Pending Approval', 'Your application is being reviewed'),
  approved('Approved', 'You are approved to work with SwiftWash'),
  rejected('Rejected', 'Your application was not approved'),
  active('Active', 'You are currently available for orders'),
  inactive('Inactive', 'You are currently offline'),
  suspended('Suspended', 'Your account has been temporarily suspended');

  const DriverStatus(this.displayName, this.description);
  final String displayName;
  final String description;
}

enum VehicleType {
  bike('Bike', Icons.motorcycle),
  scooter('Scooter', Icons.electric_scooter),
  car('Car', Icons.directions_car);

  const VehicleType(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

class DriverProfileModel {
  final String id;
  final String userId;
  final String phoneNumber;
  final String? email;
  final DriverStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? lastActiveAt;

  // Personal Information
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? pincode;

  // Documents
  final String? profilePhotoUrl;
  final String? idProofUrl; // Aadhar/PAN/Driving License
  final String? idProofType;
  final String? idProofNumber;
  final String? drivingLicenseUrl;
  final String? drivingLicenseNumber;
  final DateTime? drivingLicenseExpiry;

  // Vehicle Information
  final VehicleType? vehicleType;
  final String? vehicleModel;
  final String? vehicleNumber;
  final String? vehicleColor;
  final String? vehiclePhotoUrl;

  // Bank Details
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;

  // Employment Details
  final String employeeId;
  final double monthlySalary;
  final DateTime? joiningDate;
  final String? department;
  final String? shift; // morning, evening, night

  // Performance Metrics
  final int totalOrders;
  final int completedOrders;
  final double rating;
  final int totalRatings;
  final int attendanceDays; // days present this month
  final int totalWorkingDays; // total working days this month
  final double punctualityScore; // percentage of on-time deliveries
  final int customerComplaints;
  final int positiveFeedback;

  // Current Status
  final bool isOnline;
  final String? currentOrderId;
  final GeoPoint? currentLocation;
  final double? heading;
  final double? speed;

  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const DriverProfileModel({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    this.email,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.lastActiveAt,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.pincode,
    this.profilePhotoUrl,
    this.idProofUrl,
    this.idProofType,
    this.idProofNumber,
    this.drivingLicenseUrl,
    this.drivingLicenseNumber,
    this.drivingLicenseExpiry,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleNumber,
    this.vehicleColor,
    this.vehiclePhotoUrl,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
    this.employeeId = '',
    this.monthlySalary = 0.0,
    this.joiningDate,
    this.department,
    this.shift,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.attendanceDays = 0,
    this.totalWorkingDays = 0,
    this.punctualityScore = 0.0,
    this.customerComplaints = 0,
    this.positiveFeedback = 0,
    this.isOnline = false,
    this.currentOrderId,
    this.currentLocation,
    this.heading,
    this.speed,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory DriverProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DriverProfileModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'],
      status: DriverStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => DriverStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      fullName: data['fullName'],
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      address: data['address'],
      city: data['city'],
      pincode: data['pincode'],
      profilePhotoUrl: data['profilePhotoUrl'],
      idProofUrl: data['idProofUrl'],
      idProofType: data['idProofType'],
      idProofNumber: data['idProofNumber'],
      drivingLicenseUrl: data['drivingLicenseUrl'],
      drivingLicenseNumber: data['drivingLicenseNumber'],
      drivingLicenseExpiry: (data['drivingLicenseExpiry'] as Timestamp?)?.toDate(),
      vehicleType: data['vehicleType'] != null
          ? VehicleType.values.firstWhere((v) => v.name == data['vehicleType'])
          : null,
      vehicleModel: data['vehicleModel'],
      vehicleNumber: data['vehicleNumber'],
      vehicleColor: data['vehicleColor'],
      vehiclePhotoUrl: data['vehiclePhotoUrl'],
      bankName: data['bankName'],
      accountNumber: data['accountNumber'],
      ifscCode: data['ifscCode'],
      accountHolderName: data['accountHolderName'],
      employeeId: data['employeeId'] ?? '',
      monthlySalary: (data['monthlySalary'] ?? 0).toDouble(),
      joiningDate: (data['joiningDate'] as Timestamp?)?.toDate(),
      department: data['department'],
      shift: data['shift'],
      totalOrders: data['totalOrders'] ?? 0,
      completedOrders: data['completedOrders'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      attendanceDays: data['attendanceDays'] ?? 0,
      totalWorkingDays: data['totalWorkingDays'] ?? 0,
      punctualityScore: (data['punctualityScore'] ?? 0).toDouble(),
      customerComplaints: data['customerComplaints'] ?? 0,
      positiveFeedback: data['positiveFeedback'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      currentOrderId: data['currentOrderId'],
      currentLocation: data['currentLocation'] as GeoPoint?,
      heading: data['heading']?.toDouble(),
      speed: data['speed']?.toDouble(),
      emergencyContactName: data['emergencyContactName'],
      emergencyContactPhone: data['emergencyContactPhone'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'email': email,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'city': city,
      'pincode': pincode,
      'profilePhotoUrl': profilePhotoUrl,
      'idProofUrl': idProofUrl,
      'idProofType': idProofType,
      'idProofNumber': idProofNumber,
      'drivingLicenseUrl': drivingLicenseUrl,
      'drivingLicenseNumber': drivingLicenseNumber,
      'drivingLicenseExpiry': drivingLicenseExpiry != null ? Timestamp.fromDate(drivingLicenseExpiry!) : null,
      'vehicleType': vehicleType?.name,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'vehicleColor': vehicleColor,
      'vehiclePhotoUrl': vehiclePhotoUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'employeeId': employeeId,
      'monthlySalary': monthlySalary,
      'joiningDate': joiningDate != null ? Timestamp.fromDate(joiningDate!) : null,
      'department': department,
      'shift': shift,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'rating': rating,
      'totalRatings': totalRatings,
      'attendanceDays': attendanceDays,
      'totalWorkingDays': totalWorkingDays,
      'punctualityScore': punctualityScore,
      'customerComplaints': customerComplaints,
      'positiveFeedback': positiveFeedback,
      'isOnline': isOnline,
      'currentOrderId': currentOrderId,
      'currentLocation': currentLocation,
      'heading': heading,
      'speed': speed,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  // Helper methods
  bool get isProfileComplete {
    return fullName != null &&
           profilePhotoUrl != null &&
           idProofUrl != null &&
           drivingLicenseUrl != null &&
           vehicleType != null &&
           vehicleNumber != null &&
           bankName != null &&
           accountNumber != null &&
           ifscCode != null;
  }

  bool get isDocumentsVerified {
    return status == DriverStatus.approved || status == DriverStatus.active;
  }

  bool get canAcceptOrders {
    return status == DriverStatus.active && isOnline && currentOrderId == null;
  }

  double get completionRate {
    return totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
  }

  double get attendanceRate {
    return totalWorkingDays > 0 ? (attendanceDays / totalWorkingDays) * 100 : 0.0;
  }

  String get formattedMonthlySalary {
    return '₹${monthlySalary.toStringAsFixed(2)}';
  }

  String get employeeDisplayId {
    return employeeId.isNotEmpty ? 'EMP${employeeId}' : 'Not Assigned';
  }

  String get shiftDisplayText {
    if (shift == null) return 'Not Assigned';
    return shift!.toUpperCase();
  }

  String get statusDisplayText {
    return status.displayName;
  }

  String get vehicleDisplayText {
    if (vehicleType == null) return 'Not specified';
    if (vehicleModel != null && vehicleNumber != null) {
      return '${vehicleType!.displayName} - ${vehicleModel!} (${vehicleNumber!})';
    }
    return vehicleType!.displayName;
  }

  // Performance indicators
  String get performanceGrade {
    final avgRating = totalRatings > 0 ? rating / totalRatings : 0.0;
    final attendance = attendanceRate;
    final punctuality = punctualityScore;

    final score = (avgRating * 0.4) + (attendance * 0.3) + (punctuality * 0.3);

    if (score >= 4.5) return 'Excellent';
    if (score >= 4.0) return 'Very Good';
    if (score >= 3.5) return 'Good';
    if (score >= 3.0) return 'Satisfactory';
    return 'Needs Improvement';
  }

  // Create a copy with updated fields
  DriverProfileModel copyWith({
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? pincode,
    String? profilePhotoUrl,
    String? idProofUrl,
    String? idProofType,
    String? idProofNumber,
    String? drivingLicenseUrl,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    VehicleType? vehicleType,
    String? vehicleModel,
    String? vehicleNumber,
    String? vehicleColor,
    String? vehiclePhotoUrl,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? employeeId,
    double? monthlySalary,
    DateTime? joiningDate,
    String? department,
    String? shift,
    DriverStatus? status,
    bool? isOnline,
    String? currentOrderId,
    GeoPoint? currentLocation,
    double? heading,
    double? speed,
    DateTime? lastActiveAt,
  }) {
    return DriverProfileModel(
      id: id,
      userId: userId,
      phoneNumber: phoneNumber,
      email: email,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedAt: approvedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      drivingLicenseUrl: drivingLicenseUrl ?? this.drivingLicenseUrl,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      drivingLicenseExpiry: drivingLicenseExpiry ?? this.drivingLicenseExpiry,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      employeeId: employeeId ?? this.employeeId,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      joiningDate: joiningDate ?? this.joiningDate,
      department: department ?? this.department,
      shift: shift ?? this.shift,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      rating: rating,
      totalRatings: totalRatings,
      attendanceDays: attendanceDays,
      totalWorkingDays: totalWorkingDays,
      punctualityScore: punctualityScore,
      customerComplaints: customerComplaints,
      positiveFeedback: positiveFeedback,
      isOnline: isOnline ?? this.isOnline,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentLocation: currentLocation ?? this.currentLocation,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    );
  }
}
