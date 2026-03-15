import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../services/repairman/job_service.dart';

class RepairmanEmergencyListScreen extends StatelessWidget {
  const RepairmanEmergencyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock emergency bookings data
    final List<Map<String, String>> emergencyBookings = [
      {
        'id': 'job_1',
        'customer': 'John Doe',
        'issue': 'Water leakage emergency',
        'location': 'Green Park Apt, 1.8km away',
        'fee': '₹700',
        'service': 'Plumbing',
        'avatar': 'https://i.pravatar.cc/150?u=a',
      },
      {
        'id': 'job_2',
        'customer': 'Jane Smith',
        'issue': 'Electrical short circuit',
        'location': 'Sector 45, 2.5km away',
        'fee': '₹1200',
        'service': 'Electrician',
        'avatar': 'https://i.pravatar.cc/150?u=b',
      },
      {
        'id': 'job_3',
        'customer': 'Mike Johnson',
        'issue': 'AC not cooling',
        'location': 'Curchorem Market, 0.8km away',
        'fee': '₹900',
        'service': 'AC Repair',
        'avatar': 'https://i.pravatar.cc/150?u=c',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Emergency Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4A80F0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('4 Active Emergencies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Tap to accept', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                      child: const Text('High Priority', style: TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Available Jobs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: emergencyBookings.length,
                itemBuilder: (context, index) {
                  final booking = emergencyBookings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(booking['avatar']!),
                                radius: 25,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(booking['customer']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(booking['issue']!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    Text(booking['location']!, style: TextStyle(fontSize: 12, color: Colors.green)),
                                  ],
                                ),
                              ),
                              Text(booking['fee']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.chat, size: 16),
                                  label: const Text('Chat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade700,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final jobId = booking['id'] ?? 'unknown';
                                    await JobService().acceptJob(jobId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Job accepted!')),
                                      );
                                      Navigator.pushNamed(context, AppRoutes.repairmanEmergencyDetail, arguments: booking);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Accept Job'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

