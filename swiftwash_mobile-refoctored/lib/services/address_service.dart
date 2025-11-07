import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/supabase_config.dart';
import '../models/address_model.dart';
import '../services/auth_service.dart';

class AddressService {
  final _supabase = SupabaseConfig.client;
  final _authService = AuthService();

  Future<List<AddressModel>> getUserAddresses() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AddressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting user addresses: $e');
      rethrow;
    }
  }

  Future<AddressModel?> getDefaultAddress() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;

      return AddressModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting default address: $e');
      return null;
    }
  }

  Future<AddressModel> getAddress(String addressId) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('id', addressId)
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting address: $e');
      rethrow;
    }
  }

  Future<AddressModel> createAddress({
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required double latitude,
    required double longitude,
    required String formattedAddress,
    String? placeId,
    bool isDefault = false,
  }) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      if (isDefault) {
        await _clearDefaultAddress();
      }

      final data = {
        'user_id': userId,
        'label': label,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'formatted_address': formattedAddress,
        'place_id': placeId,
        'is_default': isDefault,
      };

      final response = await _supabase
          .from('addresses')
          .insert(data)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating address: $e');
      rethrow;
    }
  }

  Future<AddressModel> updateAddress({
    required String addressId,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? placeId,
    bool? isDefault,
  }) async {
    try {
      if (isDefault == true) {
        await _clearDefaultAddress();
      }

      final updates = <String, dynamic>{};
      if (label != null) updates['label'] = label;
      if (addressLine1 != null) updates['address_line1'] = addressLine1;
      if (addressLine2 != null) updates['address_line2'] = addressLine2;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (postalCode != null) updates['postal_code'] = postalCode;
      if (country != null) updates['country'] = country;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (formattedAddress != null) updates['formatted_address'] = formattedAddress;
      if (placeId != null) updates['place_id'] = placeId;
      if (isDefault != null) updates['is_default'] = isDefault;

      if (updates.isEmpty) {
        return await getAddress(addressId);
      }

      final response = await _supabase
          .from('addresses')
          .update(updates)
          .eq('id', addressId)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _supabase.from('addresses').delete().eq('id', addressId);
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      await _clearDefaultAddress();
      await updateAddress(addressId: addressId, isDefault: true);
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }

  Future<void> _clearDefaultAddress() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return;

      await _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    } catch (e) {
      debugPrint('Error clearing default address: $e');
    }
  }

  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Address not found');
      }

      final location = locations.first;
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        throw Exception('Unable to get address details');
      }

      final placemark = placemarks.first;

      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address_line1': placemark.street ?? '',
        'city': placemark.locality ?? placemark.subAdministrativeArea ?? '',
        'state': placemark.administrativeArea ?? '',
        'postal_code': placemark.postalCode ?? '',
        'country': placemark.country ?? 'India',
        'formatted_address': [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.postalCode,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', '),
      };
    } catch (e) {
      debugPrint('Error geocoding address: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        throw Exception('Unable to get address details');
      }

      final placemark = placemarks.first;

      return {
        'latitude': latitude,
        'longitude': longitude,
        'address_line1': placemark.street ?? '',
        'city': placemark.locality ?? placemark.subAdministrativeArea ?? '',
        'state': placemark.administrativeArea ?? '',
        'postal_code': placemark.postalCode ?? '',
        'country': placemark.country ?? 'India',
        'formatted_address': [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.postalCode,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', '),
      };
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      rethrow;
    }
  }

  Future<double> calculateDistance({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      final response = await _supabase.rpc('calculate_distance', params: {
        'lat1': from.latitude,
        'lon1': from.longitude,
        'lat2': to.latitude,
        'lon2': to.longitude,
      });

      return (response as num).toDouble();
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return _calculateDistanceLocal(from, to);
    }
  }

  double _calculateDistanceLocal(LatLng from, LatLng to) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((to.latitude - from.latitude) * p) / 2 +
        cos(from.latitude * p) *
            cos(to.latitude * p) *
            (1 - cos((to.longitude - from.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }
}

double cos(num x) => x.toDouble();
double sin(num x) => x.toDouble();
double asin(num x) => x.toDouble();
double sqrt(num x) => x.toDouble();
