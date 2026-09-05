import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStream;
  static bool _isStarting = false;

  // ============================================================
  // CHECK / REQUEST LOCATION PERMISSION
  // ============================================================

  static Future<bool> ensureLocationPermission() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      print('Location permission denied.');
      return false;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      print(
        'Location permission permanently denied.',
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // START LIVE LOCATION UPDATES
  // ============================================================

  static Future<bool> startLiveUpdates(
    int userId,
  ) async {
    // Prevent multiple simultaneous starts
    if (_isStarting) {
      print('Location service is already starting.');
      return false;
    }

    // Already running
    if (_positionStream != null) {
      print('Live location updates already running.');
      return true;
    }

    _isStarting = true;

    try {
      final hasPermission =
          await ensureLocationPermission();

      if (!hasPermission) {
        return false;
      }

      const LocationSettings locationSettings =
          LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream =
          Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          try {
            final result =
                await ApiService.updateUserLocation(
              userId,
              position.latitude,
              position.longitude,
            );

            print(
              'Location updated: '
              '${position.latitude}, '
              '${position.longitude}',
            );

            print(
              'Backend response: $result',
            );
          } catch (e) {
            print(
              'Error updating location: $e',
            );
          }
        },
        onError: (error) {
          print(
            'Location stream error: $error',
          );
        },
      );

      print('Live location updates started.');

      return true;
    } catch (e) {
      print(
        'Error starting live location: $e',
      );

      return false;
    } finally {
      _isStarting = false;
    }
  }

  // ============================================================
  // STOP LIVE LOCATION UPDATES
  // ============================================================

  static Future<void> stopLiveUpdates() async {
    await _positionStream?.cancel();

    _positionStream = null;

    print('Live location updates stopped.');
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission =
          await ensureLocationPermission();

      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print(
        'Error getting current location: $e',
      );

      return null;
    }
  }
}