import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import '../../../models/booking_model.dart';
import '../../../core/utils/location_utils.dart';
import 'package:latlong2/latlong.dart' as latlong;

class TrackingScreen extends StatefulWidget {
  final String bookingId;
  final Booking booking;

  const TrackingScreen({
    super.key,
    required this.bookingId,
    required this.booking,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  latlong.LatLng? _userLocation;
  latlong.LatLng? _repairmanLocation;
  Timer? _pollTimer;
  String _statusText = 'Loading repairman location...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initMap();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initMap() async {
    if (widget.booking.userLatitude != null &&
        widget.booking.userLongitude != null) {
      _userLocation = latlong.LatLng(
        widget.booking.userLatitude!,
        widget.booking.userLongitude!,
      );
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchRepairmanLocation();
    });
    // Initial fetch
    _fetchRepairmanLocation();
  }

  Future<void> _fetchRepairmanLocation() async {
    try {
      final locationData = await LocationService.getRepairmanLocationByBooking(
        widget.bookingId,
      );
      final lat = double.tryParse(locationData['latitude'].toString());
      final lng = double.tryParse(locationData['longitude'].toString());
      if (lat != null && lng != null && mounted) {
        setState(() {
          _repairmanLocation = latlong.LatLng(lat, lng);
          _isLoading = false;
          if (_userLocation != null) {
            final distance = calculateDistance(
              _userLocation!,
              _repairmanLocation!,
            );
            final eta = calculateETA(_userLocation!, _repairmanLocation!);
            _statusText =
                '${distance.toStringAsFixed(1)} km away, ETA $eta min';
          } else {
            _statusText =
                'Repairman at ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          }
        });

        // Animate to show both
        if (_mapController != null &&
            _userLocation != null &&
            _repairmanLocation != null) {
          final southWestLat =
              math.min(_userLocation!.latitude, _repairmanLocation!.latitude) -
              0.01;
          final southWestLng =
              math.min(
                _userLocation!.longitude,
                _repairmanLocation!.longitude,
              ) -
              0.01;
          final northEastLat =
              math.max(_userLocation!.latitude, _repairmanLocation!.latitude) +
              0.01;
          final northEastLng =
              math.max(
                _userLocation!.longitude,
                _repairmanLocation!.longitude,
              ) +
              0.01;
          final bounds = LatLngBounds(
            southwest: LatLng(southWestLat, southWestLng),
            northeast: LatLng(northEastLat, northEastLng),
          );
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Repairman location unavailable: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Repairman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _userLocation?.latitude ?? 20.5937,
                _userLocation?.longitude ?? 78.9629,
              ),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: {
              if (_userLocation != null)
                Marker(
                  markerId: const MarkerId('user'),
                  position: LatLng(
                    _userLocation!.latitude,
                    _userLocation!.longitude,
                  ),
                  infoWindow: const InfoWindow(title: 'Your location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              if (_repairmanLocation != null)
                Marker(
                  markerId: const MarkerId('repairman'),
                  position: LatLng(
                    _repairmanLocation!.latitude,
                    _repairmanLocation!.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: 'Repairman (${widget.booking.status})',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
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
                      _isLoading ? Icons.hourglass_empty : Icons.directions_car,
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
