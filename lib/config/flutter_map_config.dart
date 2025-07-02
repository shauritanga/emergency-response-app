import 'package:latlong2/latlong.dart';

/// Flutter Map configuration for the Emergency Response App
class FlutterMapConfig {
  // Tile source URLs (no API keys required!)
  static const String openStreetMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String cartoDBUrl = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  static const String cartoDBDarkUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String cartoDBLightUrl = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String stamenTerrainUrl = 'https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}{r}.png';
  static const String openTopoMapUrl = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  
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
  static const String cartoDBAttribution = '© OpenStreetMap contributors © CARTO';
  static const String stamenAttribution = 'Map tiles by Stamen Design, under CC BY 3.0. Data by OpenStreetMap, under ODbL.';
  static const String openTopoAttribution = '© OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap (CC-BY-SA)';
  
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
        return openStreetMapUrl;
      case styleSatellite:
        return cartoDBUrl;
      case styleTerrain:
        return stamenTerrainUrl;
      case styleDark:
        return cartoDBDarkUrl;
      case styleLight:
        return cartoDBLightUrl;
      default:
        return openStreetMapUrl;
    }
  }
  
  /// Get subdomains for a specific style
  static List<String>? getSubdomains(String style) {
    switch (style) {
      case styleSatellite:
      case styleDark:
      case styleLight:
        return cartoDBSubdomains;
      case styleTerrain:
        return stamenSubdomains;
      default:
        return null;
    }
  }
  
  /// Get attribution for a specific style
  static String getAttribution(String style) {
    switch (style) {
      case styleStreet:
        return openStreetMapAttribution;
      case styleSatellite:
      case styleDark:
      case styleLight:
        return cartoDBAttribution;
      case styleTerrain:
        return stamenAttribution;
      default:
        return openStreetMapAttribution;
    }
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
