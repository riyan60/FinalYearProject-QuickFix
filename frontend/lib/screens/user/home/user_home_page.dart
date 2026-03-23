import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:provider/provider.dart';

import '../../../services/auth_service.dart';
import '../../../core/utils/location_utils.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../services/user/service_catalog_service.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../location/location_picker_screen.dart';
import '../../profile/repairman_profile_page.dart';
import '../booking/emergency_service_booking_page.dart';
import '../cart/cart_page.dart';
import '../history/booking_history_page.dart';
import '../profile/user_profile_page.dart';
import '../services/dynamic_service_list_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final AuthService _authService = AuthService();
  final ServiceCatalogService _serviceCatalogService = ServiceCatalogService();
  final RepairmanService _repairmanService = RepairmanService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _selectedLocationLabel = 'Choose your location';
  latlng.LatLng? _selectedLocation;
  latlng.LatLng? _savedSignupLocation;
  String _savedCity = '';
  String _displayName = 'QuickFix User';
  _LocationSource _selectedLocationSource = _LocationSource.signup;
  _RepairmanFilterMode _repairmanFilterMode = _RepairmanFilterMode.all;
  String? _selectedSpecialtyFilter;
  final GlobalKey _locationMenuKey = GlobalKey();

  late final Future<List<ServiceCategoryView>> _serviceCategoriesFuture =
      _loadServiceCategories();
  late final Future<List<dynamic>> _repairmenFuture = _repairmanService
      .getRepairmanList();

  static const List<ServiceCategoryView> _fallbackCategories = [
    ServiceCategoryView(
      label: 'Mechanic',
      subtitle: 'Professional car repair services',
      icon: Icons.directions_car,
    ),
    ServiceCategoryView(
      label: 'Carpenter',
      subtitle: 'Professional carpentry services',
      icon: Icons.handyman,
    ),
    ServiceCategoryView(
      label: 'AC Repair',
      subtitle: 'Professional AC cooling services',
      icon: Icons.ac_unit,
    ),
    ServiceCategoryView(
      label: 'Electrician',
      subtitle: 'Professional electrical services',
      icon: Icons.bolt,
    ),
    ServiceCategoryView(
      label: 'Plumber',
      subtitle: 'Professional plumbing services',
      icon: Icons.water_drop,
    ),
    ServiceCategoryView(
      label: 'Cleaning',
      subtitle: 'Professional cleaning services',
      icon: Icons.cleaning_services,
    ),
  ];

  static const Map<String, ServiceCategoryView> _categoryByKey = {
    'mechanic': ServiceCategoryView(
      label: 'Mechanic',
      subtitle: 'Professional car repair services',
      icon: Icons.directions_car,
    ),
    'carpenter': ServiceCategoryView(
      label: 'Carpenter',
      subtitle: 'Professional carpentry services',
      icon: Icons.handyman,
    ),
    'ac repair': ServiceCategoryView(
      label: 'AC Repair',
      subtitle: 'Professional AC cooling services',
      icon: Icons.ac_unit,
    ),
    'electrician': ServiceCategoryView(
      label: 'Electrician',
      subtitle: 'Professional electrical services',
      icon: Icons.bolt,
    ),
    'plumber': ServiceCategoryView(
      label: 'Plumber',
      subtitle: 'Professional plumbing services',
      icon: Icons.water_drop,
    ),
    'cleaning': ServiceCategoryView(
      label: 'Cleaning',
      subtitle: 'Professional cleaning services',
      icon: Icons.cleaning_services,
    ),
  };

  static const Map<String, List<String>> _categoryKeywords = {
    'ac repair': ['ac', 'refrigerant', 'compressor', 'coil', 'cooling'],
    'electrician': ['electric', 'wiring', 'circuit', 'fan', 'light'],
    'plumber': ['plumb', 'pipe', 'leak', 'drain', 'tap', 'bathroom'],
    'carpenter': ['carpenter', 'furniture', 'wood', 'shelf', 'door'],
    'mechanic': ['mechanic', 'engine', 'oil', 'brake', 'battery', 'tire'],
    'cleaning': ['clean', 'carpet', 'window', 'office', 'renovation'],
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _restoreSignupLocation();
    _loadCurrentProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().sync();
    });
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _restoreSignupLocation() {
    final session = AuthService.currentSession ?? <String, dynamic>{};
    final name =
        (session['name'] ?? session['username'] ?? session['identity'] ?? '')
            .toString()
            .trim();
    final city = (session['city'] ?? '').toString().trim();
    final latitude = double.tryParse('${session['latitude'] ?? ''}');
    final longitude = double.tryParse('${session['longitude'] ?? ''}');

    if (latitude != null && longitude != null) {
      final savedLocation = latlng.LatLng(latitude, longitude);
      _savedSignupLocation = savedLocation;
    } else if (city.isNotEmpty) {
      _selectedLocationLabel = city;
    }

    _savedCity = city;
    if (name.isNotEmpty) {
      _displayName = name;
    }

    final selectedLatitude = double.tryParse('${session['selected_latitude'] ?? ''}');
    final selectedLongitude = double.tryParse(
      '${session['selected_longitude'] ?? ''}',
    );
    final selectedLabel = (session['selected_location_label'] ?? '')
        .toString()
        .trim();
    final selectedSource = (session['selected_location_source'] ?? 'signup')
        .toString()
        .trim()
        .toLowerCase();

    if (selectedLatitude != null && selectedLongitude != null) {
      _selectedLocation = latlng.LatLng(selectedLatitude, selectedLongitude);
      _selectedLocationSource = selectedSource == 'live'
          ? _LocationSource.live
          : _LocationSource.signup;
      _selectedLocationLabel = selectedLabel.isNotEmpty
          ? selectedLabel
          : (_selectedLocationSource == _LocationSource.signup
                ? (_savedCity.isNotEmpty ? _savedCity : 'Signup location')
                : 'Selected location');
    } else if (_savedSignupLocation != null) {
      _selectedLocation = _savedSignupLocation;
      _selectedLocationSource = _LocationSource.signup;
      _selectedLocationLabel = city.isNotEmpty ? city : 'Signup location';
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      await _authService.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _restoreSignupLocation();
      });
      await _hydrateSignupCityLabel();
    } catch (_) {
      // Keep existing session data if profile fetch is unavailable.
      await _hydrateSignupCityLabel();
    }
  }

  Future<void> _hydrateSignupCityLabel() async {
    if (_savedCity.isNotEmpty || _savedSignupLocation == null) return;

    final resolvedCity = await _reverseGeocodeCity(_savedSignupLocation!);
    if (!mounted || resolvedCity == null || resolvedCity.isEmpty) return;

    setState(() {
      _savedCity = resolvedCity;
      if (_selectedLocationSource == _LocationSource.signup) {
        _selectedLocationLabel = resolvedCity;
      }
    });
  }

  Future<String?> _reverseGeocodeCity(latlng.LatLng point) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'QuickFix/1.0 (support@quickfix.local)'},
      );

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;

      final address = decoded['address'];
      if (address is! Map) return null;

      final city =
          (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['municipality'] ??
                  '')
              .toString()
              .trim();
      final state = (address['state'] ?? '').toString().trim();

      if (city.isEmpty && state.isEmpty) return null;
      if (city.isEmpty) return state;
      if (state.isEmpty) return city;
      return '$city, $state';
    } catch (_) {
      return null;
    }
  }

  Future<List<ServiceCategoryView>> _loadServiceCategories() async {
    try {
      final services = await _serviceCatalogService.getAllServices();
      final detected = <String>{};

      for (final service in services) {
        final rawCategory = service.category.trim().toLowerCase();
        if (_categoryByKey.containsKey(rawCategory)) {
          detected.add(rawCategory);
          continue;
        }

        final haystack = '${service.name} ${service.description}'.toLowerCase();
        for (final entry in _categoryKeywords.entries) {
          if (entry.value.any(haystack.contains)) {
            detected.add(entry.key);
          }
        }
      }

      if (detected.isEmpty) {
        return _fallbackCategories;
      }

      return detected
          .map((key) => _categoryByKey[key])
          .whereType<ServiceCategoryView>()
          .toList();
    } catch (_) {
      return _fallbackCategories;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  String _normalizeSpecialty(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('electric')) return 'Electrician';
    if (normalized.contains('plumb')) return 'Plumber';
    if (normalized.contains('carpent')) return 'Carpenter';
    if (normalized.contains('mechanic')) return 'Mechanic';
    if (normalized.contains('clean')) return 'Cleaning';
    if (normalized.contains('ac')) return 'AC Repair';
    return normalized.isEmpty
        ? 'General Repair'
        : normalized
              .split(' ')
              .map(
                (part) => part.isEmpty
                    ? part
                    : '${part[0].toUpperCase()}${part.substring(1)}',
              )
              .join(' ');
  }

  double _repairmanRating(Map<String, dynamic> data) {
    final ratingValue = data['rating'];
    if (ratingValue is num) {
      return ratingValue.toDouble();
    }
    return double.tryParse('$ratingValue') ?? 0.0;
  }

  String _repairmanSpecialty(Map<String, dynamic> data) {
    final skills = data['skills'];
    if (skills is List && skills.isNotEmpty) {
      return _normalizeSpecialty('${skills.first}');
    }

    return _normalizeSpecialty(
      (data['specialization'] ?? data['category'] ?? 'General repair')
          .toString(),
    );
  }

  List<String> _specialtyOptions(List<dynamic> repairmen) {
    final groupedBestRatings = <String, double>{};

    for (final repairman in repairmen.whereType<Map>()) {
      final data = Map<String, dynamic>.from(repairman);
      final specialty = _repairmanSpecialty(data);
      final rating = _repairmanRating(data);
      final currentBest = groupedBestRatings[specialty];
      if (currentBest == null || rating > currentBest) {
        groupedBestRatings[specialty] = rating;
      }
    }

    final specialties = groupedBestRatings.keys.toList();
    specialties.sort((a, b) {
      final ratingCompare =
          (groupedBestRatings[b] ?? 0).compareTo(groupedBestRatings[a] ?? 0);
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return a.compareTo(b);
    });
    return specialties;
  }

  List<ServiceCategoryView> _filterCategories(
    List<ServiceCategoryView> categories,
  ) {
    final query = _searchQuery;
    if (query.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      final haystack =
          '${category.label} ${category.subtitle}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<dynamic> _filterRepairmen(List<dynamic> repairmen) {
    final query = _searchQuery;
    final selectedCityLabel = _selectedLocationLabel.trim().toLowerCase();
    final selectedCityToken = selectedCityLabel.split(',').first.trim();
    final filtered = repairmen.where((repairman) {
      if (repairman is! Map) {
        return false;
      }

      final data = Map<String, dynamic>.from(repairman);
      final haystack =
          '${data['name'] ?? ''} '
          '${data['specialization'] ?? ''} '
          '${data['category'] ?? ''} '
          '${data['city'] ?? ''} '
          '${data['address'] ?? ''}'.toLowerCase();

      if (query.isNotEmpty && !haystack.contains(query)) {
        return false;
      }

      if (_repairmanFilterMode == _RepairmanFilterMode.location) {
        final city = (data['city'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        final matchesCity =
            selectedCityToken.isNotEmpty &&
            (city.contains(selectedCityToken) ||
                address.contains(selectedCityToken));

        if (!matchesCity && _selectedLocation != null) {
          final lat = double.tryParse('${data['latitude'] ?? ''}');
          final lng = double.tryParse('${data['longitude'] ?? ''}');
          if (lat == null || lng == null) {
            return false;
          }

          final distance = calculateDistance(
            _selectedLocation!,
            latlng.LatLng(lat, lng),
          );
          return distance <= 25;
        }

        return matchesCity;
      }

      if (_repairmanFilterMode == _RepairmanFilterMode.specialty) {
        final specialty = _repairmanSpecialty(data);
        return _selectedSpecialtyFilter == null ||
            specialty == _selectedSpecialtyFilter;
      }

      return true;
    }).map((repairman) {
      final data = Map<String, dynamic>.from(repairman as Map);
      data.remove('is_best_repairman');
      return data;
    }).toList();

    filtered.sort((a, b) {
      final ratingCompare = _repairmanRating(b).compareTo(_repairmanRating(a));
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
    });

    if (_repairmanFilterMode != _RepairmanFilterMode.best) {
      return filtered;
    }

    final bestBySpecialty = <String, Map<String, dynamic>>{};
    for (final repairman in filtered) {
      final specialty = _repairmanSpecialty(repairman);
      final current = bestBySpecialty[specialty];
      if (current == null ||
          _repairmanRating(repairman) > _repairmanRating(current)) {
        bestBySpecialty[specialty] = repairman;
      }
    }

    final bestRepairmen = bestBySpecialty.values.toList();
    bestRepairmen.sort((a, b) {
      final ratingCompare = _repairmanRating(b).compareTo(_repairmanRating(a));
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return _repairmanSpecialty(a).compareTo(_repairmanSpecialty(b));
    });
    return bestRepairmen.take(6).map((repairman) {
      return {
        ...repairman,
        'is_best_repairman': true,
      };
    }).toList();
  }

  Future<void> _openRepairmanFilters(List<dynamic> repairmen) async {
    final specialties = _specialtyOptions(repairmen);
    final selectedCityToken = _selectedLocationLabel
        .trim()
        .toLowerCase()
        .split(',')
        .first
        .trim();
    final selected = await showModalBottomSheet<_RepairmanFilterSelection>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        _RepairmanFilterMode tempMode = _repairmanFilterMode;
        String? tempSpecialty = _selectedSpecialtyFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Repairmen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<_RepairmanFilterMode>(
                      value: _RepairmanFilterMode.all,
                      groupValue: tempMode,
                      title: const Text('All repairmen'),
                      onChanged: (value) {
                        setModalState(() {
                          tempMode = value!;
                          tempSpecialty = null;
                        });
                      },
                    ),
                    RadioListTile<_RepairmanFilterMode>(
                      value: _RepairmanFilterMode.location,
                      groupValue: tempMode,
                      title: Text(
                        selectedCityToken.isNotEmpty
                            ? 'Near $selectedCityToken'
                            : 'Near selected location',
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          tempMode = value!;
                          tempSpecialty = null;
                        });
                      },
                    ),
                    RadioListTile<_RepairmanFilterMode>(
                      value: _RepairmanFilterMode.specialty,
                      groupValue: tempMode,
                      title: const Text('By specialty / skill'),
                      onChanged: (value) {
                        setModalState(() {
                          tempMode = value!;
                          tempSpecialty ??= specialties.isNotEmpty
                              ? specialties.first
                              : null;
                        });
                      },
                    ),
                    if (tempMode == _RepairmanFilterMode.specialty &&
                        specialties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: tempSpecialty,
                          decoration: const InputDecoration(
                            labelText: 'Specialty',
                            border: OutlineInputBorder(),
                          ),
                          items: specialties
                              .map(
                                (specialty) => DropdownMenuItem<String>(
                                  value: specialty,
                                  child: Text(specialty),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() {
                              tempSpecialty = value;
                            });
                          },
                        ),
                      ),
                    RadioListTile<_RepairmanFilterMode>(
                      value: _RepairmanFilterMode.best,
                      groupValue: tempMode,
                      title: const Text('Best repairmen'),
                      subtitle: const Text(
                        'Top-rated repairman from 6 different specialties',
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          tempMode = value!;
                          tempSpecialty = null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _RepairmanFilterSelection(
                              mode: tempMode,
                              specialty: tempSpecialty,
                            ),
                          );
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _repairmanFilterMode = selected.mode;
      _selectedSpecialtyFilter =
          selected.mode == _RepairmanFilterMode.specialty
          ? selected.specialty
          : null;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            userData: AuthService.currentSession ?? const {},
          ),
        ),
      );
    }
  }

  Future<void> _selectLocationSource(_LocationSource source) async {
    if (source == _LocationSource.signup) {
      setState(() {
        _selectedLocationSource = _LocationSource.signup;
        _selectedLocation = _savedSignupLocation;
        _selectedLocationLabel = _savedCity.isNotEmpty
            ? _savedCity
            : 'Signup location unavailable';
      });
      await AuthService.updateSessionData({
        'selected_location_source': 'signup',
        'selected_location_label': _selectedLocationLabel,
        if (_selectedLocation != null) 'selected_latitude': _selectedLocation!.latitude,
        if (_selectedLocation != null) 'selected_longitude': _selectedLocation!.longitude,
      });
      await _openMapForSelectedLocation();
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Enable device location services to use live location.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _selectedLocationSource = _LocationSource.live;
        _selectedLocation = latlng.LatLng(
          position.latitude,
          position.longitude,
        );
        _selectedLocationLabel = 'Current location';
      });
      await AuthService.updateSessionData({
        'selected_location_source': 'live',
        'selected_location_label': _selectedLocationLabel,
        'selected_latitude': position.latitude,
        'selected_longitude': position.longitude,
      });
      await _openMapForSelectedLocation();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMapForSelectedLocation() async {
    final current = _selectedLocation;
    if (current == null || !mounted) return;

    final result = await Navigator.push<latlng.LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: current,
          initialLabel: _selectedLocationSource == _LocationSource.signup
              ? _savedCity
              : _selectedLocationLabel,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final resolvedCity = await _reverseGeocodeCity(result);
    final shouldRepairSignupLocation =
        _selectedLocationSource == _LocationSource.signup &&
        ((_savedCity.trim().isEmpty) || _savedSignupLocation == null);

    if (shouldRepairSignupLocation) {
      try {
        await _authService.updateCurrentProfile({
          'city': resolvedCity ?? _savedCity,
          'latitude': result.latitude,
          'longitude': result.longitude,
        });
      } catch (_) {
        // Keep local state even if profile sync fails.
      }
    }

    setState(() {
      _selectedLocation = result;
      if (_selectedLocationSource == _LocationSource.signup) {
        if ((resolvedCity ?? '').trim().isNotEmpty) {
          _savedCity = resolvedCity!.trim();
        }
        _savedSignupLocation = result;
        _selectedLocationLabel = _savedCity.isNotEmpty
            ? _savedCity
            : 'Saved city';
      } else {
        _selectedLocationLabel = (resolvedCity ?? '').trim().isNotEmpty
            ? resolvedCity!.trim()
            : 'Selected location';
      }
    });

    await AuthService.updateSessionData({
      'selected_location_source':
          _selectedLocationSource == _LocationSource.live ? 'live' : 'signup',
      'selected_location_label': _selectedLocationLabel,
      'selected_latitude': result.latitude,
      'selected_longitude': result.longitude,
    });
  }

  Future<void> openLocationMenu(TapDownDetails details) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selection = await showMenu<_LocationSource>(
      context: context,
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          20,
          details.globalPosition.dy + 12,
          overlay.size.width - 40,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _LocationSource.signup,
          child: locationMenuItem(
            icon: Icons.home_work_outlined,
            title: _savedCity.isNotEmpty ? _savedCity : 'Saved city',
            subtitle: 'Use your city selected during signup',
            selected: _selectedLocationSource == _LocationSource.signup,
          ),
        ),
        PopupMenuItem(
          value: _LocationSource.live,
          child: locationMenuItem(
            icon: Icons.my_location_rounded,
            title: 'Use live location',
            subtitle: 'Fetch your current device location',
            selected: _selectedLocationSource == _LocationSource.live,
          ),
        ),
      ],
    );

    if (selection != null) {
      await _selectLocationSource(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 18),
              _buildEmergencyBookingCard(),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search repair, cleaning, plumbing...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: () async {
                            final repairmen = await _repairmenFuture;
                            if (!mounted) return;
                            await _openRepairmanFilters(repairmen);
                          },
                        ),
                      ],
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Popular Services',
                subtitle: 'Pick a category and book in minutes',
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<ServiceCategoryView>>(
                future: _serviceCategoriesFuture,
                builder: (context, snapshot) {
                  final categories = _filterCategories(
                    snapshot.data ?? _fallbackCategories,
                  );
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No services match your search.'),
                    );
                  }

                  return SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 150,
                          child: serviceCard(categories[index]),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Nearby Repairmans',
                subtitle: _repairmanFilterMode == _RepairmanFilterMode.all
                    ? 'Trusted professionals available around your area'
                    : _repairmanFilterMode == _RepairmanFilterMode.location
                    ? 'Repairmen filtered by your selected location'
                    : _repairmanFilterMode == _RepairmanFilterMode.specialty
                    ? 'Repairmen listed by rating for ${_selectedSpecialtyFilter ?? 'the selected specialty'}'
                    : 'Top-rated repairmen across 6 specialties',
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<dynamic>>(
                future: _repairmenFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text('Failed to load workers'),
                    );
                  }

                  final repairmen = _filterRepairmen(snapshot.data ?? []);
                  if (repairmen.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No repairmen match your search.'
                            : _repairmanFilterMode == _RepairmanFilterMode.location
                            ? 'No repairmen found near your selected location.'
                            : _repairmanFilterMode ==
                                  _RepairmanFilterMode.specialty
                            ? 'No repairmen found for ${_selectedSpecialtyFilter ?? 'that specialty'}.'
                            : _repairmanFilterMode == _RepairmanFilterMode.best
                            ? 'No top-rated repairmen are available right now.'
                            : 'No workers available right now',
                      ),
                    );
                  }

                  final sortedRepairmen = List<dynamic>.from(repairmen);
                  if (_selectedLocation != null &&
                      _repairmanFilterMode == _RepairmanFilterMode.all) {
                    sortedRepairmen.sort((a, b) {
                      final repairmanA = Map<String, dynamic>.from(a as Map);
                      final repairmanB = Map<String, dynamic>.from(b as Map);

                      final latA = double.tryParse(
                        '${repairmanA['latitude'] ?? ''}',
                      );
                      final lngA = double.tryParse(
                        '${repairmanA['longitude'] ?? ''}',
                      );
                      final latB = double.tryParse(
                        '${repairmanB['latitude'] ?? ''}',
                      );
                      final lngB = double.tryParse(
                        '${repairmanB['longitude'] ?? ''}',
                      );

                      final distanceA = latA != null && lngA != null
                          ? calculateDistance(
                              _selectedLocation!,
                              latlng.LatLng(latA, lngA),
                            )
                          : double.infinity;
                      final distanceB = latB != null && lngB != null
                          ? calculateDistance(
                              _selectedLocation!,
                              latlng.LatLng(latB, lngB),
                            )
                          : double.infinity;

                      return distanceA.compareTo(distanceB);
                    });
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedRepairmen.length,
                    itemBuilder: (context, index) {
                      final data = Map<String, dynamic>.from(
                        sortedRepairmen[index] as Map,
                      );
                      final name = (data['name'] ?? 'Worker').toString();
                      final ratingValue = data['rating'];
                      final rating = ratingValue is num
                          ? ratingValue.toDouble()
                          : double.tryParse('$ratingValue') ?? 0.0;
                      final specialty = _repairmanSpecialty(data);

                      return workerCard(
                        name,
                        rating.toStringAsFixed(1),
                        specialty,
                        index,
                        data,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange.withAlpha(128),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF3BA7B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage('assets/images/logo.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NotificationBellButton(
                    backgroundColor: Colors.white.withAlpha(38),
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(
                              initialUserLocation: _selectedLocation,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLocationSelector(isInHero: true),
        ],
      ),
    );
  }

  Widget _buildEmergencyBookingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD8C7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.crisis_alert_outlined,
              color: Color(0xFFE05A2A),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need urgent help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Request repairmen who have emergency service turned on.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserEmergencyServiceBookingScreen(
                    userLocation: _selectedLocation,
                    locationLabel: _selectedLocationLabel,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE05A2A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector({bool isInHero = false}) {
    final backgroundColor = isInHero
        ? Colors.white.withAlpha(235)
        : Colors.white;
    final boxShadow = isInHero
        ? null
        : const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: openLocationMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: boxShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFE23744),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(
                      color: Color(0xFF7A8699),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedLocationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A2233),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              key: _locationMenuKey,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF7A8699),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget locationMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE8F1FF)
                  : const Color(0xFFF3F6FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected
                  ? const Color(0xFF1F6FEB)
                  : const Color(0xFF7A8699),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: const Color(0xFF1A2233),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8699),
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1F6FEB)),
        ],
      ),
    );
  }

  Widget serviceCard(ServiceCategoryView category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DynamicServiceListScreen(
              categoryTitle: category.label,
              categoryIcon: category.icon,
              subtitle: category.subtitle,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x110F172A),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  category.icon,
                  color: const Color(0xFF1F6FEB),
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                category.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget workerCard(
    String name,
    String rating,
    String specialty,
    int index,
    Map<String, dynamic> data,
  ) {
    final repairmanLatitude = double.tryParse('${data['latitude'] ?? ''}');
    final repairmanLongitude = double.tryParse('${data['longitude'] ?? ''}');
    final distanceLabel =
        _selectedLocation != null &&
            repairmanLatitude != null &&
            repairmanLongitude != null
        ? '${calculateDistance(
            _selectedLocation!,
            latlng.LatLng(repairmanLatitude, repairmanLongitude),
          ).toStringAsFixed(1)} km away'
        : 'Distance unavailable';
    final isBestRepairman = data['is_best_repairman'] == true;
    final emergencyEnabled = data['emergency_service_enabled'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RepairmanProfilePage(
              name: name,
              rating: rating.toString(),
              profileData: data,
              userLocation: _selectedLocation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: index.isEven
                      ? [const Color(0xFF1F6FEB), const Color(0xFF54C5F8)]
                      : [const Color(0xFFFF9A62), const Color(0xFFFFC371)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (isBestRepairman) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Best Repairman',
                        style: TextStyle(
                          color: Color(0xFF8A5A00),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  if (emergencyEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9D8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Emergency Services',
                        style: TextStyle(
                          color: Color(0xFFD35400),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFF9800),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F7EF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          distanceLabel,
                          style: const TextStyle(
                            color: Color(0xFF1F8B4C),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA4B2)),
          ],
        ),
      ),
    );
  }
}

enum _LocationSource { signup, live }

enum _RepairmanFilterMode { all, location, specialty, best }

class _RepairmanFilterSelection {
  final _RepairmanFilterMode mode;
  final String? specialty;

  const _RepairmanFilterSelection({
    required this.mode,
    this.specialty,
  });
}

class ServiceCategoryView {
  final String label;
  final String subtitle;
  final IconData icon;

  const ServiceCategoryView({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
