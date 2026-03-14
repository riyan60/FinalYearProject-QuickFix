import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  final latlng.LatLng? initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isFetchingLocation = false;
  bool _locationPermissionDenied = false;
  String _searchError = '';
  String _locationStatus = '';
  late LatLng _cameraStart;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;

  bool get _googleMapsSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    _cameraStart = LatLng(
      initial?.latitude ?? 20.5937,
      initial?.longitude ?? 78.9629,
    );
    if (initial != null) {
      _selectedLocation = LatLng(initial.latitude, initial.longitude);
    }
    if (_googleMapsSupported) {
      _initializeCurrentLocation();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationStatus = 'Fetching current location...';
      _locationPermissionDenied = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Enable device location services to use live location.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionDenied = true;
          _locationStatus = permission == LocationPermission.deniedForever
              ? 'Location permission is permanently denied.'
              : 'Location permission was denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() {
        _currentLocation = point;
        _cameraStart = point;
        _locationStatus =
            'Live location: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });

      await _moveTo(point);
      await _startLocationStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _startLocationStream() async {
    await _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = point;
        _locationStatus =
            'Live location: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
    });
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '8',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'QuickFix/1.0 (support@quickfix.local)'},
      );

      if (response.statusCode != 200) {
        throw Exception('Search failed (${response.statusCode})');
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        throw Exception('Invalid search response');
      }

      final items = decoded
          .map((item) => _SearchResult.fromJson(item))
          .whereType<_SearchResult>()
          .toList();

      setState(() {
        _searchResults = items;
      });
    } catch (_) {
      setState(() {
        _searchError = 'Search failed. Try another keyword.';
        _searchResults = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _moveTo(LatLng point) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 15)),
    );
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLocation = point;
      _searchResults = [];
      _searchError = '';
      _searchController.text = result.displayName;
    });
    _moveTo(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: _googleMapsSupported ? _buildMapLayout() : _buildUnsupportedState(),
      floatingActionButton: _googleMapsSupported
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'current_location',
                  onPressed: _isFetchingLocation ? null : _initializeCurrentLocation,
                  child: _isFetchingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'confirm_location',
                  onPressed: _selectedLocation == null
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            latlng.LatLng(
                              _selectedLocation!.latitude,
                              _selectedLocation!.longitude,
                            ),
                          );
                        },
                  child: const Icon(Icons.check),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildMapLayout() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _cameraStart, zoom: 14),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_currentLocation != null) {
              _moveTo(_currentLocation!);
            }
          },
          onTap: (position) {
            setState(() {
              _selectedLocation = position;
            });
          },
          myLocationEnabled: _currentLocation != null,
          myLocationButtonEnabled: _currentLocation != null,
          zoomControlsEnabled: false,
          markers: {
            if (_currentLocation != null)
              Marker(
                markerId: const MarkerId('current_location'),
                position: _currentLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                infoWindow: const InfoWindow(title: 'Your live location'),
              ),
            if (_selectedLocation != null)
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLocation!,
              ),
          },
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchPlaces(),
                          decoration: const InputDecoration(
                            hintText: 'Search place or address',
                            isDense: true,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSearching ? null : _searchPlaces,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
              ),
              if (_searchError.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _searchError,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              if (_searchResults.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSearchResult(result),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _selectedLocation == null
                        ? (_locationStatus.isNotEmpty
                              ? _locationStatus
                              : 'Tap on map to place marker')
                        : 'Selected: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                  ),
                ),
              ),
              if (_locationPermissionDenied)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Allow location permission to show your live device location.',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Google Maps picker is supported on Android, iOS, and Web in this project.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResult {
  final String displayName;
  final double latitude;
  final double longitude;

  _SearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  static _SearchResult? fromJson(dynamic jsonValue) {
    if (jsonValue is! Map) return null;
    final displayName = (jsonValue['display_name'] ?? '').toString();
    final lat = double.tryParse((jsonValue['lat'] ?? '').toString());
    final lon = double.tryParse((jsonValue['lon'] ?? '').toString());
    if (displayName.isEmpty || lat == null || lon == null) return null;
    return _SearchResult(
      displayName: displayName,
      latitude: lat,
      longitude: lon,
    );
  }
}

/*
Secondary OpenStreetMap implementation kept for future use.

Imports used before:
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Core widget used before:
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: LatLng(_cameraStart.latitude, _cameraStart.longitude),
    initialZoom: 14,
    onTap: (_, position) {
      setState(() {
        _selectedLocation = position;
      });
    },
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.quickfix_app',
    ),
    if (_selectedLocation != null)
      MarkerLayer(
        markers: [
          Marker(
            point: _selectedLocation!,
            width: 40,
            height: 40,
            child: const Icon(Icons.location_on, size: 40, color: Colors.red),
          ),
        ],
      ),
  ],
);
*/
