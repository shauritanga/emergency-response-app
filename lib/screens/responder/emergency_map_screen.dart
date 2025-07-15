import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/emergency.dart';
import '../../models/flutter_map_models.dart';
import '../../providers/location_provider.dart';
import '../../providers/routing_provider.dart';
import '../../config/flutter_map_config.dart';

class EmergencyMapScreen extends ConsumerStatefulWidget {
  final Emergency emergency;

  const EmergencyMapScreen({super.key, required this.emergency});

  @override
  ConsumerState<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends ConsumerState<EmergencyMapScreen> {
  MapController? mapController;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  FlutterMapRouteResult? _routeResult;
  bool _isLoading = true;
  bool _showSatellite = false;

  @override
  void initState() {
    super.initState();
    _initializeLocationAndRoute();
  }

  Future<void> _initializeLocationAndRoute() async {
    try {
      // Get user's current location
      final location =
          await ref.read(locationServiceProvider).getCurrentLocation();
      if (location == null ||
          location.latitude == null ||
          location.longitude == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to get current location. Showing emergency location only.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _userLocation = LatLng(location.latitude!, location.longitude!);
      });

      // Get route from user's location to emergency
      try {
        debugPrint('🗺️ Requesting route from routing service...');
        final route = await ref
            .read(routingServiceProvider)
            .getRoute(
              _userLocation!,
              LatLng(widget.emergency.latitude, widget.emergency.longitude),
            );

        if (route.points.isNotEmpty) {
          debugPrint('✅ Route loaded with ${route.points.length} points');
          debugPrint(
            '📏 OSRM calculated distance: ${route.distance} (${route.distanceMeters}m)',
          );
          setState(() {
            _routePoints = route.points;
            _routeResult = route;
            _isLoading = false;
          });
        } else {
          debugPrint('⚠️ Route service returned empty points');
          setState(() {
            _routePoints = [];
            _routeResult = null;
            _isLoading = false;
          });
        }
      } catch (routeError) {
        debugPrint('❌ Route loading failed: $routeError');
        setState(() {
          _routePoints = [];
          _routeResult = null;
          _isLoading = false;
        });
        // Don't show error for route failure - direct distance will be used
      }

      // Adjust map bounds to show both user and emergency locations
      if (mapController != null && _userLocation != null) {
        _fitBounds();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading route: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fitBounds() {
    if (mapController == null || _userLocation == null) return;

    final emergencyLocation = LatLng(
      widget.emergency.latitude,
      widget.emergency.longitude,
    );

    final bounds = FlutterMapBounds.fromPointList([
      _userLocation!,
      emergencyLocation,
    ]);

    mapController!.fitCamera(
      CameraFit.bounds(
        bounds: bounds.toLatLngBounds(),
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  void _onMapCreated(MapController controller) {
    setState(() {
      mapController = controller;
    });

    // Fit bounds after map is created
    if (!_isLoading && _userLocation != null) {
      _fitBounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyLocation = LatLng(
      widget.emergency.latitude,
      widget.emergency.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.emergency.type} Emergency'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Map Type Toggle
          IconButton(
            icon: Icon(_showSatellite ? Icons.map : Icons.satellite),
            tooltip: _showSatellite ? 'Show Map' : 'Show Satellite',
            onPressed: () {
              setState(() {
                _showSatellite = !_showSatellite;
              });
            },
          ),
          // Recenter Map
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Recenter Map',
            onPressed: _fitBounds,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Map
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: emergencyLocation,
                      initialZoom: 14.0,
                      onMapReady: () {
                        final controller = MapController();
                        _onMapCreated(controller);
                      },
                    ),
                    children: [
                      // Base Tile Layer
                      TileLayer(
                        urlTemplate:
                            _showSatellite
                                ? FlutterMapConfig.getTileUrl(
                                  FlutterMapConfig.styleSatellite,
                                )
                                : FlutterMapConfig.openStreetMapUrl,
                        userAgentPackageName: 'com.example.app',
                      ),

                      // Emergency Area Circle
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: emergencyLocation,
                            radius: 100, // 100 meters radius for emergency area
                            useRadiusInMeter: true,
                            color: Colors.red.withValues(alpha: 0.3),
                            borderColor: Colors.red,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),

                      // Route Polyline
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: Colors.blue,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),

                      // Markers
                      MarkerLayer(
                        markers: [
                          // Emergency Marker
                          Marker(
                            point: emergencyLocation,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getEmergencyIcon(widget.emergency.type),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Flexible(
                                    child: const Text(
                                      'Emergency',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // User Location Marker (if available)
                          if (_userLocation != null)
                            Marker(
                              point: _userLocation!,
                              width: 60,
                              height: 60,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Info Panel
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.emergency.type} Emergency',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.emergency.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            if (_userLocation != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDistanceText(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  if (_routeResult != null)
                                    Text(
                                      'ETA: ${_routeResult!.duration}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else if (_routePoints.isEmpty &&
                                      _userLocation != null)
                                    const Text(
                                      '(Direct distance)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  double _calculateDistance() {
    final emergencyLocation = LatLng(
      widget.emergency.latitude,
      widget.emergency.longitude,
    );

    // Priority 1: Use OSRM-calculated route distance (most accurate)
    if (_routeResult != null && _routeResult!.distanceMeters > 0) {
      final distanceKm = _routeResult!.distanceMeters / 1000;
      debugPrint(
        '📏 Using OSRM route distance: ${distanceKm.toStringAsFixed(2)} km',
      );
      return distanceKm;
    }

    // Priority 2: Calculate from route points if available
    if (_routePoints.isNotEmpty && _userLocation != null) {
      debugPrint(
        '📏 Calculating route distance from ${_routePoints.length} points',
      );

      double totalDistance = 0;
      for (int i = 0; i < _routePoints.length - 1; i++) {
        totalDistance += _calculatePointDistance(
          _routePoints[i],
          _routePoints[i + 1],
        );
      }

      debugPrint(
        '📏 Calculated route distance: ${totalDistance.toStringAsFixed(2)} km',
      );
      return totalDistance;
    }

    // Priority 3: Fallback to direct distance (as the crow flies)
    if (_userLocation != null) {
      final directDistance = _calculatePointDistance(
        _userLocation!,
        emergencyLocation,
      );
      debugPrint(
        '📏 Direct distance (fallback): ${directDistance.toStringAsFixed(2)} km',
      );
      return directDistance;
    }

    // No user location available
    debugPrint('📏 No location available for distance calculation');
    return 0;
  }

  double _calculatePointDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    final distanceInKm = distance.as(LengthUnit.Kilometer, point1, point2);

    // Validate the distance (should be reasonable for emergency response)
    if (distanceInKm < 0 || distanceInKm > 1000) {
      debugPrint('⚠️ Suspicious distance calculated: ${distanceInKm}km');
    }

    return distanceInKm;
  }

  String _getDistanceText() {
    final distance = _calculateDistance();

    if (distance == 0) {
      return 'Distance: Calculating...';
    }

    // Format distance appropriately
    String distanceText;
    if (distance < 1) {
      // Show in meters for distances less than 1km
      final meters = (distance * 1000).round();
      distanceText = '${meters}m';
    } else {
      // Show in kilometers with 1 decimal place
      distanceText = '${distance.toStringAsFixed(1)} km';
    }

    // Add route type indicator
    if (_routeResult != null) {
      return 'Route: $distanceText';
    } else if (_routePoints.isNotEmpty) {
      return 'Route: $distanceText';
    } else {
      return 'Direct: $distanceText';
    }
  }

  IconData _getEmergencyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.emergency;
    }
  }
}
