import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  // Default baseline center coordinates for Vizianagaram District, Andhra Pradesh
  static const double defaultVizianagaramLat = 18.1124;
  static const double defaultVizianagaramLon = 83.3980;

  /// Requests location permission with graceful error handling
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user.');
          _hasPermission = false;
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions permanently denied.');
        _hasPermission = false;
        return false;
      }

      _hasPermission = true;
      await getCurrentLocation();
      return true;
    } catch (e) {
      debugPrint('[LocationService] Location permission notice: $e');
      _hasPermission = false;
      return false;
    }
  }

  /// Retrieves the current GPS position or uses baseline Vizianagaram coordinate
  Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _currentPosition = position;
      _hasPermission = true;
      debugPrint('[LocationService] Location acquired: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('[LocationService] getCurrentLocation notice: $e');
      // If web permission granted or fallback test mode:
      if (_hasPermission) {
        _currentPosition = Position(
          latitude: defaultVizianagaramLat,
          longitude: defaultVizianagaramLon,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        return _currentPosition;
      }
      return null;
    }
  }

  /// Calculates distance in kilometers between user position and hospital
  double calculateDistanceInKm({
    required double hospitalLat,
    required double hospitalLon,
    double? userLat,
    double? userLon,
  }) {
    final uLat = userLat ?? _currentPosition?.latitude ?? defaultVizianagaramLat;
    final uLon = userLon ?? _currentPosition?.longitude ?? defaultVizianagaramLon;

    final distanceInMeters = Geolocator.distanceBetween(
      uLat,
      uLon,
      hospitalLat,
      hospitalLon,
    );

    return distanceInMeters / 1000.0;
  }
}
