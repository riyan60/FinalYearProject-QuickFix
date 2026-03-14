import 'package:flutter/material.dart';

import '../../../services/repairman/repairman_service.dart';
import '../../../services/user/service_catalog_service.dart';
import '../cart/cart_page.dart';
import '../history/booking_history_page.dart';
import '../profile/user_profile_page.dart';
import '../services/dynamic_service_list_screen.dart';
import '../../repairman/profile/repairman_profile_page.dart';
import '../../location/location_picker_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final ServiceCatalogService _serviceCatalogService = ServiceCatalogService();
  final RepairmanService _repairmanService = RepairmanService();

  int _selectedIndex = 0;

  late final Future<List<_ServiceCategoryView>> _serviceCategoriesFuture =
      _loadServiceCategories();
  late final Future<List<dynamic>> _repairmenFuture = _repairmanService
      .getRepairmanList();

  static const List<_ServiceCategoryView> _fallbackCategories = [
    _ServiceCategoryView(
      label: 'Mechanic',
      subtitle: 'Professional car repair services',
      icon: Icons.directions_car,
    ),
    _ServiceCategoryView(
      label: 'Carpenter',
      subtitle: 'Professional carpentry services',
      icon: Icons.handyman,
    ),
    _ServiceCategoryView(
      label: 'AC Repair',
      subtitle: 'Professional AC cooling services',
      icon: Icons.ac_unit,
    ),
    _ServiceCategoryView(
      label: 'Electrician',
      subtitle: 'Professional electrical services',
      icon: Icons.bolt,
    ),
    _ServiceCategoryView(
      label: 'Plumber',
      subtitle: 'Professional plumbing services',
      icon: Icons.water_drop,
    ),
    _ServiceCategoryView(
      label: 'Cleaning',
      subtitle: 'Professional cleaning services',
      icon: Icons.cleaning_services,
    ),
  ];

  static const Map<String, _ServiceCategoryView> _categoryByKey = {
    'mechanic': _ServiceCategoryView(
      label: 'Mechanic',
      subtitle: 'Professional car repair services',
      icon: Icons.directions_car,
    ),
    'carpenter': _ServiceCategoryView(
      label: 'Carpenter',
      subtitle: 'Professional carpentry services',
      icon: Icons.handyman,
    ),
    'ac repair': _ServiceCategoryView(
      label: 'AC Repair',
      subtitle: 'Professional AC cooling services',
      icon: Icons.ac_unit,
    ),
    'electrician': _ServiceCategoryView(
      label: 'Electrician',
      subtitle: 'Professional electrical services',
      icon: Icons.bolt,
    ),
    'plumber': _ServiceCategoryView(
      label: 'Plumber',
      subtitle: 'Professional plumbing services',
      icon: Icons.water_drop,
    ),
    'cleaning': _ServiceCategoryView(
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

  Future<List<_ServiceCategoryView>> _loadServiceCategories() async {
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
          .whereType<_ServiceCategoryView>()
          .toList();
    } catch (_) {
      return _fallbackCategories;
    }
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
          builder: (context) => const UserProfilePage(userData: null),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            color: const Color(0xFF2B72E1),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      'QuickFix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<_ServiceCategoryView>>(
                      future: _serviceCategoriesFuture,
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? _fallbackCategories;
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            snapshot.data == null) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          );
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          children: categories
                              .map((category) => _serviceCard(category))
                              .toList(),
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.build,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'GET 69% OFF your first booking\nQuick Book Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {},
                            child: const Text(
                              'Book Now',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<List<dynamic>>(
                      future: _repairmenFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            snapshot.data == null) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
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

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.4,
                              ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: repairmen.length,
                          itemBuilder: (context, index) {
                            final data = Map<String, dynamic>.from(
                              repairmen[index] as Map,
                            );
                            final name = (data['name'] ?? 'Worker').toString();
                            final ratingValue = data['rating'];
                            final rating = ratingValue is num
                                ? ratingValue.toStringAsFixed(1)
                                : (double.tryParse('$ratingValue') ?? 0)
                                      .toStringAsFixed(1);

                            return _workerCard(name, rating);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget _serviceCard(_ServiceCategoryView category) {
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: const Color(0xFF4A90E2), size: 35),
            const SizedBox(height: 5),
            Text(
              category.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _workerCard(String name, String rating) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RepairmanProfilePage(name: name, rating: rating),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.blue, size: 14),
                Text(rating, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCategoryView {
  final String label;
  final String subtitle;
  final IconData icon;

  const _ServiceCategoryView({
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}
