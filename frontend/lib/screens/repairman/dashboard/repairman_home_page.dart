import 'package:flutter/material.dart';

void main() {
  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif'),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The blue background color seen at the top of the image
      backgroundColor: const Color(0xFF4A90E2), 
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with Logo and Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/3524/3524659.png', // Placeholder for QuickFix logo
                        height: 30,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'QuickFix',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 20
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content Area (White Rounded Container)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
              child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 25,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Navigate to booking requests
                        },
                        child: _buildMenuCard(
                          title: 'Booking Requests',
                          icon: Icons.build,
                          color: const Color(0xFFF3C699),
                          badgeCount: 3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to scheduled days
                        },
                        child: _buildMenuCard(
                          title: 'Scheduled Days',
                          icon: Icons.calendar_month,
                          color: const Color(0xFF90CAF9),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to in progress
                        },
                        child: _buildMenuCard(
                          title: 'In Progress',
                          icon: Icons.settings,
                          color: const Color(0xFF90CAF9),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to earnings
                        },
                        child: _buildMenuCard(
                          title: 'Earnings',
                          icon: Icons.attach_money,
                          color: const Color(0xFFF3C699),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                      Navigator.pushNamed(context, '/repairman-emergency-list');
                        },
                        child: _buildMenuCard(
                          title: 'Emergency Services',
                          icon: Icons.notifications_active,
                          color: const Color(0xFF90CAF9),
                          badgeCount: 4,
                          isEmergency: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange.withOpacity(0.5),
        showUnselectedLabels: true,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Booking'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    int badgeCount = 0,
    bool isEmergency = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(
                  icon, 
                  size: 35, 
                  color: isEmergency ? Colors.redAccent : color
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            bottom: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEmergency ? const Color(0xFF90CAF9) : const Color(0xFFF3C699),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}