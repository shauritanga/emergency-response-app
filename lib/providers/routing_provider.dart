import 'package:emergency_response_app/services/routing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routingServiceProvider = Provider<RoutingService>((ref) {
  return RoutingService();
});
