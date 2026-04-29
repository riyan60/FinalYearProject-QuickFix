import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../core/utils/location_utils.dart';
import '../../services/google_route_service.dart';

class RepairmanPreviewMapScreen extends StatefulWidget {
  final String repairmanName;
  final latlong.LatLng userLocation;
  final latlong.LatLng repairmanLocation;

  const RepairmanPreviewMapScreen({
    super.key,
    required this.repairmanName,
    required this.userLocation,
    required this.repairmanLocation,
  });

  @override
  State<RepairmanPreviewMapScreen> createState() =>
      _RepairmanPreviewMapScreenState();
}

class _RepairmanPreviewMapScreenState extends State<RepairmanPreviewMapScreen> {
  GoogleMapController? _mapController;
  GoogleRouteInfo? _routeInfo;
  List<LatLng> _routePoints = const [];

  double get _distanceKm =>
      _routeInfo?.distanceKm ??
      calculateDistance(widget.userLocation, widget.repairmanLocation);

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final route = await GoogleRouteService.getDrivingRoute(
        origin: widget.repairmanLocation,
        destination: widget.userLocation,
      );
      if (!mounted) return;
      setState(() {
        _routeInfo = route;
        _routePoints = route.polylinePoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
      _fitBounds();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routePoints = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repairman on Map'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.userLocation.latitude,
                widget.userLocation.longitude,
              ),
              zoom: 13,
            ),
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
            markers: {
              Marker(
                markerId: const MarkerId('user'),
                position: LatLng(
                  widget.userLocation.latitude,
                  widget.userLocation.longitude,
                ),
                infoWindow: const InfoWindow(title: 'Your location'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
              Marker(
                markerId: const MarkerId('repairman'),
                position: LatLng(
                  widget.repairmanLocation.latitude,
                  widget.repairmanLocation.longitude,
                ),
                infoWindow: InfoWindow(title: widget.repairmanName),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            },
            polylines: {
              if (_routePoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('user_to_repairman_outline'),
                  points: _routePoints,
                  color: const Color(0xFF21127A),
                  width: 10,
                  zIndex: 1,
                ),
              if (_routePoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('user_to_repairman_fill'),
                  points: _routePoints,
                  color: const Color(0xFF5A31F4),
                  width: 6,
                  zIndex: 2,
                ),
            },
            myLocationEnabled: true,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.repairmanName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Distance: ${_routeInfo == null ? '~' : ''}'
                      '${_distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitBounds() {
    if (_mapController == null) return;

    final points = _routePoints.length >= 2
        ? _routePoints
        : [
            LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
            LatLng(
              widget.repairmanLocation.latitude,
              widget.repairmanLocation.longitude,
            ),
          ];

    var southWestLat = points.first.latitude;
    var southWestLng = points.first.longitude;
    var northEastLat = points.first.latitude;
    var northEastLng = points.first.longitude;

    for (final point in points.skip(1)) {
      southWestLat = math.min(southWestLat, point.latitude);
      southWestLng = math.min(southWestLng, point.longitude);
      northEastLat = math.max(northEastLat, point.latitude);
      northEastLng = math.max(northEastLng, point.longitude);
    }

    southWestLat -= 0.01;
    southWestLng -= 0.01;
    northEastLat += 0.01;
    northEastLng += 0.01;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(southWestLat, southWestLng),
          northeast: LatLng(northEastLat, northEastLng),
        ),
        80,
      ),
    );
  }
}
