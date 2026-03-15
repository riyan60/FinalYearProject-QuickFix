import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import '../../../../models/booking_model.dart';
import '../../../../core/utils/location_utils.dart';

class RepairmanTrackingScreen extends StatefulWidget {
  final Booking booking;

  const RepairmanTrackingScreen({super.key, required this.booking});

  @override
  State<RepairmanTrackingScreen> createState() =>
      _RepairmanTrackingScreenState();
}

class _RepairmanTrackingScreenState extends State<RepairmanTrackingScreen> {
  latlong.LatLng? _userLocation;
  latlong.LatLng? _repairmanLocation;
  Timer? _pollTimer;
  String _statusText = 'Loading locations...';

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _getCurrentRepairmanLocation();
    _startPolling();
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
    }
  }

  Future<void> _getCurrentRepairmanLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _repairmanLocation = latlong.LatLng(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      // Fallback or handle error
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateStatus();
    });
    _updateStatus();
  }

  Future<void> _updateStatus() async {
    if (_userLocation == null || _repairmanLocation == null) return;

    final distance = calculateDistance(_repairmanLocation!, _userLocation!);
    final eta = calculateETA(_repairmanLocation!, _userLocation!);

    setState(() {
      _statusText = '${distance.toStringAsFixed(1)} km to user, ETA $eta min';
    });
  }

  @override
  Widget build(BuildContext context) {
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
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 14,
            ),
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
                    const Icon(Icons.directions, size: 32, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      widget.booking.status.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_statusText),
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
