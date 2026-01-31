import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'ac_repair.dart';
import 'carpenter.dart';
import 'cleaning.dart';
import 'electrician.dart';
import 'mechanic.dart';
import 'plumber.dart';

import 'user_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) { // Profile Icon
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfilePage(userData: null), // Pass null or a default user data
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
          // Blue top bar
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 10),
            color: const Color(0xFF2B72E1),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'QuickFix Services',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search",
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
                    // Service Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: [
                        _serviceCard(Icons.directions_car, "Mechanic", context: context),
                        _serviceCard(Icons.handyman, "Carpenter", context: context),
                        _serviceCard(Icons.ac_unit, "AC Repair", context: context),
                        _serviceCard(Icons.bolt, "Electrician", context: context),
                        _serviceCard(Icons.water_drop, "Plumber", context: context),
                        _serviceCard(Icons.cleaning_services, "Cleaning", context: context),
                      ],
                    ),
                    // Promo Banner
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.build, color: Colors.white, size: 30),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "GET 69% OFF your first booking\nQuick Book Now",
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
                            child: const Text("Book Now", style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                    // Worker Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.4,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      children: [
                        _workerCard("Riyan", "4.8"),
                        _workerCard("Ankit", "4.0"),
                        _workerCard("Gaurang", "3.8"),
                        _workerCard("Dhanashre", "3.7"),
                        _workerCard("Vaniesh", "3.1"),
                        _workerCard("Harshvardhan", "1.8"),
                      ],
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _serviceCard(IconData icon, String label, {BuildContext? context}) {
    return GestureDetector(
      onTap: () {
        if (context != null) {
          switch (label) {
            case "Mechanic":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MechanicListScreen()),
              );
              break;
            case "Carpenter":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CarpenterListScreen()),
              );
              break;
            case "AC Repair":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ACRepairListScreen()),
              );
              break;
            case "Electrician":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ElectricianListScreen()),
              );
              break;
            case "Plumber":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlumberListScreen()),
              );
              break;
            case "Cleaning":
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CleaningListScreen()),
              );
              break;
          }
        }
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
            Icon(icon, color: const Color(0xFF4A90E2), size: 35),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _workerCard(String name, String rating) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.blue, size: 14),
              Text(rating, style: const TextStyle(fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}