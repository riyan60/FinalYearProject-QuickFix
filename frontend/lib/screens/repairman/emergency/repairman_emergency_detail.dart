import 'package:flutter/material.dart';
import '../../../services/repairman/job_service.dart';

class RepairmanEmergencyDetailScreen extends StatelessWidget {
  final Map<String, String> booking;

  const RepairmanEmergencyDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final customer = booking['customer'] ?? 'Unknown';
    final issue = booking['issue'] ?? 'No issue specified';
    final location = booking['location'] ?? 'Unknown location';
    final fee = booking['fee'] ?? '₹0';
    final service = booking['service'] ?? 'Unknown service';
    final avatar = booking['avatar'] ?? 'https://i.pravatar.cc/150?img=11';
    final jobId = booking['id'] ?? 'unknown';

    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF7043)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Accept $service Job',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                          Text(' Emergency', style: TextStyle(color: Color(0xFFC2410C), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildJobProfileHeader(customer, avatar, location),
                      const SizedBox(height: 20),
                      _buildMapCard(location, fee),
                      const SizedBox(height: 20),
                      _buildEarningsBreakdown(fee),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await JobService().completeJob(jobId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Job started!')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Start Job', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Decline Job', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobProfileHeader(String customer, String avatar, String location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(avatar),
            ),
            const Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking['issue']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey),
                  Text(' $location', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ],
              ),
              Text('$customer - ${booking['service']}', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard(String location, String fee) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1580130775592-0e7ac6a103d9?w=1000'),
                fit: BoxFit.cover,
              ),
            ),
            child: const Center(child: Icon(Icons.location_pin, color: Colors.red, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fee, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildSmallButton(Icons.chat, 'Chat', Colors.green),
                    const SizedBox(width: 8),
                    _buildSmallButton(Icons.navigation, 'Navigate', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdown(String totalFee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(),
          _buildPriceRow('Service Fee', '₹400'),
          _buildPriceRow('Emergency Fee', '₹300'),
          _buildPriceRow('Total Earnings', totalFee, isBold: true),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Earnings', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text(totalFee, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(price, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

