import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

String get googleMapsApiKey {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? 'YOUR_ANDROID_API_KEY';
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    return dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? 'YOUR_IOS_API_KEY';
  } else {
    // Web or other platforms - you can add more conditions here
    return dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? 'YOUR_ANDROID_API_KEY';
  }
}
