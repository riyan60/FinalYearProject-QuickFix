import 'package:flutter/material.dart';

import '../../user/home/user_home_page.dart';
import '../../user/profile/user_profile_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Serif'), // Matching the serif-style headers
      home: const RepairmanProfilePage(name: 'Riyan', rating: '4.8'),
    );
  }
}

class RepairmanProfilePage extends StatelessWidget {
  final String name;
  final String rating;

  const RepairmanProfilePage({super.key, required this.name, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBioBox(),
                  const SizedBox(height: 20),
                  const Text("Select Services", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildServiceCard(),
                  const SizedBox(height: 20),
                  const Text("Customer Review", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildReviewRow(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF3B82F6),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () {}),
            ),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.person, size: 60, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 5),
                const Text("Riyan Lobo", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)),
                  child: const Text("₹ 250/hour", style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.orange, size: 16),
                Icon(Icons.star, color: Colors.orange, size: 16),
                Icon(Icons.star, color: Colors.orange, size: 16),
                Icon(Icons.star, color: Colors.orange, size: 16),
                Icon(Icons.star_half, color: Colors.orange, size: 16),
                Text(" 4.8", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Text("(3.5 (453 reviews))", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBioBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: const Text(
        "Highly skilled professional with over 1 year of experience in electrical wiring. Specialized in fan installation, lighting, and electrical panel work.",
        style: TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildServiceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          _serviceItem(Icons.settings_input_component, "Ceiling Fan Installation", "₹450"),
          _serviceItem(Icons.electrical_services, "New Wiring / Repair", "₹650"),
          _serviceItem(Icons.ac_unit, "AC Service/Deep Clean", "₹599"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(150, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Book Now", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _serviceItem(IconData icon, String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black54)),
              child: Center(child: Icon(icon, size: 20, color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReviewRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _reviewChip("Riyan", "4.8"),
          _reviewChip("Ankit", "3.9"),
          _reviewChip("Gaurang", "4.0"),
        ],
      ),
    );
  }

  Widget _reviewChip(String name, String rating) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 15)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Row(children: [
                const Icon(Icons.star, color: Colors.blue, size: 12),
                Text(rating, style: const TextStyle(fontSize: 10, color: Colors.blue)),
              ])
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.orange.withOpacity(0.5),
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Booking'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserHome()),
          );
        } else if (index == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking feature coming soon!')),
          );
        } else if (index == 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Map feature coming soon!')),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserProfilePage()),
          );
        }
      },
    );
  }
}