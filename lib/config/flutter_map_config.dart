import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Flutter Map configuration for the Emergency Response App
class FlutterMapConfig {
  // Street map sources (optimized for street visibility)
  static const String openStreetMapUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String cartoDBPositronUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String cartoDBVoyagerUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String googleMapsUrl =
      'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  static const String googleHybridUrl =
      'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';

  // Additional map styles
  static const String cartoDBDarkUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String openTopoMapUrl =
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';

  // Satellite imagery sources
  static const String esriSatelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String googleSatelliteUrl =
      'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
  static const String bingSatelliteUrl =
      'https://ecn.t3.tiles.virtualearth.net/tiles/a{q}.jpeg?g=1';

  // Fallback tile sources (use as alternatives)
  static const String stamenTerrainUrl =
      'https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}{r}.png';

  // Subdomains for tile servers that support them
  static const List<String> cartoDBSubdomains = ['a', 'b', 'c', 'd'];
  static const List<String> stamenSubdomains = ['a', 'b', 'c', 'd'];
  static const List<String> openTopoSubdomains = ['a', 'b', 'c'];

  // Default map settings
  static const double defaultZoom = 12.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 18.0;

  // Zanzibar coordinates (default center for the app)
  static const LatLng zanzibarCenter = LatLng(-6.1659, 39.2026);

  // Map bounds for Zanzibar region
  static const LatLng zanzibarSouthWest = LatLng(-6.5, 39.0);
  static const LatLng zanzibarNorthEast = LatLng(-5.8, 39.5);

  // Emergency marker settings
  static const double emergencyMarkerSize = 40.0;
  static const double responderMarkerSize = 35.0;
  static const double userMarkerSize = 30.0;

  // Route settings
  static const double routeWidth = 5.0;
  static const double routeOpacity = 0.8;

  // Animation settings
  static const Duration animationDuration = Duration(milliseconds: 500);

  // Tile attribution
  static const String openStreetMapAttribution = '© OpenStreetMap contributors';
  static const String cartoDBAttribution =
      '© OpenStreetMap contributors © CARTO';
  static const String stamenAttribution =
      'Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.';
  static const String openTopoAttribution =
      '© OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap (CC-BY-SA)';
  static const String esriSatelliteAttribution =
      'Tiles © Esri — Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community';
  static const String googleMapsAttribution = '© Google Maps';

  // Map styles enum
  static const String styleStreet = 'street';
  static const String styleSatellite = 'satellite';
  static const String styleTerrain = 'terrain';
  static const String styleDark = 'dark';
  static const String styleLight = 'light';

  /// Get tile URL for a specific style
  static String getTileUrl(String style) {
    switch (style) {
      case styleStreet:
        return googleMapsUrl; // Use Google Maps for excellent street visibility
      case styleSatellite:
        return esriSatelliteUrl; // Use ESRI satellite imagery
      case styleTerrain:
        return openTopoMapUrl; // OpenTopoMap is more reliable than Stamen
      case styleDark:
        return cartoDBDarkUrl;
      case styleLight:
        return cartoDBPositronUrl; // Use CartoDB Positron for light style
      default:
        return googleMapsUrl; // Default to Google Maps
    }
  }

  /// Get subdomains for a specific style
  static List<String>? getSubdomains(String style) {
    switch (style) {
      case styleStreet:
        return null; // OpenStreetMap doesn't use subdomains
      case styleDark:
      case styleLight:
        return cartoDBSubdomains;
      case styleSatellite:
        return null; // ESRI doesn't use subdomains
      case styleTerrain:
        return openTopoSubdomains; // OpenTopoMap subdomains
      default:
        return null; // Default to no subdomains
    }
  }

  /// Get attribution for a specific style
  static String getAttribution(String style) {
    switch (style) {
      case styleStreet:
        return googleMapsAttribution; // Google Maps attribution for street style
      case styleSatellite:
        return esriSatelliteAttribution; // ESRI satellite attribution
      case styleDark:
      case styleLight:
        return cartoDBAttribution;
      case styleTerrain:
        return openTopoAttribution; // OpenTopoMap attribution
      default:
        return googleMapsAttribution; // Default to Google Maps attribution
    }
  }

  /// Create a properly configured TileLayer with headers and error handling
  static TileLayer createTileLayer({String style = styleStreet}) {
    final url = getTileUrl(style);
    final subdomains = getSubdomains(style);

    return TileLayer(
      urlTemplate: url,
      subdomains: subdomains ?? [],
      userAgentPackageName: 'com.emergency.response.app',
      maxZoom: maxZoom,
      minZoom: minZoom,
      retinaMode: false, // Disable retina to reduce load
    );
  }

  /// Create a fallback tile layer for when primary fails
  static TileLayer createFallbackTileLayer() {
    return TileLayer(
      urlTemplate: cartoDBPositronUrl, // Use light CartoDB as fallback
      subdomains: cartoDBSubdomains,
      userAgentPackageName: 'com.emergency.response.app',
      maxZoom: maxZoom,
      minZoom: minZoom,
    );
  }
}

/// Map style options for the UI
class MapStyleOption {
  final String id;
  final String name;
  final String description;

  const MapStyleOption({
    required this.id,
    required this.name,
    required this.description,
  });
}

/// Available map styles
class MapStyles {
  static const List<MapStyleOption> available = [
    MapStyleOption(
      id: FlutterMapConfig.styleStreet,
      name: 'Street',
      description: 'Standard street map',
    ),
    MapStyleOption(
      id: FlutterMapConfig.styleSatellite,
      name: 'Satellite',
      description: 'Satellite imagery with labels',
    ),
    MapStyleOption(
      id: FlutterMapConfig.styleTerrain,
      name: 'Terrain',
      description: 'Topographic terrain map',
    ),
    MapStyleOption(
      id: FlutterMapConfig.styleDark,
      name: 'Dark',
      description: 'Dark theme map',
    ),
    MapStyleOption(
      id: FlutterMapConfig.styleLight,
      name: 'Light',
      description: 'Light theme map',
    ),
  ];
}
