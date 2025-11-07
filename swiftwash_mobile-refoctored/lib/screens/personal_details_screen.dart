import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftwash_mobile/screens/phone_verification_test.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  _PersonalDetailsScreenState createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  // Editable user profile data
  String? displayName;
  String? phoneNumber;
  String? email;
  String? gender;
  DateTime? dateOfBirth;
  DateTime? memberSince;
  Map<String, dynamic>? userProfile;
  String? loginProvider;
  bool isPhoneVerified = false;
  bool isEmailVerified = false;

  bool _isEditingName = false;
  bool _isEditingPhone = false;
  bool _isEditingDOB = false;
  bool _isEditingGender = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    // Determine login provider
    String provider = 'phone';
    if (user.providerData.isNotEmpty) {
      if (user.providerData.any((providerData) => providerData.providerId == 'google.com')) {
        provider = 'google';
      } else if (user.providerData.any((providerData) => providerData.providerId == 'apple.com')) {
        provider = 'apple';
      } else if (user.providerData.any((providerData) => providerData.providerId == 'password')) {
        provider = 'email';
      } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        provider = 'phone';
      }
    }

    setState(() {
      displayName = user.displayName ?? 'User';
      email = user.email ?? '';
      phoneNumber = user.phoneNumber ?? '';
      loginProvider = provider;
      isEmailVerified = user.emailVerified;
      isPhoneVerified = user.phoneNumber != null && user.phoneNumber!.isNotEmpty;
    });

    // Initialize controllers
    _nameController.text = user.displayName ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.phoneNumber ?? '';

    // Load additional profile data from Firestore
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Timestamp? dobTimestamp = data['dateOfBirth'] as Timestamp?;
        String? genderValue = data['gender'] as String?;
        String? savedPhone = data['phoneNumber'] as String?;
        bool? phoneVerified = data['phoneVerified'] as bool?;

        setState(() {
          userProfile = data;
          memberSince = (doc.get('memberSince') as Timestamp?)?.toDate();
          dateOfBirth = dobTimestamp?.toDate();
          gender = genderValue;
          phoneNumber = savedPhone ?? user.phoneNumber ?? '';
          isPhoneVerified = phoneVerified ?? (user.phoneNumber != null && user.phoneNumber!.isNotEmpty);
        });

        // Update phone controller if we have data from Firestore
        if (phoneNumber!.isNotEmpty) {
          _phoneController.text = phoneNumber!;
        }
      } else {
        // Create new user profile document if it doesn't exist
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'loginProvider': provider,
          'memberSince': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': user.emailVerified,
          'phoneVerified': false,
          'profileComplete': false,
        });
        setState(() {
          memberSince = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _updateDisplayName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update Firebase Auth display name
      await user.updateDisplayName(_nameController.text.trim());

      // Update Firestore profile
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': _nameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        displayName = _nameController.text.trim();
        _isEditingName = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating name: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      // Reauthenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();

      setState(() {
        _isChangingPassword = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error changing password: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending verification email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Personal Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to continue'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(user),

                  const SizedBox(height: 32),

                  // Basic Information
                  _buildBasicInfoSection(),

                  const SizedBox(height: 24),

                  // Personal Information
                  _buildPersonalInfoSection(),

                  const SizedBox(height: 24),

                  // Security Information
                  if (user.email != null) _buildSecuritySection(user),

                  const SizedBox(height: 24),

                  // Membership Information
                  _buildMembershipSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF04D6F7).withOpacity(0.2),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Color(0xFF04D6F7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.emailVerified
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.emailVerified ? Icons.verified : Icons.warning,
                  size: 16,
                  color: user.emailVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  user.emailVerified ? 'Verified' : 'Unverified',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: user.emailVerified ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Full Name - Fixed Layout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: !_isEditingName
                                ? Text(
                                    displayName ?? 'Not set',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  )
                                : TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your full name',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                          if (_isEditingName) ...[
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: _updateDisplayName,
                              color: Colors.green,
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _nameController.text = displayName ?? '';
                                setState(() {
                                  _isEditingName = false;
                                });
                              },
                              color: Colors.red,
                              padding: EdgeInsets.zero,
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => setState(() => _isEditingName = true),
                              color: const Color(0xFF04D6F7),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email Address
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.email, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              email ?? 'Not set',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (FirebaseAuth.instance.currentUser != null && FirebaseAuth.instance.currentUser!.email != null) ...[
                            const SizedBox(width: 8),
                            if (FirebaseAuth.instance.currentUser!.emailVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      size: 12,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Unverified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          // Phone Number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  isPhoneVerified ? Icons.phone_android : Icons.phone,
                  color: Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPhoneVerified ? 'Phone Number (Verified)' : 'Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        phoneNumber?.isNotEmpty == true ? phoneNumber! : 'Not set',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      if (isPhoneVerified)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPhoneVerified ? Icons.edit : Icons.add,
                    color: const Color(0xFF04D6F7),
                  ),
                  onPressed: () {
                    if (isPhoneVerified) {
                      _showPhoneEditDialog();
                    } else {
                      _navigateToPhoneVerification();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Date of Birth
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Date of Birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  dateOfBirth != null
                      ? '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
                      : 'Not set',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showDatePicker,
                  color: const Color(0xFF04D6F7),
                ),
              ],
            ),
          ),

          // Gender
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Gender',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  gender ?? 'Not set',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showGenderDialog,
                  color: const Color(0xFF04D6F7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Email Verification
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Verification',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        user.emailVerified ? 'Your email is verified' : 'Verify your email',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!user.emailVerified)
                  TextButton(
                    onPressed: _sendEmailVerification,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF04D6F7).withOpacity(0.1),
                      foregroundColor: const Color(0xFF04D6F7),
                    ),
                    child: const Text('Verify'),
                  ),
              ],
            ),
          ),

          // Password Change
          if (_isChangingPassword)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            setState(() => _isChangingPassword = false);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF04D6F7),
                          ),
                          child: const Text('Change'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.grey, size: 24),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isChangingPassword = true),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF04D6F7),
                    ),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),

          // Two-Factor Authentication (Placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Not enabled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Membership',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Member Since
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Since',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        memberSince != null
                            ? '${memberSince!.day}/${memberSince!.month}/${memberSince!.year}'
                            : 'Recently joined',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified,
                  color: Color(0xFF04D6F7),
                  size: 20,
                ),
              ],
            ),
          ),

          // Account Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.grey, size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    await _showDatePicker();
  }

  Future<void> _selectGender() async {
    _showGenderDialog();
  }

  void _showPhoneEditDialog() {
    final TextEditingController dialogController = TextEditingController(
      text: phoneNumber,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Phone Number'),
        content: TextField(
          controller: dialogController,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (dialogController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number cannot be empty')),
                );
                return;
              }

              User? user = _auth.currentUser;
              if (user == null) return;

              try {
                await _firestore.collection('users').doc(user.uid).update({
                  'phoneNumber': dialogController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                setState(() {
                  phoneNumber = dialogController.text.trim();
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating phone number: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF04D6F7),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      User? user = _auth.currentUser;
      if (user == null) return;

      try {
        await _firestore.collection('users').doc(user.uid).update({
          'dateOfBirth': Timestamp.fromDate(pickedDate),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          dateOfBirth = pickedDate;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date of birth updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating date of birth: $e')),
        );
      }
    }
  }

  void _showGenderDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Gender'),
        children: [
          SimpleDialogOption(
            onPressed: () => _updateGender('Male'),
            child: const Text('Male'),
          ),
          SimpleDialogOption(
            onPressed: () => _updateGender('Female'),
            child: const Text('Female'),
          ),
          SimpleDialogOption(
            onPressed: () => _updateGender('Other'),
            child: const Text('Other'),
          ),
          SimpleDialogOption(
            onPressed: () => _updateGender('Prefer not to say'),
            child: const Text('Prefer not to say'),
          ),
        ],
      ),
    );
  }

  void _showAddProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sign In Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Google or Apple sign in to your account for easier access.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _linkGoogleAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.account_circle, color: Colors.red),
                    label: const Text('Add Google'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _linkAppleAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.smartphone),
                    label: const Text('Add Apple'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToPhoneVerification() async {
    print('Navigating to phone verification screen...');

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneVerificationTestScreen(),
        ),
      );

      print('Phone verification result: $result');

      if (result != null && result is Map<String, dynamic>) {
        print('Valid result received: phoneNumber=${result['phoneNumber']}, verified=${result['verified']}');

        setState(() {
          phoneNumber = result['phoneNumber'];
          isPhoneVerified = result['verified'] ?? false;
          loginProvider = 'phone';
        });

        // Reload user data to refresh the UI
        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified successfully!')),
        );

        // Update Firestore with verified phone
        User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'phoneNumber': result['phoneNumber'],
            'phoneVerified': result['verified'] ?? false,
            'loginProvider': 'phone',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          print('Firestore updated successfully');
        }
      } else {
        print('No result received from phone verification');
      }
    } catch (e) {
      print('Error navigating to phone verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: $e')),
      );
    }
  }

  Future<void> _linkGoogleAccount() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google account linking is not available')),
    );
  }

  Future<void> _linkAppleAccount() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple account linking is not available')),
    );
  }

  void _updateGender(String selectedGender) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'gender': selectedGender,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        gender = selectedGender;
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gender updated to $selectedGender')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating gender: $e')),
      );
    }
  }
}
