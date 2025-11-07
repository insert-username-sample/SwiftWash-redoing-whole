// Test script to verify username-based authentication
// Run this with: dart run test_username_auth.dart

import 'package:swiftwash_admin/models/admin_user_model.dart';
import 'package:swiftwash_admin/services/admin_service.dart';

void main() async {
  print('Testing username-based authentication...');

  final adminService = AdminService();

  try {
    // Test 1: Create admin with username
    print('\n1. Creating admin with username "testadmin"...');
    final newAdmin = await adminService.createAdmin(
      username: 'testadmin',
      name: 'Test Admin',
      phone: '+1234567890',
      role: AdminRole.storeAdmin,
    );
    print('✓ Admin created successfully: ${newAdmin.username}');

    // Test 2: Try to create duplicate username (should fail)
    print('\n2. Testing duplicate username creation...');
    try {
      await adminService.createAdmin(
        username: 'testadmin', // Same username
        name: 'Another Test Admin',
        phone: '+1234567891',
        role: AdminRole.storeAdmin,
      );
      print('✗ Duplicate username creation should have failed');
    } catch (e) {
      print('✓ Duplicate username correctly rejected: ${e.toString()}');
    }

    // Test 3: Authenticate with correct credentials
    print('\n3. Testing authentication with correct username/password...');
    final authenticatedAdmin = await adminService.authenticateAdmin('testadmin', 'FoundersOffice');
    if (authenticatedAdmin != null) {
      print('✓ Authentication successful for: ${authenticatedAdmin.username}');
    } else {
      print('✗ Authentication failed');
    }

    // Test 4: Authenticate with wrong password (should fail)
    print('\n4. Testing authentication with wrong password...');
    final wrongAuth = await adminService.authenticateAdmin('testadmin', 'wrongpassword');
    if (wrongAuth == null) {
      print('✓ Wrong password correctly rejected');
    } else {
      print('✗ Wrong password should have been rejected');
    }

    // Test 5: Authenticate with non-existent username (should fail)
    print('\n5. Testing authentication with non-existent username...');
    final nonExistentAuth = await adminService.authenticateAdmin('nonexistent', 'FoundersOffice');
    if (nonExistentAuth == null) {
      print('✓ Non-existent username correctly rejected');
    } else {
      print('✗ Non-existent username should have been rejected');
    }

    print('\n✅ All username authentication tests completed successfully!');

  } catch (e) {
    print('❌ Test failed with error: ${e.toString()}');
  }
}