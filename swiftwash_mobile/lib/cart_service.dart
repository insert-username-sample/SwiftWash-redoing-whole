import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = 'cart';

  static Future<void> saveCart(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = items.map((item) {
      return {
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'serviceName': item['serviceName'],
        'icon_code_point': item['icon'].codePoint,
        'icon_font_family': item['icon'].fontFamily,
      };
    }).toList();
    await prefs.setString(_cartKey, jsonEncode(cartData));
  }

  static Future<List<Map<String, dynamic>>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString(_cartKey);
    if (cartData == null) {
      return [];
    }
    final List<dynamic> decodedData = jsonDecode(cartData);
    return decodedData.map((item) {
      return {
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'serviceName': item['serviceName'],
        'icon_code_point': item['icon_code_point'],
        'icon_font_family': item['icon_font_family'],
      };
    }).toList();
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
