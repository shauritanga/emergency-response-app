import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Flutter Map-specific coordinate model (using LatLng from latlong2)
typedef FlutterMapLatLng = LatLng;

/// Extension methods for LatLng to maintain compatibility
extension LatLngExtensions on LatLng {
  /// Convert to a more readable string format
  String toStringFormatted() => 'LatLng($latitude, $longitude)';
  
  /// Calculate distance to another point in meters
  double distanceTo(LatLng other) {
    return const Distance().as(LengthUnit.Meter, this, other);
  }
  
  /// Calculate bearing to another point in degrees
  double bearingTo(LatLng other) {
    return const Distance().bearing(this, other);
  }
}

/// Flutter Map route result model
class FlutterMapRouteResult {
  final List<LatLng> points;
  final String distance;
  final String duration;
  final double distanceMeters;
  final double durationSeconds;

  FlutterMapRouteResult({
    required this.points,
    required this.distance,
    required this.duration,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory FlutterMapRouteResult.fromJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    final geometry = route['geometry'];
    final distance = route['distance'];
    final duration = route['duration'];

    // Decode the geometry (LineString coordinates)
    final coordinates = geometry['coordinates'] as List;
    final points = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

    return FlutterMapRouteResult(
      points: points,
      distance: _formatDistance(distance),
      duration: _formatDuration(duration),
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
    );
  }

  static String _formatDistance(num meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String _formatDuration(num seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}

/// Flutter Map marker model
class FlutterMapMarker {
  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;
  final Widget? child;
  final double width;
  final double height;
  final Color? color;
  final IconData? icon;

  FlutterMapMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.child,
    this.width = 40.0,
    this.height = 40.0,
    this.color,
    this.icon,
  });

  /// Convert to flutter_map Marker
  Marker toMarker() {
    return Marker(
      point: position,
      width: width,
      height: height,
      child: child ?? _buildDefaultMarker(),
    );
  }

  Widget _buildDefaultMarker() {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon ?? Icons.location_on,
        color: Colors.white,
        size: width * 0.6,
      ),
    );
  }
}

/// Flutter Map bounds model
class FlutterMapBounds {
  final LatLng southWest;
  final LatLng northEast;

  FlutterMapBounds({required this.southWest, required this.northEast});

  /// Convert to flutter_map LatLngBounds
  LatLngBounds toLatLngBounds() {
    return LatLngBounds(southWest, northEast);
  }

  /// Create bounds from two points
  static FlutterMapBounds fromPoints(LatLng point1, LatLng point2) {
    final minLat = point1.latitude < point2.latitude ? point1.latitude : point2.latitude;
    final maxLat = point1.latitude > point2.latitude ? point1.latitude : point2.latitude;
    final minLng = point1.longitude < point2.longitude ? point1.longitude : point2.longitude;
    final maxLng = point1.longitude > point2.longitude ? point1.longitude : point2.longitude;

    return FlutterMapBounds(
      southWest: LatLng(minLat, minLng),
      northEast: LatLng(maxLat, maxLng),
    );
  }

  /// Create bounds from a list of points
  static FlutterMapBounds fromPointList(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return FlutterMapBounds(
      southWest: LatLng(minLat, minLng),
      northEast: LatLng(maxLat, maxLng),
    );
  }

  /// Get center point of bounds
  LatLng get center {
    final centerLat = (southWest.latitude + northEast.latitude) / 2;
    final centerLng = (southWest.longitude + northEast.longitude) / 2;
    return LatLng(centerLat, centerLng);
  }

  /// Check if bounds contains a point
  bool contains(LatLng point) {
    return point.latitude >= southWest.latitude &&
        point.latitude <= northEast.latitude &&
        point.longitude >= southWest.longitude &&
        point.longitude <= northEast.longitude;
  }
}

/// Flutter Map polyline model
class FlutterMapPolyline {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final List<Color>? gradientColors;

  FlutterMapPolyline({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.strokeWidth = 5.0,
    this.opacity = 1.0,
    this.gradientColors,
  });

  /// Convert to flutter_map Polyline
  Polyline toPolyline() {
    return Polyline(
      points: points,
      color: color.withOpacity(opacity),
      strokeWidth: strokeWidth,
      gradientColors: gradientColors,
    );
  }
}

/// Emergency marker types
enum EmergencyMarkerType {
  fire,
  medical,
  police,
  accident,
  flood,
  earthquake,
  other,
}

/// Emergency marker helper
class EmergencyMarkerHelper {
  static Color getColorForType(EmergencyMarkerType type) {
    switch (type) {
      case EmergencyMarkerType.fire:
        return Colors.red;
      case EmergencyMarkerType.medical:
        return Colors.green;
      case EmergencyMarkerType.police:
        return Colors.blue;
      case EmergencyMarkerType.accident:
        return Colors.orange;
      case EmergencyMarkerType.flood:
        return Colors.cyan;
      case EmergencyMarkerType.earthquake:
        return Colors.brown;
      case EmergencyMarkerType.other:
        return Colors.grey;
    }
  }

  static IconData getIconForType(EmergencyMarkerType type) {
    switch (type) {
      case EmergencyMarkerType.fire:
        return Icons.local_fire_department;
      case EmergencyMarkerType.medical:
        return Icons.medical_services;
      case EmergencyMarkerType.police:
        return Icons.local_police;
      case EmergencyMarkerType.accident:
        return Icons.car_crash;
      case EmergencyMarkerType.flood:
        return Icons.water;
      case EmergencyMarkerType.earthquake:
        return Icons.terrain;
      case EmergencyMarkerType.other:
        return Icons.warning;
    }
  }

  static FlutterMapMarker createEmergencyMarker({
    required String id,
    required LatLng position,
    required EmergencyMarkerType type,
    String? title,
    String? snippet,
    double size = 40.0,
  }) {
    return FlutterMapMarker(
      id: id,
      position: position,
      title: title,
      snippet: snippet,
      width: size,
      height: size,
      color: getColorForType(type),
      icon: getIconForType(type),
    );
  }
}
