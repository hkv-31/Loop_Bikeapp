import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationService with ChangeNotifier {
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLoading = false;
  String? _error;

  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Simple mock coordinates for Bandra
  double get mockLatitude => 19.0540;
  double get mockLongitude => 72.8302;

  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setMockLocation();
        return true;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied';
          _setMockLocation();
          return true;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied.';
        _setMockLocation();
        return true;
      }

      return true;
    } catch (e) {
      _setMockLocation();
      return true;
    }
  }

  void _setMockLocation() {
    _currentLatitude = mockLatitude;
    _currentLongitude = mockLongitude;
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      bool hasPermission = await checkPermission();
      if (!hasPermission) return;

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      } catch (e) {
        // Use mock location for web/emulator
        _setMockLocation();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _setMockLocation();
      _error = 'Using demo location in Bandra';
      notifyListeners();
    }
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  // Get bearing between two points for map direction
  double getBearing(double startLat, double startLng, double endLat, double endLng) {
    final startLatRad = startLat * (math.pi / 180);
    final startLngRad = startLng * (math.pi / 180);
    final endLatRad = endLat * (math.pi / 180);
    final endLngRad = endLng * (math.pi / 180);

    final y = math.sin(endLngRad - startLngRad) * math.cos(endLatRad);
    final x = math.cos(startLatRad) * math.sin(endLatRad) - 
              math.sin(startLatRad) * math.cos(endLatRad) * math.cos(endLngRad - startLngRad);
    final bearing = math.atan2(y, x);

    return (bearing * (180 / math.pi) + 360) % 360;
  }
}