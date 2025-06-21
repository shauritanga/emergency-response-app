import 'package:emergency_response_app/providers/emergency_provider.dart';
import 'package:emergency_response_app/providers/location_provider.dart';
import 'package:emergency_response_app/providers/routing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/emergency.dart';
import '../../widgets/emergency_chat_widget.dart';

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
  GoogleMapController? mapController;
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
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
        _userLocation = LatLng(location.latitude!, location.longitude!);
      });

      // Get route from user's location to emergency
      final route = await ref
          .read(routingServiceProvider)
          .getRoute(
            _userLocation!,
            LatLng(widget.emergency.latitude, widget.emergency.longitude),
          );

      setState(() {
        _routePoints = route.points;
        _distance = route.distance;
        _duration = route.duration;
        _isLoading = false;
      });

      // Adjust map bounds to show both user and emergency locations
      if (mapController != null && _userLocation != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            _userLocation!.latitude < widget.emergency.latitude
                ? _userLocation!.latitude
                : widget.emergency.latitude,
            _userLocation!.longitude < widget.emergency.longitude
                ? _userLocation!.longitude
                : widget.emergency.longitude,
          ),
          northeast: LatLng(
            _userLocation!.latitude > widget.emergency.latitude
                ? _userLocation!.latitude
                : widget.emergency.latitude,
            _userLocation!.longitude > widget.emergency.longitude
                ? _userLocation!.longitude
                : widget.emergency.longitude,
          ),
        );
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50), // 50px padding
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading route: $e';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Trigger map bounds update after map is created
    if (!_isLoading && _userLocation != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _userLocation!.latitude < widget.emergency.latitude
              ? _userLocation!.latitude
              : widget.emergency.latitude,
          _userLocation!.longitude < widget.emergency.longitude
              ? _userLocation!.longitude
              : widget.emergency.longitude,
        ),
        northeast: LatLng(
          _userLocation!.latitude > widget.emergency.latitude
              ? _userLocation!.latitude
              : widget.emergency.latitude,
          _userLocation!.longitude > widget.emergency.longitude
              ? _userLocation!.longitude
              : widget.emergency.longitude,
        ),
      );
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyLatLng = LatLng(
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
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: emergencyLatLng,
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('emergency'),
                            position: emergencyLatLng,
                            infoWindow: InfoWindow(
                              title: '${widget.emergency.type} Emergency',
                              snippet: widget.emergency.description,
                            ),
                          ),
                          if (_userLocation != null)
                            Marker(
                              markerId: const MarkerId('user'),
                              position: _userLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Your Location',
                              ),
                            ),
                        },
                        polylines: {
                          if (_routePoints.isNotEmpty)
                            Polyline(
                              polylineId: const PolylineId('route'),
                              points: _routePoints,
                              color: Colors.blue,
                              width: 5,
                            ),
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
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
                                  style: const TextStyle(color: Colors.red),
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

                    // Emergency Chat Widget
                    EmergencyChatWidget(emergencyId: widget.emergency.id),
                  ],
                ),
              ),
    );
  }
}
