import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final locationProvider = FutureProvider<LocationData?>((ref) async {
  return await ref.watch(locationServiceProvider).getCurrentLocation();
});
