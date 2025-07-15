import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final locationProvider = FutureProvider<LocationData?>((ref) async {
  return await ref.watch(locationServiceProvider).getCurrentLocation();
});

// Geocoding provider for converting coordinates to location names
// Using string key to prevent infinite rebuilds with Map equality issues
final locationNameProvider = FutureProvider.family<String, String>((
  ref,
  coordinateKey,
) async {
  // Parse coordinates from the key (format: "lat,lng")
  final parts = coordinateKey.split(',');
  final latitude = double.parse(parts[0]);
  final longitude = double.parse(parts[1]);

  print('🔍 LocationProvider: Requesting location for $latitude, $longitude');
  final result = await GeocodingService.getShortLocationName(
    latitude,
    longitude,
  );
  print('🔍 LocationProvider: Got result: $result');
  return result;
});
