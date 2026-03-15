import 'package:flutter/material.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../services/user/service_catalog_service.dart';
import '../profile/user_profile_page.dart';
import '../services/dynamic_service_list_screen.dart';
import '../../location/location_picker_screen.dart';
import '../../../routes/app_routes.dart' as routes;

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
  late final Future<List<dynamic>> _repairmenFuture =
      _repairmanService.getRepairmanList();

  static const List<_ServiceCategoryView> _fallbackCategories = [
    _ServiceCategoryView(label: 'Mechanic', subtitle: 'Car repair', icon: Icons.directions_car),
    _ServiceCategoryView(label: 'Carpenter', subtitle: 'Wood work', icon: Icons.handyman),
    _ServiceCategoryView(label: 'AC Repair', subtitle: 'Cooling services', icon: Icons.ac_unit),
    _ServiceCategoryView(label: 'Electrician', subtitle: 'Electrical services', icon: Icons.bolt),
    _ServiceCategoryView(label: 'Plumber', subtitle: 'Plumbing services', icon: Icons.water_drop),
    _ServiceCategoryView(label: 'Cleaning', subtitle: 'Cleaning services', icon: Icons.cleaning_services),
  ];

  static const Map<String, _ServiceCategoryView> _categoryByKey = {
    'mechanic': _ServiceCategoryView(label: 'Mechanic', subtitle: 'Car repair', icon: Icons.directions_car),
    'carpenter': _ServiceCategoryView(label: 'Carpenter', subtitle: 'Wood work', icon: Icons.handyman),
    'ac repair': _ServiceCategoryView(label: 'AC Repair', subtitle: 'Cooling', icon: Icons.ac_unit),
    'electrician': _ServiceCategoryView(label: 'Electrician', subtitle: 'Electrical', icon: Icons.bolt),
    'plumber': _ServiceCategoryView(label: 'Plumber', subtitle: 'Plumbing', icon: Icons.water_drop),
    'cleaning': _ServiceCategoryView(label: 'Cleaning', subtitle: 'Cleaning', icon: Icons.cleaning_services),
  };

  static const Map<String, List<String>> _categoryKeywords = {
    'ac repair': ['ac', 'refrigerant', 'compressor', 'cooling'],
    'electrician': ['electric', 'wiring', 'circuit', 'fan', 'light'],
    'plumber': ['plumb', 'pipe', 'leak', 'drain', 'tap'],
    'carpenter': ['carpenter', 'furniture', 'wood', 'door'],
    'mechanic': ['mechanic', 'engine', 'oil', 'brake'],
    'cleaning': ['clean', 'carpet', 'window'],
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
          if (entry.value.any(haystack.contains)) detected.add(entry.key);
        }
      }
      return detected.isEmpty ? _fallbackCategories : detected.map((key) => _categoryByKey[key]).whereType<_ServiceCategoryView>().toList();
    } catch (_) {
      return _fallbackCategories;
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserProfilePage(userData: null)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Gradient Card
            Stack(
              children: [
                Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6397EF), Color(0xFFF8FAFF)],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/logo.png', height: 35),
                            const SizedBox(width: 8),
                            const Text('QuickFix', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
Navigator.pushNamed(context, '/user-emergency-service-booking');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_active, color: Colors.redAccent, size: 24),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A80F0), Color(0xFFB2C9FB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text("Hello 👋", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text("Find services near you", style: TextStyle(color: Colors.white, fontSize: 20)),
                              const SizedBox(height: 20),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search services',
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.9),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Service Grid
            FutureBuilder<List<_ServiceCategoryView>>(
              future: _serviceCategoriesFuture,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? _fallbackCategories;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) => _serviceCard(categories[index]),
                );
              },
            ),

            // Nearby Repairmen Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Text('Nearby Repairmen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FutureBuilder<List<dynamic>>(
                future: _repairmenFuture,
                builder: (context, snapshot) {
                  final repairmen = snapshot.data ?? [];
                  if (repairmen.isEmpty) return const Center(child: Text("No workers found"));
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: repairmen.length,
                    itemBuilder: (context, index) {
                      final data = Map<String, dynamic>.from(repairmen[index] as Map);
                      return _workerListItem(
                        data['name'] ?? 'Worker', 
                        (data['rating'] ?? 0.0).toString(),
                        "1.2 km away" // Placeholder for distance
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _serviceCard(_ServiceCategoryView category) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DynamicServiceListScreen(
        categoryTitle: category.label, categoryIcon: category.icon, subtitle: category.subtitle,
      ))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: const Color(0xFF4A80F0), size: 45),
            const SizedBox(height: 12),
            Text(category.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _workerListItem(String name, String rating, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundImage: AssetImage('assets/images/user.jpg')),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on, color: Colors.grey, size: 14),
                    const SizedBox(width: 2),
                    Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE8F0FE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View Profile', style: TextStyle(color: Color(0xFF4A80F0), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategoryView {
  final String label;
  final String subtitle;
  final IconData icon;
  const _ServiceCategoryView({required this.label, required this.subtitle, required this.icon});
}