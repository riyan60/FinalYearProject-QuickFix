import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../core/utils/location_utils.dart';
import '../../../models/booking_model.dart';

class RepairmanTrackingScreen extends StatefulWidget {
  final Booking booking;

  const RepairmanTrackingScreen({super.key, required this.booking});

  @override
  State<RepairmanTrackingScreen> createState() =>
      _RepairmanTrackingScreenState();
}

class _RepairmanTrackingScreenState extends State<RepairmanTrackingScreen> {
  GoogleMapController? _mapController;
  latlong.LatLng? _userLocation;
  latlong.LatLng? _repairmanLocation;
  Timer? _pollTimer;
  bool _isLoading = true;
  String _statusText = 'Loading user location...';

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _refreshLocations();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLocations(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _initUserLocation() {
    if (widget.booking.userLatitude != null &&
        widget.booking.userLongitude != null) {
      _userLocation = latlong.LatLng(
        widget.booking.userLatitude!,
        widget.booking.userLongitude!,
      );
    } else {
      _statusText = 'User location is not available for this booking.';
      _isLoading = false;
    }
  }

  Future<void> _refreshLocations() async {
    if (_userLocation == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentRepairmanLocation = latlong.LatLng(
        position.latitude,
        position.longitude,
      );
      final distanceKm = calculateDistance(
        currentRepairmanLocation,
        _userLocation!,
      );
      final etaMinutes = calculateETA(currentRepairmanLocation, _userLocation!);

      if (!mounted) return;
      setState(() {
        _repairmanLocation = currentRepairmanLocation;
        _isLoading = false;
        _statusText =
            '${distanceKm.toStringAsFixed(1)} km to user, ETA $etaMinutes min';
      });

      _fitCameraToPoints();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusText =
            'Unable to calculate live distance. Check location permission.';
      });
    }
  }

  void _fitCameraToPoints() {
    if (_mapController == null ||
        _userLocation == null ||
        _repairmanLocation == null) {
      return;
    }

    final southWestLat =
        math.min(_userLocation!.latitude, _repairmanLocation!.latitude) - 0.01;
    final southWestLng =
        math.min(_userLocation!.longitude, _repairmanLocation!.longitude) -
        0.01;
    final northEastLat =
        math.max(_userLocation!.latitude, _repairmanLocation!.latitude) + 0.01;
    final northEastLng =
        math.max(_userLocation!.longitude, _repairmanLocation!.longitude) +
        0.01;

    final bounds = LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = LatLng(
      _userLocation?.latitude ?? 20.5937,
      _userLocation?.longitude ?? 78.9629,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track User Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitCameraToPoints();
            },
            markers: {
              if (_userLocation != null)
                Marker(
                  markerId: const MarkerId('user'),
                  position: LatLng(
                    _userLocation!.latitude,
                    _userLocation!.longitude,
                  ),
                  infoWindow: const InfoWindow(title: 'User Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
              if (_repairmanLocation != null)
                Marker(
                  markerId: const MarkerId('repairman'),
                  position: LatLng(
                    _repairmanLocation!.latitude,
                    _repairmanLocation!.longitude,
                  ),
                  infoWindow: const InfoWindow(title: 'Your Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
            },
            myLocationEnabled: true,
          ),
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.directions,
                      size: 32,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.booking.status.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_statusText, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
