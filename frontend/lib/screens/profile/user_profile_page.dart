import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../cart/cart_page.dart';
import '../home/home_page.dart';
import '../auth/login_page.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Center(
        child: Text(
          '$title\n\nComing Soon!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final dynamic userData;

  const UserProfilePage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
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
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFD6E9FF),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF4A90E2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Riyan Lobo",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "riyan@gmail.com",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Text(
                          "97643642",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Edit profile",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection("Account Info", [
                  _buildListTile(context, Icons.security, "security"),
                  _buildListTile(
                    context,
                    Icons.notifications_none,
                    "Notifications",
                  ),
                  _buildListTile(context, Icons.lock, "Privacy"),
                ]),
                _buildSection("Support & About", [
                  _buildListTile(context, Icons.credit_card, "My Subscription"),
                  _buildListTile(context, Icons.help, "Help & Support"),
                  _buildListTile(context, Icons.info, "Terms and Policies"),
                ]),
                _buildSection("Actions", [
                  _buildListTile(context, Icons.flag, "Report a problem"),
                  _buildListTile(context, Icons.person_add, "Add account"),
                  _buildLogoutListTile(context, Icons.logout, "Log out"),
                ]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
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
            // Already on Profile
          }
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ComingSoonPage(title: title)),
        );
      },
    );
  }

  Widget _buildLogoutListTile(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
      onTap: () async {
        final authService = AuthService();
        await authService.logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
    );
  }
}
