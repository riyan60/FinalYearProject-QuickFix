import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Calculate distance between two points using Haversine formula (in km)
double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371; // km

  final double dLat = _toRadians(point2.latitude - point1.latitude);
  final double dLng = _toRadians(point2.longitude - point1.longitude);

  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(point1.latitude)) *
          math.cos(_toRadians(point2.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

/// Convert degrees to radians
double _toRadians(double degrees) {
  return degrees * (math.pi / 180.0);
}

/// Estimate ETA in minutes (assumed average speed 40 km/h for urban repairman)
int calculateETA(LatLng from, LatLng to) {
  final distanceKm = calculateDistance(from, to);
  final speedKmh = 40.0;
  final timeHours = distanceKm / speedKmh;
  final timeMinutes = (timeHours * 60).round();
  return timeMinutes.clamp(1, 120); // Min 1min, max 2h
}
