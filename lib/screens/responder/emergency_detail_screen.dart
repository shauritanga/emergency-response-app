import 'package:emergency_response_app/providers/emergency_provider.dart';
import 'package:emergency_response_app/providers/location_provider.dart';
import 'package:emergency_response_app/providers/routing_provider.dart';
import 'package:emergency_response_app/models/flutter_map_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:emergency_response_app/config/flutter_map_config.dart';
import '../../models/emergency.dart';
import '../../widgets/emergency_chat_widget.dart';
import '../../widgets/emergency_images_widget.dart';

class EmergencyDetailScreen extends ConsumerStatefulWidget {
  final Emergency emergency;
  final bool isResponder;

  const EmergencyDetailScreen({
    super.key,
    required this.emergency,
    required this.isResponder,
  });

  @override
  ConsumerState<EmergencyDetailScreen> createState() =>
      _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends ConsumerState<EmergencyDetailScreen> {
  MapController? mapController;
  FlutterMapLatLng? _userLocation;
  List<FlutterMapLatLng> _routePoints = [];
  String? _distance;
  String? _duration;
  String? _error;
  bool _isLoading = true;

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
      if (location == null) {
        setState(() {
          _error =
              'Unable to get current location. Showing emergency location only.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userLocation = FlutterMapLatLng(location.latitude!, location.longitude!);
      });

      // Get route from user's location to emergency
      final route = await ref
          .read(routingServiceProvider)
          .getRoute(
            _userLocation!,
            FlutterMapLatLng(widget.emergency.latitude, widget.emergency.longitude),
          );

      setState(() {
        _routePoints = route.points;
        _distance = route.distance;
        _duration = route.duration;
        _isLoading = false;
      });

      // Add markers and route to map
      await _addMarkersAndRoute();

      // Adjust map bounds to show both user and emergency locations
      if (mapController != null && _userLocation != null) {
        final emergencyLocation = FlutterMapLatLng(
          widget.emergency.latitude,
          widget.emergency.longitude,
        );
        final bounds = FlutterMapBounds.fromPoints(
          _userLocation!,
          emergencyLocation,
        );

        mapController?.move(bounds.center, 14.0);
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading route: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(MapController controller) {
    mapController = controller;

    // Add markers and route after map is created
    _addMarkersAndRoute();

    // Trigger map bounds update after map is created
    if (!_isLoading && _userLocation != null) {
      final emergencyLocation = FlutterMapLatLng(
        widget.emergency.latitude,
        widget.emergency.longitude,
      );
      final bounds = FlutterMapBounds.fromPoints(_userLocation!, emergencyLocation);

      controller.move(bounds.center, 14.0);
    }
  }

  Future<void> _addMarkersAndRoute() async {
    if (mapController == null) return;

    // Markers and routes will be handled by the widget tree in Flutter Map
  }

  @override
  Widget build(BuildContext context) {
    final emergencyLocation = FlutterMapLatLng(
      widget.emergency.latitude,
      widget.emergency.longitude,
    );

    return Scaffold(
      appBar: AppBar(title: Text('${widget.emergency.type} Emergency')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Map Section
                    SizedBox(
                      height: 300,
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          center: emergencyLocation,
                          zoom: 14.0,
                          onMapReady: () {
                            _onMapCreated(mapController!);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: FlutterMapConfig.openStreetMapUrl,
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(
                            markers: [
                              FlutterMapMarker(
                                id: 'emergency',
                                position: emergencyLocation,
                                title: '${widget.emergency.type} Emergency',
                                snippet: widget.emergency.description,
                              ).toMarker(),
                              if (_userLocation != null)
                                FlutterMapMarker(
                                  id: 'user_location',
                                  position: _userLocation!,
                                  title: 'Your Location',
                                ).toMarker(),
                            ],
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: emergencyLocation,
                                radius: 100, // 100 meters radius for emergency area
                                useRadiusInMeter: true,
                                color: Colors.red.withOpacity(0.3),
                                borderColor: Colors.red,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                FlutterMapPolyline(
                                  id: 'route',
                                  points: _routePoints,
                                  color: Colors.deepPurple,
                                  strokeWidth: 5.0,
                                ).toPolyline(),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Emergency Details Card
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text('Type: ${widget.emergency.type}'),
                            Text('Status: ${widget.emergency.status}'),
                            Text(
                              'Description: ${widget.emergency.description}',
                            ),
                            if (_distance != null && _duration != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Distance: $_distance',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Estimated Time: $_duration',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ),
                            if (widget.isResponder)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(emergencyServiceProvider)
                                          .updateEmergencyStatus(
                                            widget.emergency.id,
                                            widget.emergency.status == 'Pending'
                                                ? 'In Progress'
                                                : 'Resolved',
                                          );
                                    } catch (e) {
                                      setState(() {
                                        _error = 'Error updating status: $e';
                                      });
                                    }
                                  },
                                  child: Text(
                                    widget.emergency.status == 'Pending'
                                        ? 'Mark as In Progress'
                                        : 'Mark as Resolved',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Emergency Images Widget
                    widget.emergency.imageUrls.isNotEmpty
                        ? EmergencyImagesWidget(
                            imageUrls: widget.emergency.imageUrls,
                          )
                        : const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No images available for this emergency.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                    // Emergency Chat Widget
                    EmergencyChatWidget(emergencyId: widget.emergency.id),
                  ],
                ),
              ),
    );
  }
}
