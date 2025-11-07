import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMarkerService {
  static final CustomMarkerService _instance = CustomMarkerService._internal();
  factory CustomMarkerService() => _instance;
  CustomMarkerService._internal();

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _facilityIcon;
  BitmapDescriptor? _customerIcon;
  BitmapDescriptor? _scooterIcon;

  // Initialize custom markers
  Future<void> initializeMarkers() async {
    _driverIcon = await _createDriverIcon();
    _facilityIcon = await _createFacilityIcon();
    _customerIcon = await _createCustomerIcon();
    _scooterIcon = await _createScooterIcon();
  }

  // Create driver icon (person with delivery bag)
  Future<BitmapDescriptor> _createDriverIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    // Background circle
    paint.color = Colors.blue;
    canvas.drawCircle(const Offset(25, 25), 25, paint);

    // White border
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(const Offset(25, 25), 25, paint);

    // Driver icon (person with bag)
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(const Offset(25, 18), 4, paint);

    // Body
    canvas.drawRect(const Rect.fromLTWH(21, 22, 8, 10), paint);

    // Delivery bag
    paint.color = Colors.orange;
    canvas.drawRect(const Rect.fromLTWH(29, 24, 6, 8), paint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(50, 50);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Create facility icon (building)
  Future<BitmapDescriptor> _createFacilityIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    // Building background
    paint.color = Colors.red;
    canvas.drawRect(const Rect.fromLTWH(10, 10, 30, 30), paint);

    // Windows
    paint.color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(15, 15, 5, 5), paint);
    canvas.drawRect(const Rect.fromLTWH(22, 15, 5, 5), paint);
    canvas.drawRect(const Rect.fromLTWH(29, 15, 5, 5), paint);
    canvas.drawRect(const Rect.fromLTWH(15, 22, 5, 5), paint);
    canvas.drawRect(const Rect.fromLTWH(22, 22, 5, 5), paint);
    canvas.drawRect(const Rect.fromLTWH(29, 22, 5, 5), paint);

    // SwiftWash logo area
    paint.color = Colors.blue;
    canvas.drawRect(const Rect.fromLTWH(15, 30, 20, 8), paint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(50, 50);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Create customer icon (home)
  Future<BitmapDescriptor> _createCustomerIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    // Background circle
    paint.color = Colors.green;
    canvas.drawCircle(const Offset(25, 25), 25, paint);

    // White border
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(const Offset(25, 25), 25, paint);

    // Home icon
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    // House body
    canvas.drawRect(const Rect.fromLTWH(18, 20, 14, 12), paint);

    // Roof
    final path = Path();
    path.moveTo(15, 20);
    path.lineTo(25, 12);
    path.lineTo(35, 20);
    path.close();
    canvas.drawPath(path, paint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(50, 50);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Create scooter icon for driver
  Future<BitmapDescriptor> _createScooterIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();

    // Background circle
    paint.color = Colors.blue;
    canvas.drawCircle(const Offset(25, 25), 25, paint);

    // White border
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(const Offset(25, 25), 25, paint);

    // Scooter body
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    // Main body
    canvas.drawRect(const Rect.fromLTWH(15, 20, 20, 8), paint);

    // Wheels
    paint.color = Colors.grey;
    canvas.drawCircle(const Offset(18, 32), 4, paint);
    canvas.drawCircle(const Offset(32, 32), 4, paint);

    // Handle
    canvas.drawLine(const Offset(25, 20), const Offset(25, 12), paint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(50, 50);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Getter methods for icons
  BitmapDescriptor get driverIcon => _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  BitmapDescriptor get facilityIcon => _facilityIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor get customerIcon => _customerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor get scooterIcon => _scooterIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
}
