import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: JobRequests()));

class JobRequests extends StatefulWidget {
  const JobRequests({super.key});

  @override
  State<JobRequests> createState() => _JobRequestsState();
}

class _JobRequestsState extends State<JobRequests> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const HomeScreen(),
    const EarningsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A80D4),
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
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLogoHeader(),
        _buildFilterTabs(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _serviceRequestCard(context, "Ceiling Fan Installation", "Ankit Sharma", "2.4 miles", "30 minutes ago"),
              _serviceRequestCard(context, "New Wringing & Repair", "Riya lobo", "11.4 miles", "34 minutes ago"),
              _serviceRequestCard(context, "AC Service", "Deepak naik", "11.4 miles", "44 minutes ago"),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                  child: const Text("View More", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _tab("All", isActive: true),
          _tab("Emergency"),
          _tab("Near Me"),
        ],
      ),
    );
  }

  Widget _tab(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? const Border(bottom: BorderSide(color: Colors.blue, width: 2)) : null,
        boxShadow: [if (!isActive) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _serviceRequestCard(BuildContext context, String title, String client, String dist, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.build, size: 18, color: Colors.grey)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Client: $client", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Row(children: const [Icon(Icons.location_on, size: 12, color: Colors.grey), Text("2.4 miles", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                const Text("30 minutes ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/job-details');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E95E0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("View Details", style: TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLogoHeader(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text("Earnings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildEarningsCard(),
              const SizedBox(height: 20),
              _sectionLabel("Today"),
              _earningItem("Ceiling Fan Installation", "Quepem", "₹ 2,000"),
              _sectionLabel("Feb 4, 2026"),
              _earningItem("New Wringing & Repair", "Gudi", "₹ 10,000"),
              _sectionLabel("Feb 19, 2026"),
              _earningItem("AC Service", "Curchorem", "₹ 7,000"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFD4E9FF), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("₹1,00,000", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Earnings this week", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Text("Feb 1 - Feb 26", style: TextStyle(fontSize: 11))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) => _bar(i == 2)),
          )
        ],
      ),
    );
  }

  Widget _bar(bool active) {
    return Container(height: active ? 60 : 40, width: 20, decoration: BoxDecoration(color: active ? Colors.blue : Colors.white, borderRadius: BorderRadius.circular(5)));
  }

  Widget _sectionLabel(String label) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _earningItem(String title, String loc, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.settings_suggest_outlined),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

Widget _buildLogoHeader() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Row(
      children: const [
        Icon(Icons.build, color: Colors.orange, size: 24),
        SizedBox(width: 8),
        Text("QuickFix", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    ),
  );
}

class JobRequestsPage extends StatelessWidget {
  const JobRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: JobRequests(),
    );
  }
}
