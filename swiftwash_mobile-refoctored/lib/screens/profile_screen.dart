import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';
import 'avatar_selection_screen.dart';
import 'saved_addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'personal_details_screen.dart';
import 'premium_screen.dart';
import 'help_and_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  // Avatar state
  Map<String, dynamic>? _selectedAvatar;
  int? _selectedAvatarIndex;
  Color? _selectedAvatarColor;

  // User data state
  String? _displayName;
  String? _phoneNumber;
  String? _loginProvider;

  // Subscription state
  SubscriptionModel? _currentSubscription;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSubscriptionData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Detect login provider
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
        _displayName = user.displayName ?? 'User';
        _phoneNumber = user.phoneNumber ?? '';
        _loginProvider = provider;
      });
    }
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoadingSubscription = true);
    try {
      final subscription = await SubscriptionService().getCurrentSubscription();
      setState(() {
        _currentSubscription = subscription;
        _isLoadingSubscription = false;
      });
    } catch (e) {
      print('Error loading subscription: $e');
      setState(() => _isLoadingSubscription = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildAccountInfoSection(),
            const SizedBox(height: 24),
            _buildMembershipSection(),
            const SizedBox(height: 24),
            _buildPreferencesSection(),
            const SizedBox(height: 24),
            _buildSupportSection(),
            const SizedBox(height: 24),
            _buildLogoutSection(),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openAvatarSelection,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildCustomAvatar(80),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName ?? 'User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _loginProvider == 'google' ? Icons.account_circle_outlined : Icons.phone,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _loginProvider == 'google'
                            ? 'Signed in with Google Account'
                            : _phoneNumber?.isNotEmpty == true ? _phoneNumber! : 'Phone verification needed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openAvatarSelection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF48FF4F), width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 12, color: Color(0xFF04D6F7)),
                        const SizedBox(width: 8),
                        Text(
                          'Change Avatar',
                          style: TextStyle(
                            color: Color(0xFF04D6F7),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildAccountInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Account Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          _buildMenuItem(
            Icons.place,
            'Saved Addresses',
            Colors.blue,
            _manageSavedAddresses,
          ),
          _buildMenuItem(
            Icons.credit_card,
            'Payment Methods',
            Colors.green,
            _managePaymentMethods,
          ),
          _buildMenuItem(
            Icons.person,
            'Personal Details',
            Colors.purple,
            _managePersonalDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSection() {
    if (_isLoadingSubscription) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
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
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isPremium = _currentSubscription?.isActive ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                colors: [Color(0xFF04D6F7), Color(0xFF48FF4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Swift Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                isPremium ? Icons.star : Icons.star_border,
                color: isPremium ? Colors.yellow : Colors.white,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Active until ${_formatDate(_currentSubscription!.endDate)}'
                : 'Upgrade to Premium for exclusive benefits',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          if (isPremium && _currentSubscription!.daysRemaining <= 7)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_currentSubscription!.daysRemaining} days remaining',
                style: TextStyle(
                  color: Colors.orange.shade200,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _handlePremiumAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPremium ? 'Renew Plan' : 'Upgrade Now',
                    style: TextStyle(
                      color: isPremium ? Color(0xFF04D6F7) : Color(0xFF48FF4F),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (!isPremium) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF48FF4F),
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          _buildComingSoonItem(
            Icons.nightlight_round,
            'Dark Mode',
            'Coming Soon',
          ),
          _buildToggleItem(
            Icons.notifications,
            'Notifications',
            Colors.orange,
            _notifications,
            (value) => setState(() => _notifications = value),
          ),
          _buildComingSoonItem(
            Icons.language,
            'Language',
            'Coming Soon',
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Support & Policies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          _buildMenuItem(
            Icons.help,
            'Help Center',
            Colors.blue,
            _openHelpCenter,
          ),
          _buildMenuItem(
            Icons.description,
            'Terms & Conditions',
            Colors.grey,
            _openTerms,
          ),
          _buildMenuItem(
            Icons.shield,
            'Privacy Policy',
            Colors.green,
            _openPrivacyPolicy,
          ),
          _buildMenuItem(
            Icons.mail,
            'Contact Us',
            Colors.purple,
            _contactUs,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
      child: InkWell(
        onTap: () => _showLogoutModal(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Color(0xFFFF4444)),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor, VoidCallback onTap, {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, String title, Color iconColor, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: value ? Color(0xFF04D6F7) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: value ? 24 : 2,
                    top: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }

  // Avatar methods
  void _openAvatarSelection() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AvatarSelectionScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAvatar = result;
        _selectedAvatarIndex = result['avatarIndex'];
        _selectedAvatarColor = result['color'];
      });
    }
  }

  Widget _buildCustomAvatar(double size) {
    if (_selectedAvatar == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade100,
        ),
        child: Icon(
          Icons.person,
          color: Colors.blue,
          size: size * 0.6,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _selectedAvatar?['color'] ?? Colors.blue.shade100,
        border: Border.all(
          color: Colors.white,
          width: size * 0.05,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Icon(
        _selectedAvatar?['avatarType'] == 'woman' ? Icons.person_2 : Icons.person,
        color: Colors.white,
        size: size * 0.75,
      ),
    );
  }

  // Profile methods with proper navigation
  void _manageSavedAddresses() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
    );
  }

  void _managePaymentMethods() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
    );
  }

  void _managePersonalDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PersonalDetailsScreen()),
    );
  }

  void _handlePremiumAction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    ).then((_) {
      // Refresh subscription data when returning from premium screen
      _loadSubscriptionData();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }


  void _openHelpCenter() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const HelpAndSupportScreen()),
    );
  }

  void _openTerms() {
    Navigator.of(context).pop();
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).pop();
  }

  void _contactUs() {
    // Navigate back and potentially open help tab
    Navigator.of(context).pop();
  }

  // Private helper methods


  void _showSettingsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to settings')),
    );
  }

  void _showLogoutModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully logged out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}
