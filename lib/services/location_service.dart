import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/dialogs/location_dialog.dart';
import '../utils/snackbar_utils.dart';

class LocationService {
  /// Detects city and state with proper checks for device location service and permissions.
  /// Shows themed dialogs if location service is disabled or permissions are permanently denied.
  /// Returns the detected "City, State" string, or null if cancelled/unavailable.
  Future<String?> detectLocationWithDialogs(BuildContext context) async {
    // 1. Check if device location service is enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        await showEnableLocationDialog(context);
      }
      return null;
    }

    // 2. Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          showErrorSnackBar(
            context: context,
            message: 'Location permission was denied. Please enter manually.',
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        await showLocationPermissionDialog(context);
      }
      return null;
    }

    // 3. Location is enabled and permitted; fetch position and address
    final location = await _getPositionAndAddress();
    if (location == null && context.mounted) {
      showErrorSnackBar(
        context: context,
        message: 'Unable to detect location. Please enter manually.',
      );
    }
    return location;
  }

  /// Get user's current location and return as "City, State" format
  /// Returns null if location cannot be determined
  Future<String?> getCurrentCityAndState() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await _getPositionAndAddress();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Internal helper to fetch position and reverse geocode
  Future<String?> _getPositionAndAddress() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String city = place.locality ?? place.subAdministrativeArea ?? '';
        String state = place.administrativeArea ?? '';

        if (city.isNotEmpty && state.isNotEmpty) {
          return '$city, $state';
        } else if (city.isNotEmpty) {
          return city;
        } else if (state.isNotEmpty) {
          return state;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting position or address: $e');
      return null;
    }
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open device location settings (GPS settings)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (useful when permission is permanently denied)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
