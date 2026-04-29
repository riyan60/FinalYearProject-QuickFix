import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../core/utils/location_utils.dart';
import '../../../models/booking_model.dart';
import '../../../services/google_route_service.dart';
import '../../../services/location_service.dart';

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
  bool _isFollowingCamera = true;
  bool _isProgrammaticCameraMove = false;
  bool _canShowRepairmanLocation = false;
  List<LatLng> _routePoints = const [];

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
      _statusText =
          'User location is not available for this booking. Ask the user to book again after selecting a map location.';
      _isLoading = false;
    }
  }

  Future<void> _refreshLocations() async {
    if (_userLocation == null) return;

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _canShowRepairmanLocation = false;
          _statusText =
              'Turn on location permission and GPS to track the user.';
        });
        return;
      }

      final currentRepairmanLocation = latlong.LatLng(
        position.latitude,
        position.longitude,
      );
      GoogleRouteInfo? route;
      try {
        route = await GoogleRouteService.getDrivingRoute(
          origin: currentRepairmanLocation,
          destination: _userLocation!,
        );
      } catch (_) {
        route = null;
      }

      if (!mounted) return;
      setState(() {
        _repairmanLocation = currentRepairmanLocation;
        _isLoading = false;
        _canShowRepairmanLocation = true;
        if (route != null) {
          _routePoints = route.polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          _statusText =
              '${route.distanceKm.toStringAsFixed(1)} km to user, ETA ${route.durationMinutes} min';
        } else {
          final distanceKm = calculateDistance(
            currentRepairmanLocation,
            _userLocation!,
          );
          final etaMinutes = calculateETA(
            currentRepairmanLocation,
            _userLocation!,
          );
          _routePoints = const [];
          _statusText =
              '~${distanceKm.toStringAsFixed(1)} km to user, ETA $etaMinutes min';
        }
      });

      if (_isFollowingCamera) {
        _fitCameraToPoints();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _canShowRepairmanLocation = false;
        _statusText =
            'Unable to track user location. Check location permission and Google Maps setup.';
      });
    }
  }

  Future<void> _fitCameraToPoints() async {
    if (_mapController == null || _userLocation == null) {
      return;
    }

    final points = _routePoints.length >= 2
        ? _routePoints
        : <LatLng>[
            LatLng(_userLocation!.latitude, _userLocation!.longitude),
            if (_repairmanLocation != null)
              LatLng(
                _repairmanLocation!.latitude,
                _repairmanLocation!.longitude,
              ),
          ];

    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

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

    final bounds = LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );

    _isProgrammaticCameraMove = true;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } finally {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _isProgrammaticCameraMove = false;
      });
    }
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
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onMapCreated: (controller) {
              _mapController = controller;
              _fitCameraToPoints();
            },
            onCameraMoveStarted: () {
              if (_isProgrammaticCameraMove || !_isFollowingCamera) return;
              setState(() {
                _isFollowingCamera = false;
              });
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
            polylines: {
              if (_routePoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('route_to_user_outline'),
                  points: _routePoints,
                  color: const Color(0xFF21127A),
                  width: 10,
                  zIndex: 1,
                ),
              if (_routePoints.length >= 2)
                Polyline(
                  polylineId: const PolylineId('route_to_user_fill'),
                  points: _routePoints,
                  color: const Color(0xFF5A31F4),
                  width: 6,
                  zIndex: 2,
                ),
            },
            myLocationEnabled: _canShowRepairmanLocation,
          ),
          if (!_isFollowingCamera)
            Positioned(
              right: 16,
              bottom: 20,
              child: FloatingActionButton.small(
                heroTag: 'repairman_tracking_recenter',
                onPressed: () {
                  setState(() {
                    _isFollowingCamera = true;
                  });
                  _fitCameraToPoints();
                },
                child: const Icon(Icons.my_location),
              ),
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
