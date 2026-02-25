import 'package:flutter/material.dart';

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key});

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
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildJobHeader(),
                      const SizedBox(height: 20),
                      _buildCustomerCard(),
                      const SizedBox(height: 15),
                      _buildScheduleCard(),
                      const SizedBox(height: 15),
                      _buildJobDescription(),
                      const SizedBox(height: 25),
                      _buildActionButtons(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(), // Shared from previous screens
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.build, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text("QuickFix", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text("Job Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFFF5F9FF),
          child: Icon(Icons.plumbing, color: Color(0xFF4A80D4), size: 30),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Fix Leaky Faucet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFD4E9FF), borderRadius: BorderRadius.circular(20)),
              child: const Text("Plumbing Job", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildCustomerCard() {
    return _sectionWrapper(
      title: "Customer",
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Ankit Sharma", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Green Park Apartment, Flat 12B, New Delhi", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return _sectionWrapper(
      title: "Schedule",
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calendar_month, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Today, 24 Apr 2024\n10:00 AM – 11:30 AM", style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Earnings  ₹2,500", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    Text("Payment Paid", style: TextStyle(color: Color(0xFF1E7E34), fontSize: 12)),
                    Icon(Icons.chevron_right, size: 14, color: Color(0xFF1E7E34)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJobDescription() {
    return _sectionWrapper(
      title: "Job Description",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kitchen sink faucet is leaking, need to repair/replace.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Customer Images", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("View All Photos >", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network('https://via.placeholder.com/100', width: 100, fit: BoxFit.cover),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Chat"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A80D4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Start Job"),
          ),
        ),
      ],
    );
  }

  Widget _sectionWrapper({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Booking"),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Map"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}