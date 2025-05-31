import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoutingService {
  // Replace with your Google Maps API key
  static const String _apiKey = 'AIzaSyDlOuo_7i3C1k1uvT73uxmarYjJ9Jps3Oc';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  Future<RouteResult> getRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      '$_baseUrl?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final polyline = route['overview_polyline']['points'];
          final points = _decodePolyline(polyline);
          return RouteResult(
            points: points,
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
          );
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}

class RouteResult {
  final List<LatLng> points;
  final String distance;
  final String duration;

  RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });
}
