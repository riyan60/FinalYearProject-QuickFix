import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class UserEmergencyBookingConfirmScreen extends StatelessWidget {
  const UserEmergencyBookingConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Emergency Booking", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Get help in minutes", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Stack(
                children: [
                  const Icon(Icons.notifications_none, color: Colors.black),
                  Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Service Banner ---
            _buildServiceBanner(),
            const SizedBox(height: 16),

            // --- Location Card ---
            _buildInfoCard(
              icon: Icons.location_on,
              color: Colors.red,
              text: "Curchorem Market, Goa",
              trailingText: "Change",
            ),
            const SizedBox(height: 16),

            // --- Issue Description ---
            _buildIssueDescription(),
            const SizedBox(height: 16),

            // --- Arrival & Total Row ---
            Row(
              children: [
                Expanded(child: _buildSummaryMiniCard(Icons.access_time, "Estimated Arrival", "10 - 15 min", Colors.red, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryMiniCard(Icons.shopping_bag_outlined, "Total Amount", "₹700", Colors.red, Colors.red)),
              ],
            ),
            const SizedBox(height: 16),

            // --- Detailed Bill ---
            _buildPriceDetails(),
            const SizedBox(height: 24),

            // --- Booking Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency booking confirmed!')),
                  );
Navigator.pushNamed(context, '/user-emergency-tracking');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF04438),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Confirm Booking", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text("Safe & Secure Booking", style: TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildServiceBanner() {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFF04438),
                  radius: 25,
                  child: Icon(Icons.bolt, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Electrician", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: const Text("Emergency", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const Text("High Priority Service", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0, bottom: 0, top: 0,
            child: Image.network('https://cdn-icons-png.flaticon.com/512/3588/3588629.png', width: 100), // Placeholder for technician illustration
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required Color color, required String text, required String trailingText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(trailingText, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIssueDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Describe the issue", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text("Power outage in house. Need immediate help!", style: TextStyle(fontWeight: FontWeight.w500))),
              CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.edit, size: 18, color: Colors.black)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard(IconData icon, String title, String value, Color iconColor, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: valColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _priceRow("Service Fee", "₹500"),
          const SizedBox(height: 8),
          _priceRow("Emergency Fee", "₹200", isEmergency: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)), // Simplification of dashed line
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Total Payable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹700", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool isEmergency = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(amount, style: TextStyle(color: isEmergency ? Colors.red : Colors.black, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
