import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/constants/api_constants.dart';

class GoogleRouteInfo {
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> polylinePoints;

  const GoogleRouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polylinePoints,
  });
}

class GoogleRouteService {
  static const String _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  static Future<GoogleRouteInfo> getDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(_directionsUrl).replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'departure_time': 'now',
        'traffic_model': 'best_guess',
        'key': ApiConstants.googleMapsApiKey,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Google Directions request failed');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status']?.toString();
    if (status != 'OK') {
      final message = body['error_message']?.toString();
      throw Exception(
        message == null ? 'Google Directions status: $status' : message,
      );
    }

    final routes = body['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) {
      throw Exception('No driving route found');
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>? ?? const [];
    if (legs.isEmpty) {
      throw Exception('No route legs found');
    }

    var distanceMeters = 0;
    var durationSeconds = 0;
    for (final item in legs) {
      final leg = item as Map<String, dynamic>;
      distanceMeters += (leg['distance']?['value'] as num?)?.round() ?? 0;
      durationSeconds +=
          (leg['duration_in_traffic']?['value'] as num?)?.round() ??
          (leg['duration']?['value'] as num?)?.round() ??
          0;
    }

    final points = _decodeRoutePoints(route);

    return GoogleRouteInfo(
      distanceKm: distanceMeters / 1000,
      durationMinutes: (durationSeconds / 60).round().clamp(1, 24 * 60),
      polylinePoints: points.isEmpty ? [origin, destination] : points,
    );
  }

  static List<LatLng> _decodeRoutePoints(Map<String, dynamic> route) {
    final points = <LatLng>[];
    final legs = route['legs'] as List<dynamic>? ?? const [];

    for (final legItem in legs) {
      final leg = legItem as Map<String, dynamic>;
      final steps = leg['steps'] as List<dynamic>? ?? const [];

      for (final stepItem in steps) {
        final step = stepItem as Map<String, dynamic>;
        final encoded = step['polyline']?['points']?.toString() ?? '';
        if (encoded.isEmpty) continue;

        final stepPoints = _decodePolyline(encoded);
        if (stepPoints.isEmpty) continue;

        if (points.isNotEmpty && stepPoints.isNotEmpty) {
          final previous = points.last;
          final next = stepPoints.first;
          if (previous.latitude == next.latitude &&
              previous.longitude == next.longitude) {
            stepPoints.removeAt(0);
          }
        }
        points.addAll(stepPoints);
      }
    }

    if (points.isNotEmpty) return points;

    final encodedPolyline =
        route['overview_polyline']?['points']?.toString() ?? '';
    return _decodePolyline(encodedPolyline);
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      final latResult = _decodeNextValue(encoded, index);
      index = latResult.nextIndex;
      lat += latResult.value;

      final lngResult = _decodeNextValue(encoded, index);
      index = lngResult.nextIndex;
      lng += lngResult.value;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  static _PolylineValue _decodeNextValue(String encoded, int startIndex) {
    var index = startIndex;
    var result = 0;
    var shift = 0;
    int byte;

    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);

    final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    return _PolylineValue(value, index);
  }
}

class _PolylineValue {
  final int value;
  final int nextIndex;

  const _PolylineValue(this.value, this.nextIndex);
}
