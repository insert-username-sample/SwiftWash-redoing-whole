import 'package:flutter/material.dart';
import 'package:swiftwash_mobile/app_theme.dart';
import 'package:swiftwash_mobile/screens/home_screen.dart';
import 'package:swiftwash_mobile/screens/orders_screen.dart';
import 'package:swiftwash_mobile/screens/help_and_support_screen.dart';
import 'package:swiftwash_mobile/screens/profile_screen.dart';
import 'package:swiftwash_mobile/screens/premium_screen.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Start on Home screen (0=Home, 1=Orders, 2=Premium, 3=Help, 4=Profile)

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    OrdersScreen(),
    PremiumScreen(), // Premium membership screen
    HelpAndSupportScreen(),
    ProfileScreen(), // User profile for person icon tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Container(
            height: 85, // Sufficient height to completely eliminate any remaining overflow
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E7EB), // Thin outline at top
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.brandBlue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.inventory_2_outlined, 'Orders', 1),
                _buildNavItem(Icons.star_outline, 'Premium', 2),
                _buildNavItem(Icons.headset_mic_outlined, 'Help', 3),
                _buildNavItem(Icons.person_outline, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? const Color(0xFF04D6F7) : Colors.grey.shade500,
            size: 28,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index ? const Color(0xFF04D6F7) : Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_selectedIndex == index)
            Container(
              margin: const EdgeInsets.only(top: 1.0),
              width: 16,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF04D6F7), Color(0xFF48FF4F)],
                ),
                borderRadius: BorderRadius.circular(0.5),
              ),
            ),
        ],
      ),
      label: '',
    );
  }
}
