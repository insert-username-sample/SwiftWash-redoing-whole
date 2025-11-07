import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  // Hardcoded founder credentials
  static const String _password = 'FoundersOffice';
  static const List<String> _validUsernames = [
    'manas-founder',
    'kashinath-founder'
  ];

  String? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  String? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => true; // Founders are always super admins
  String get adminRole => 'super_admin';

  Future<void> signInWithUsernameAndPassword(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Check credentials
      if (password != _password) {
        throw Exception('Invalid password');
      }

      if (!_validUsernames.contains(username)) {
        throw Exception('Invalid username');
      }

      // Authentication successful
      _currentUser = username;
      _isAuthenticated = true;

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));

      _currentUser = null;
      _isAuthenticated = false;

    } catch (e) {
      print('Error signing out: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get display name for the current user
  String getDisplayName() {
    if (_currentUser == null) return 'Unknown';

    switch (_currentUser) {
      case 'manas-founder':
        return 'Manas (Founder)';
      case 'kashinath-founder':
        return 'Kashinath (Founder)';
      default:
        return _currentUser!;
    }
  }

  // Check if username is valid
  bool isValidUsername(String username) {
    return _validUsernames.contains(username);
  }

  // Get all valid usernames (for display purposes)
  List<String> getValidUsernames() {
    return _validUsernames;
  }
}
