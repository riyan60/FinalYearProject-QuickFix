import 'package:flutter/material.dart';

class UserEmergencyTrackingScreen extends StatelessWidget {
  const UserEmergencyTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A80F0), // Main blue background
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- Success Header ---
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 18,
                  child: Icon(Icons.check, color: Colors.white, size: 20),
                ),
                SizedBox(width: 10),
                Text(
                  "Booking Confirmed",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Technician is on the way",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // --- Main Content Card ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildServiceHeader(),
                      const SizedBox(height: 20),
                      _buildTechnicianCard(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                      _buildTrackButton(),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.bolt, color: Colors.white)),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Electrician Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.red),
                      Text(" Curchorem Market, Goa", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                const Text("Arrival in ", style: TextStyle(color: Colors.green)),
                const Text("10-15 min", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTechnicianCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 30, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=ryan')),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Ryan Lobo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(width: 4),
                        Icon(Icons.check_circle, color: Colors.blue, size: 18),
                      ],
                    ),
                    Text("4.8 ⭐", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Text("1.2 km away", style: TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 20),
          _priceRow("Service Fee", "₹500"),
          const SizedBox(height: 10),
          _priceRow("Emergency Fee", "₹200"),
          const Divider(height: 30),
          _priceRow("Total", "₹700", isBold: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _secondaryButton(Icons.chat_bubble, "Chat Technician")),
        const SizedBox(width: 12),
        Expanded(child: _secondaryButton(Icons.location_on, "Track Arrival")),
      ],
    );
  }

  Widget _secondaryButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTrackButton() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A80F0),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Track Technician", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text("Safe & Secure Booking", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _priceRow(String label, String amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 20 : 16)),
      ],
    );
  }
}
