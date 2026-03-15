import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

import '../../../services/auth_service.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../services/user/service_catalog_service.dart';
import '../../location/location_picker_screen.dart';
import '../../repairman/profile/repairman_profile_page.dart';
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
    _restoreSignupLocation();
    _loadCurrentProfile();
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
      _selectedLocation = savedLocation;
      _selectedLocationLabel = city.isNotEmpty ? city : 'Signup location';
    } else if (city.isNotEmpty) {
      _selectedLocationLabel = city;
    }

    _savedCity = city;
    if (name.isNotEmpty) {
      _displayName = name;
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
    _searchController.dispose();
    super.dispose();
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
        _selectedLocationLabel =
            'Live (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
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
      if ((resolvedCity ?? '').trim().isNotEmpty &&
          (_savedCity.trim().isEmpty ||
              _selectedLocationSource != _LocationSource.signup)) {
        _savedCity = resolvedCity!.trim();
      }
      if (_selectedLocationSource == _LocationSource.signup &&
          _savedSignupLocation == null) {
        _savedSignupLocation = result;
      }
      if (_selectedLocationSource == _LocationSource.signup) {
        _selectedLocationLabel = _savedCity.isNotEmpty
            ? _savedCity
            : 'Saved city';
      } else {
        _selectedLocationLabel =
            'Live (${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)})';
      }
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
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search repair, cleaning, plumbing...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
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
                  final categories = snapshot.data ?? _fallbackCategories;
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
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
              const SectionHeader(
                title: 'Nearby Repairmans',
                subtitle: 'Trusted professionals available around your area',
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

                  final repairmen = snapshot.data ?? [];
                  if (repairmen.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text('No workers available right now'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: repairmen.length,
                    itemBuilder: (context, index) {
                      final data = Map<String, dynamic>.from(
                        repairmen[index] as Map,
                      );
                      final name = (data['name'] ?? 'Worker').toString();
                      final ratingValue = data['rating'];
                      final rating = ratingValue is num
                          ? ratingValue.toDouble()
                          : double.tryParse('$ratingValue') ?? 0.0;
                      final specialty =
                          (data['specialization'] ??
                                  data['category'] ??
                                  'General repair')
                              .toString();

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
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLocationSelector(isInHero: true),
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
    final distance = (1.2 + (index * 0.7)).toStringAsFixed(1);
    final ratingValue = double.tryParse(rating) ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RepairmanProfilePage(
              name: name,
              rating: ratingValue,
              profileData: data,
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
                          '$distance km away',
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
