import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../core/utils/location_utils.dart';

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

  double get _distanceKm => calculateDistance(
        widget.userLocation,
        widget.repairmanLocation,
      );

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
              Polyline(
                polylineId: const PolylineId('user_to_repairman'),
                points: [
                  LatLng(
                    widget.userLocation.latitude,
                    widget.userLocation.longitude,
                  ),
                  LatLng(
                    widget.repairmanLocation.latitude,
                    widget.repairmanLocation.longitude,
                  ),
                ],
                color: const Color(0xFF2E6BE6),
                width: 5,
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
                      'Distance: ${_distanceKm.toStringAsFixed(1)} km',
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

    final southWestLat = math.min(
          widget.userLocation.latitude,
          widget.repairmanLocation.latitude,
        ) -
        0.01;
    final southWestLng = math.min(
          widget.userLocation.longitude,
          widget.repairmanLocation.longitude,
        ) -
        0.01;
    final northEastLat = math.max(
          widget.userLocation.latitude,
          widget.repairmanLocation.latitude,
        ) +
        0.01;
    final northEastLng = math.max(
          widget.userLocation.longitude,
          widget.repairmanLocation.longitude,
        ) +
        0.01;

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
