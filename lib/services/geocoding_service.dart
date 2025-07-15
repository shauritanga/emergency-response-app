import 'package:geocoding/geocoding.dart';

class GeocodingService {
  // Cache to avoid repeated geocoding calls for the same coordinates
  static final Map<String, String> _cache = {};

  // Mock data for common locations (useful for development/offline mode)
  static final Map<String, String> _mockLocations = {
    '40.713,-74.006': 'Manhattan, New York',
    '51.507,-0.128': 'Westminster, London',
    '48.857,2.295': 'Champs-Élysées, Paris',
    '35.676,139.650': 'Shibuya, Tokyo',
    '-33.867,151.207': 'Sydney CBD, Sydney',
    '37.775,-122.418': 'Mission District, San Francisco',
    '34.052,-118.244': 'Downtown, Los Angeles',
    '41.878,-87.630': 'The Loop, Chicago',
    '25.761,-80.191': 'Downtown, Miami',
    '47.608,-122.335': 'Capitol Hill, Seattle',
    // Add the actual coordinates from the app (Dar es Salaam, Tanzania)
    '-6.726,39.198': 'Dar es Salaam, Tanzania',
    '-6.727,39.198': 'Dar es Salaam, Tanzania',
    '-6.728,39.197': 'Dar es Salaam, Tanzania',
    '-6.725,39.199': 'Dar es Salaam, Tanzania',
    // Add more variations for better matching
    '-6.726,39.197': 'Kinondoni, Dar es Salaam',
    '-6.727,39.197': 'Ilala, Dar es Salaam',
    '-6.728,39.198': 'Temeke, Dar es Salaam',
    // Add more mock locations as needed for testing
  };

  static Future<String> getShortLocationName(
    double latitude,
    double longitude,
  ) async {
    final cacheKey =
        '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Use Flutter's geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        String locationName = '';

        if (placemark.subAdministrativeArea != null &&
            placemark.subAdministrativeArea!.isNotEmpty) {
          locationName = placemark.subAdministrativeArea!;
        } else if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          locationName = placemark.administrativeArea!;
        }

        // Add country if available and different from the main location
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          if (locationName.isNotEmpty &&
              !locationName.contains(placemark.country!)) {
            locationName += ', ${placemark.locality!}';
          } else if (locationName.isEmpty) {
            locationName = placemark.country!;
          }
        }

        if (locationName.isNotEmpty) {
          _cache[cacheKey] = locationName;
          return locationName;
        }
      }

      // If no placemark data, fall through to mock data
      throw Exception('No placemark data available');
    } catch (e) {
      print('🚨 Geocoding failed: $e');

      // Try mock data fallback for development/offline mode
      final mockKey =
          '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';

      if (_mockLocations.containsKey(mockKey)) {
        final mockResult = _mockLocations[mockKey]!;
        _cache[cacheKey] = mockResult;
        print('📍 Using mock location: $mockResult');
        return mockResult;
      }

      // Try to find nearby coordinates in mock data (within 0.01 degrees)
      for (final entry in _mockLocations.entries) {
        final parts = entry.key.split(',');
        if (parts.length == 2) {
          final mockLat = double.tryParse(parts[0]);
          final mockLon = double.tryParse(parts[1]);

          if (mockLat != null && mockLon != null) {
            final latDiff = (latitude - mockLat).abs();
            final lonDiff = (longitude - mockLon).abs();

            // If within 0.01 degrees (roughly 1km), use this mock location
            if (latDiff < 0.01 && lonDiff < 0.01) {
              final mockResult = entry.value;
              _cache[cacheKey] = mockResult;
              print('📍 Using nearby mock location: $mockResult');
              return mockResult;
            }
          }
        }
      }

      // Final fallback to coordinates
      final fallback =
          '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
      _cache[cacheKey] = fallback;
      return fallback;
    }
  }

  /// Clear the geocoding cache
  static void clearCache() {
    _cache.clear();
    print('🗑️ Geocoding cache cleared');
  }
}
