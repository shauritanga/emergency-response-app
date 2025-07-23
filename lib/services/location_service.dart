import 'package:location/location.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';

class LocationService {
  final Location _location = Location();

  // High accuracy configuration
  static const int _maxAccuracyMeters =
      10; // Accept only readings within 10m accuracy
  static const int _maxReadings = 5; // Take up to 5 readings for averaging
  static const Duration _readingTimeout = Duration(
    seconds: 30,
  ); // Max time to get accurate reading
  static const Duration _readingInterval = Duration(
    seconds: 2,
  ); // Interval between readings

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    // Configure location settings for high accuracy
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // 1 second interval
      distanceFilter: 0, // Get all location updates
    );

    return await _location.getLocation();
  }

  /// Get high accuracy location with multiple readings and averaging
  Future<LocationData?> getHighAccuracyLocation({
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('Checking location permissions...');

      // Check permissions first
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          onStatusUpdate?.call('Location service not available');
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          onStatusUpdate?.call('Location permission denied');
          return null;
        }
      }

      onStatusUpdate?.call('Configuring GPS for high accuracy...');

      // Configure for maximum accuracy
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 500, // 0.5 second interval for rapid updates
        distanceFilter: 0, // Get all updates regardless of distance
      );

      onStatusUpdate?.call('Warming up GPS...');

      // Warm up GPS - get initial reading and discard it
      try {
        await _location.getLocation().timeout(Duration(seconds: 10));
        await Future.delayed(Duration(seconds: 2)); // Let GPS stabilize
      } catch (e) {
        debugPrint('GPS warm-up failed: $e');
      }

      onStatusUpdate?.call('Getting accurate location readings...');

      // Collect multiple high-accuracy readings
      List<LocationData> accurateReadings = [];
      final startTime = DateTime.now();

      while (accurateReadings.length < _maxReadings &&
          DateTime.now().difference(startTime) < _readingTimeout) {
        try {
          final reading = await _location.getLocation().timeout(
            Duration(seconds: 5),
          );

          // Only accept readings with good accuracy
          if (reading.accuracy != null &&
              reading.accuracy! <= _maxAccuracyMeters) {
            accurateReadings.add(reading);
            onStatusUpdate?.call(
              'Got accurate reading ${accurateReadings.length}/$_maxReadings (±${reading.accuracy!.toStringAsFixed(1)}m)',
            );
            debugPrint(
              '📍 Accurate reading ${accurateReadings.length}: '
              '${reading.latitude}, ${reading.longitude} '
              '(±${reading.accuracy}m)',
            );
          } else {
            onStatusUpdate?.call(
              'Waiting for better accuracy... (current: ±${reading.accuracy?.toStringAsFixed(1) ?? 'unknown'}m)',
            );
            debugPrint(
              '⚠️ Inaccurate reading discarded: accuracy = ${reading.accuracy}m',
            );
          }

          // Small delay between readings
          if (accurateReadings.length < _maxReadings) {
            await Future.delayed(_readingInterval);
          }
        } catch (e) {
          debugPrint('Error getting location reading: $e');
          await Future.delayed(Duration(seconds: 1));
        }
      }

      if (accurateReadings.isEmpty) {
        onStatusUpdate?.call('Could not get accurate location');
        // Fallback to basic location if no accurate readings
        return await getCurrentLocation();
      }

      onStatusUpdate?.call('Calculating best location...');

      // Calculate averaged location from accurate readings
      final bestLocation = _calculateBestLocation(accurateReadings);

      final finalAccuracy = _calculateAverageAccuracy(accurateReadings);
      onStatusUpdate?.call(
        'Location acquired with ±${finalAccuracy.toStringAsFixed(1)}m accuracy',
      );

      debugPrint(
        '✅ Final high-accuracy location: '
        '${bestLocation.latitude}, ${bestLocation.longitude} '
        '(±${finalAccuracy.toStringAsFixed(1)}m from ${accurateReadings.length} readings)',
      );

      return bestLocation;
    } catch (e) {
      debugPrint('Error in getHighAccuracyLocation: $e');
      onStatusUpdate?.call('Error getting location: $e');
      return null;
    }
  }

  /// Calculate the best location from multiple readings using weighted averaging
  LocationData _calculateBestLocation(List<LocationData> readings) {
    if (readings.isEmpty) throw ArgumentError('No readings provided');
    if (readings.length == 1) return readings.first;

    // Use weighted average based on accuracy (more accurate readings have higher weight)
    double totalWeight = 0;
    double weightedLat = 0;
    double weightedLng = 0;
    double totalAltitude = 0;
    int altitudeCount = 0;

    for (final reading in readings) {
      // Weight is inverse of accuracy (better accuracy = higher weight)
      final weight = reading.accuracy != null ? 1.0 / reading.accuracy! : 1.0;
      totalWeight += weight;

      weightedLat += reading.latitude! * weight;
      weightedLng += reading.longitude! * weight;

      if (reading.altitude != null) {
        totalAltitude += reading.altitude!;
        altitudeCount++;
      }
    }

    final avgLat = weightedLat / totalWeight;
    final avgLng = weightedLng / totalWeight;
    final avgAltitude =
        altitudeCount > 0 ? totalAltitude / altitudeCount : null;

    // Create a new LocationData with averaged values
    // Use the most recent reading as base and update coordinates
    final baseReading = readings.last;

    return LocationData.fromMap({
      'latitude': avgLat,
      'longitude': avgLng,
      'altitude': avgAltitude,
      'accuracy': _calculateAverageAccuracy(readings),
      'speed': baseReading.speed,
      'speedAccuracy': baseReading.speedAccuracy,
      'heading': baseReading.heading,
      'time': baseReading.time,
      'isMock': baseReading.isMock,
      'verticalAccuracy': baseReading.verticalAccuracy,
      'elapsedRealtimeNanos': baseReading.elapsedRealtimeNanos,
      'elapsedRealtimeUncertaintyNanos':
          baseReading.elapsedRealtimeUncertaintyNanos,
      'satelliteNumber': baseReading.satelliteNumber,
      'provider': baseReading.provider,
    });
  }

  /// Calculate average accuracy from multiple readings
  double _calculateAverageAccuracy(List<LocationData> readings) {
    if (readings.isEmpty) return double.infinity;

    final accuracies =
        readings
            .where((r) => r.accuracy != null)
            .map((r) => r.accuracy!)
            .toList();

    if (accuracies.isEmpty) return double.infinity;

    return accuracies.reduce((a, b) => a + b) / accuracies.length;
  }

  /// Get location with custom accuracy requirements
  Future<LocationData?> getLocationWithAccuracy({
    double maxAccuracyMeters = 15.0,
    int maxAttempts = 3,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      // Check permissions
      final hasPermission = await _checkPermissions();
      if (!hasPermission) return null;

      // Configure for high accuracy
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 1000,
        distanceFilter: 0,
      );

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        debugPrint('🎯 Location attempt $attempt/$maxAttempts');

        try {
          final location = await _location.getLocation().timeout(timeout);

          if (location.accuracy != null &&
              location.accuracy! <= maxAccuracyMeters) {
            debugPrint(
              '✅ Got accurate location: ${location.latitude}, ${location.longitude} '
              '(±${location.accuracy}m)',
            );
            return location;
          } else {
            debugPrint(
              '⚠️ Location not accurate enough: ±${location.accuracy}m '
              '(required: ±${maxAccuracyMeters}m)',
            );
          }
        } catch (e) {
          debugPrint('❌ Location attempt $attempt failed: $e');
        }

        // Wait before next attempt
        if (attempt < maxAttempts) {
          await Future.delayed(Duration(seconds: 2));
        }
      }

      // If no accurate reading, return best available
      debugPrint(
        '⚠️ Could not get required accuracy, returning best available',
      );
      return await _location.getLocation();
    } catch (e) {
      debugPrint('❌ Error in getLocationWithAccuracy: $e');
      return null;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    return true;
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
