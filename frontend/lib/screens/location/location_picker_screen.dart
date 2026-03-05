import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _cameraStart;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    _cameraStart = widget.initialLocation ?? const LatLng(20.5937, 78.9629);
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    } catch (e) {
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

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLocation = point;
      _searchResults = [];
      _searchError = '';
      _searchController.text = result.displayName;
    });
    _mapController.move(point, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _cameraStart,
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
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      separatorBuilder: (context, index) => const Divider(height: 1),
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
                          ? 'Tap on map to place marker'
                          : 'Selected: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedLocation == null
            ? null
            : () {
                Navigator.pop(context, _selectedLocation);
              },
        child: const Icon(Icons.check),
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
