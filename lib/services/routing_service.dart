import 'package:emergency_response_app/models/flutter_map_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';

  Future<FlutterMapRouteResult> getRoute(
    FlutterMapLatLng origin,
    FlutterMapLatLng destination,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return FlutterMapRouteResult.fromJson(data);
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  /// Get route with multiple waypoints
  Future<FlutterMapRouteResult> getRouteWithWaypoints(
    FlutterMapLatLng origin,
    FlutterMapLatLng destination,
    List<FlutterMapLatLng> waypoints,
  ) async {
    final coordinates = [
      origin,
      ...waypoints,
      destination,
    ].map((point) => '${point.longitude},${point.latitude}').join(';');

    final url = Uri.parse(
      '$_baseUrl/driving/$coordinates?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          return FlutterMapRouteResult.fromJson(data);
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }
}
