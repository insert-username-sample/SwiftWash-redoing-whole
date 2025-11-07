import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String? fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
          'phone': phone,
        },
      );

      if (response.user != null) {
        await _createProfile(
          userId: response.user!.id,
          username: username,
          email: email,
          fullName: fullName,
          phone: phone,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in with phone: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<UserResponse> updateUser({
    String? email,
    String? password,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          phone: phone,
          data: data,
        ),
      );
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Future<ProfileModel?> getCurrentProfile() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return ProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting current profile: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? fcmToken,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (fcmToken != null) updates['fcm_token'] = fcmToken;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        await _supabase.from('profiles').update(updates).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> _createProfile({
    required String userId,
    required String username,
    required String email,
    String? fullName,
    String? phone,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'username': username,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'user_type': 'customer',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating profile: $e');
      rethrow;
    }
  }

  Future<void> saveFcmToken(String token) async {
    try {
      await updateProfile(fcmToken: token);
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  bool isAuthenticated() {
    return currentUser != null;
  }
}
