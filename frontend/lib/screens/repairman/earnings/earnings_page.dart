import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: EarningsScreen()));

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A80D4), // Blue status bar area
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildToggleSwitch(),
                    const SizedBox(height: 20),
                    _buildEarningsChartCard(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("Today"),
                    _buildEarningsItem("Ceiling Fan Installation", "Quepem", "₹ 2,000", Icons.air_outlined),
                    _buildSectionHeader("Feb 4, 2026"),
                    _buildEarningsItem("New Wiring & Repair", "Gudi", "₹ 10,000", Icons.electrical_services),
                    _buildSectionHeader("Feb 19, 2026"),
                    _buildEarningsItem("AC Service", "Curchorem", "₹ 7,000", Icons.ac_unit),
                    _buildSectionHeader("Feb 20, 2026"),
                    _buildEarningsItem("AC Service & Repair", "Margao", "₹ 5,000", Icons.settings_input_component),
                    _buildEarningsItem("Home Wiring & Repair", "Quepem", "₹ 11,000", Icons.home_repair_service),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text("QuickFix", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.arrow_back_ios, size: 20),
              Expanded(
                child: Center(
                  child: Text("Earnings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: 20), // Spacer for centering
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleBtn("Week", isSelected: true),
          _toggleBtn("Month"),
          const Text("|", style: TextStyle(color: Colors.grey)),
          _toggleBtn("Year"),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, {bool isSelected = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B97FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEarningsChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("₹1,00,000", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Earnings this week", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20)),
            child: const Text("Feb 1 - Feb 26", style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chartBar("Mon", 40),
              _chartBar("Tue", 60),
              _chartBar("Wed", 85, isActive: true),
              _chartBar("Thu", 50),
              _chartBar("Fri", 70),
              _chartBar("Sat", 45),
              _chartBar("Sun", 30),
            ],
          )
        ],
      ),
    );
  }

  Widget _chartBar(String label, double height, {bool isActive = false}) {
    return Column(
      children: [
        Container(
          height: height,
          width: 20,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B97FF) : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEarningsItem(String title, String location, String amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: "Booking"),
        BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: "Map"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
      ],
    );
  }
}