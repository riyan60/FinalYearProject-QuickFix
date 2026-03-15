import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../jobs/active_jobs_page.dart';
import '../jobs/completed_jobs_page.dart';
import '../../../providers/repairman/job_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final JobProvider jobProvider;
  late final Future<int> _pendingJobsFuture;

  @override
  void initState() {
    super.initState();
    jobProvider = Provider.of<JobProvider>(context, listen: false);
    _pendingJobsFuture = _loadPendingJobs();
  }

  Future<int> _loadPendingJobs() async {
    await jobProvider.loadJobs(status: 'pending');
    return jobProvider.jobs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.settings_suggest, color: Colors.orange, size: 30),
            SizedBox(width: 8),
            Text(
              'QuickFix',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildMenuCard(
                    title: 'Booking Requests',
                    icon: Icons.build_outlined,
                    color: const Color(0xFFFFCC99),
                    badgeCountFuture: _pendingJobsFuture,
                    onTap: () {
                      Navigator.pushNamed(context, '/job-requests');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Scheduled Days',
                    icon: Icons.calendar_month_outlined,
                    color: const Color(0xFF99CCFF),
                    onTap: () {
                      Navigator.pushNamed(context, '/job-requests');
                    },
                  ),
                  _buildMenuCard(
                    title: 'In Progress',
                    icon: Icons.settings_outlined,
                    color: const Color(0xFF99CCFF),
                    onTap: () {
                      Navigator.pushNamed(context, '/job-requests');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Earnings',
                    icon: Icons.attach_money,
                    color: const Color(0xFFFFCC99),
                    onTap: () {
                      Navigator.pushNamed(context, '/earnings');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Profile',
                    icon: Icons.person,
                    color: const Color(0xFF99CCFF),
                    onTap: () {
                      Navigator.pushNamed(context, '/repairman-profile');
                    },
                  ),
                  _buildMenuCard(
                    title: 'Map',
                    icon: Icons.location_on,
                    color: const Color(0xFFFFCC99),
                    onTap: () {
                      Navigator.pushNamed(context, '/repairman-map');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
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
    Future<int>? badgeCountFuture,
    VoidCallback? onTap,
  }) {
    return FutureBuilder<int>(
      future: badgeCountFuture,
      builder: (context, snapshot) {
        final badgeCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          icon,
                          size: 40,
                          color: color.withAlpha(255),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
