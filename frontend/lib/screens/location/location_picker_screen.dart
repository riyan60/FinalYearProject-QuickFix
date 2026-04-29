import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

import '../../services/auth_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialLabel,
  });

  final latlng.LatLng? initialLocation;
  final String? initialLabel;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isFetchingLocation = false;
  bool _locationPermissionDenied = false;
  String _searchError = '';
  String _locationStatus = '';
  String _selectedLabel = '';
  bool _preferSelectedLocation = false;
  late LatLng _cameraStart;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  Timer? _searchDebounce;
  int _activeSearchRequestId = 0;
  bool _hasSearched = false;

  bool get _googleMapsSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final sessionLatitude = double.tryParse('${session['latitude'] ?? ''}');
    final sessionLongitude = double.tryParse('${session['longitude'] ?? ''}');
    final fallbackInitial = sessionLatitude != null && sessionLongitude != null
        ? latlng.LatLng(sessionLatitude, sessionLongitude)
        : null;
    final initial = widget.initialLocation ?? fallbackInitial;
    final fallbackLabel = (session['city'] ?? '').toString().trim();
    _cameraStart = LatLng(
      initial?.latitude ?? 20.5937,
      initial?.longitude ?? 78.9629,
    );
    if (initial != null) {
      _selectedLocation = LatLng(initial.latitude, initial.longitude);
      _preferSelectedLocation = true;
      _selectedLabel = (widget.initialLabel ?? fallbackLabel).trim();
      if (_selectedLabel.isNotEmpty) {
        _locationStatus = 'Selected: $_selectedLabel';
      }
    }
    if (_googleMapsSupported) {
      _initializeCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      if (_selectedLocation == null) {
        _locationStatus = 'Fetching current location...';
      }
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
          if (_selectedLocation == null) {
            _locationStatus = permission == LocationPermission.deniedForever
                ? 'Location permission is permanently denied.'
                : 'Location permission was denied.';
          }
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
        if (!_preferSelectedLocation) {
          _cameraStart = point;
          _selectedLocation = point;
          _selectedLabel = 'Current location';
          _locationStatus =
              'Live location: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        }
      });

      if (!_preferSelectedLocation) {
        await _moveTo(point);
      }
      await _startLocationStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_selectedLocation == null) {
          _locationStatus = e.toString().replaceFirst('Exception: ', '');
        }
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
        if (!_preferSelectedLocation) {
          _selectedLocation = point;
          _selectedLabel = 'Current location';
          _locationStatus =
              'Live location: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        }
      });
    });
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _activeSearchRequestId++;
      setState(() {
        _searchResults = [];
        _searchError = '';
        _hasSearched = false;
      });
      return;
    }

    if (query.length < 2) {
      _activeSearchRequestId++;
      setState(() {
        _searchResults = [];
        _searchError = 'Type at least 2 characters to search.';
        _hasSearched = false;
      });
      return;
    }

    final requestId = ++_activeSearchRequestId;

    setState(() {
      _isSearching = true;
      _searchError = '';
      _hasSearched = false;
    });

    try {
      List<_SearchResult> items = const [];

      try {
        items = await _searchWithNominatim(query);
      } catch (_) {
        // Ignore and try fallback provider below.
      }

      if (items.isEmpty) {
        items = await _searchWithMapsCo(query);
      }

      setState(() {
        _searchResults = items;
        _hasSearched = true;
        if (items.isEmpty) {
          _searchError = 'No places found. Try a broader keyword.';
        }
      });
    } on TimeoutException {
      if (!mounted || requestId != _activeSearchRequestId) return;
      setState(() {
        _searchError = 'Search timed out. Check your connection and retry.';
        _searchResults = [];
        _hasSearched = true;
      });
    } catch (error) {
      if (!mounted || requestId != _activeSearchRequestId) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() {
        _searchError = message.isEmpty
            ? 'Search failed. Try another keyword.'
            : message;
        _searchResults = [];
        _hasSearched = true;
      });
    } finally {
      if (mounted && requestId == _activeSearchRequestId) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      _activeSearchRequestId++;
      setState(() {
        _searchResults = [];
        _searchError = '';
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 450), _searchPlaces);
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _activeSearchRequestId++;
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _searchError = '';
      _isSearching = false;
      _hasSearched = false;
    });
  }

  Future<List<_SearchResult>> _searchWithNominatim(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'countrycodes': 'in',
    });
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!kIsWeb) {
      headers['User-Agent'] = 'QuickFixApp/1.0 (support@quickfix.app)';
      headers['Accept-Language'] = 'en';
    }

    final response = await http.get(uri, headers: headers).timeout(
      const Duration(seconds: 12),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Search failed (${response.statusCode}). Please try again.',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid search response');
    }

    return decoded
        .map((item) => _SearchResult.fromJson(item))
        .whereType<_SearchResult>()
        .toList();
  }

  Future<List<_SearchResult>> _searchWithMapsCo(String query) async {
    final uri = Uri.https('geocode.maps.co', '/search', {
      'q': query,
      'country': 'IN',
    });
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
        'Search service unavailable (${response.statusCode}). Please try again.',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid fallback search response');
    }

    return decoded
        .map((item) => _SearchResult.fromJson(item))
        .whereType<_SearchResult>()
        .take(8)
        .toList();
  }

  Future<void> _moveTo(LatLng point) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 15)),
    );
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _preferSelectedLocation = true;
      _selectedLocation = point;
      _selectedLabel = result.displayName;
      _locationStatus = 'Selected: ${result.displayName}';
      _searchResults = [];
      _searchError = '';
      _searchController.text = result.displayName;
    });
    _searchFocusNode.unfocus();
    _moveTo(point);
  }

  Widget _buildSearchBar() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      shadowColor: Colors.black.withAlpha(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? const Color(0xFF2E6BE6)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFF2E6BE6)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _searchPlaces(),
                decoration: const InputDecoration(
                  hintText: 'Search by place, area, or address',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.trim().isNotEmpty && !_isSearching)
              IconButton(
                tooltip: 'Clear search',
                onPressed: _clearSearch,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF6B7280),
                ),
              )
            else if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              )
            else
              IconButton(
                tooltip: 'Search',
                onPressed: _searchPlaces,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsCard() {
    final hasQuery = _searchController.text.trim().isNotEmpty;
    final shouldShowCard =
        _searchError.isNotEmpty ||
        _searchResults.isNotEmpty ||
        (hasQuery && (_isSearching || (_hasSearched && _searchResults.isEmpty)));

    if (!shouldShowCard) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchError.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                color: Colors.red.shade50,
                child: Text(
                  _searchError,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              )
            else if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Searching locations...',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              )
            else if (_searchResults.isEmpty && hasQuery)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_searching, color: Color(0xFF6B7280)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No places found. Try a broader keyword.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 14, endIndent: 14),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const Icon(
                        Icons.place_outlined,
                        color: Color(0xFF2E6BE6),
                      ),
                      title: Text(
                        result.primaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: result.secondaryText.isEmpty
                          ? null
                          : Text(
                              result.secondaryText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      onTap: () => _selectSearchResult(result),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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
                  onPressed: _isFetchingLocation
                      ? null
                      : () {
                          setState(() {
                            _preferSelectedLocation = false;
                          });
                          _initializeCurrentLocation();
                        },
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
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
            if (_selectedLocation != null) {
              _moveTo(_selectedLocation!);
            } else if (_currentLocation != null) {
              _moveTo(_currentLocation!);
            }
          },
          onTap: (position) {
            setState(() {
              _preferSelectedLocation = true;
              _selectedLocation = position;
              _selectedLabel = '';
              _locationStatus =
                  'Selected: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
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
              _buildSearchBar(),
              _buildSearchResultsCard(),
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
                        : _selectedLabel.isNotEmpty
                        ? 'Selected: $_selectedLabel'
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
                  child: Text(
                    _selectedLocation != null
                        ? 'Live location permission is denied. Showing your saved pinned location instead.'
                        : 'Allow location permission to show your live device location.',
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

  String get primaryText =>
      displayName.split(',').firstWhere((part) => part.trim().isNotEmpty, orElse: () => displayName).trim();

  String get secondaryText {
    final parts = displayName
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length <= 1) return '';
    return parts.skip(1).join(', ');
  }

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
