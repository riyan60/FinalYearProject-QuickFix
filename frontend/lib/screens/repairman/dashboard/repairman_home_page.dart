import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_utils.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../widgets/notification_bell_button.dart';
import '../jobs/job_requests_page.dart';
import '../profile/repairman_services_page.dart';
import '../profile/repairman_verification_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final RepairmanService _repairmanService = RepairmanService();
  late Future<_DashboardStats> _statsFuture;
  bool _isEmergencyEnabled = false;
  bool _isSavingEmergency = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadDashboardStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().sync();
    });
  }

  Future<_DashboardStats> _loadDashboardStats() async {
    final pendingFuture = _repairmanService.getMyBookings().then(
      (bookings) => bookings.where((booking) => booking.status == 'pending').length,
    );
    final earningsFuture = _repairmanService.getMyEarnings();
    final profileFuture = AuthService().getCurrentProfile();

    final results = await Future.wait<dynamic>([
      pendingFuture,
      earningsFuture,
      profileFuture,
    ]);

    final pendingJobs = results[0] as int;
    final earningsData = Map<String, dynamic>.from(results[1] as Map);
    final profileResponse = Map<String, dynamic>.from(results[2] as Map);
    final profile = Map<String, dynamic>.from(
      (profileResponse['profile'] as Map?) ?? const <String, dynamic>{},
    );

    final emergencyEnabled =
        profile['emergency_service_enabled'] == true ||
        profile['emergency_service_enabled'].toString().toLowerCase() == 'true';

    if (mounted) {
      setState(() {
        _isEmergencyEnabled = emergencyEnabled;
      });
    }

    return _DashboardStats(
      pendingJobs: pendingJobs,
      totalEarnings: earningsData['total_earnings'] ?? 0,
      completedJobs: earningsData['completed_jobs'] ?? 0,
      repairmanName:
          (profile['name'] ??
                  AuthService.currentSession?['name'] ??
                  AuthService.currentSession?['username'] ??
                  'Repairman')
              .toString(),
    );
  }

  Future<void> _refreshDashboard() async {
    final future = _loadDashboardStats();
    setState(() {
      _statsFuture = future;
    });
    await context.read<NotificationProvider>().sync();
    await future;
  }

  Future<void> _toggleEmergencyServices(bool value) async {
    setState(() {
      _isEmergencyEnabled = value;
      _isSavingEmergency = true;
    });

    try {
      await _repairmanService.updateMyProfile({
        'emergency_service_enabled': value,
      });
      AuthService.mergeSessionProfile({'emergency_service_enabled': value});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Emergency services enabled'
                : 'Emergency services disabled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEmergencyEnabled = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingEmergency = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: FutureBuilder<_DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data;
            final pendingJobs = stats?.pendingJobs ?? 0;
            final totalEarnings = stats?.totalEarnings ?? 0;
            final completedJobs = stats?.completedJobs ?? 0;
            final repairmanName = stats?.repairmanName ?? 'Repairman';

            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _buildHeader(repairmanName),
                  const SizedBox(height: 20),
                  _buildHeroCard(
                    pendingJobs: pendingJobs,
                    totalEarnings: totalEarnings,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pending Jobs',
                          value: '$pendingJobs',
                          subtitle: 'Waiting for response',
                          icon: Icons.pending_actions_outlined,
                          color: const Color(0xFFFFF0D6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Completed',
                          value: '$completedJobs',
                          subtitle: 'Finished bookings',
                          icon: Icons.task_alt_outlined,
                          color: const Color(0xFFDFF4E8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildEmergencyCard(),
                  const SizedBox(height: 22),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.08,
                    children: [
                      _buildActionCard(
                        title: 'Requests',
                        subtitle: pendingJobs > 0
                            ? '$pendingJobs waiting now'
                            : 'No pending requests',
                        icon: Icons.pending_actions_outlined,
                        color: const Color(0xFFFFF0D6),
                        badgeCount: pendingJobs,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JobRequestsPage(
                                initialStatus: 'pending',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        title: 'Active Jobs',
                        subtitle: 'Track ongoing work',
                        icon: Icons.handyman_outlined,
                        color: const Color(0xFFD7E9FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const JobRequestsPage(initialStatus: 'active'),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        title: 'Earnings',
                        subtitle: '${MoneyUtils.format(totalEarnings)} total',
                        icon: Icons.attach_money,
                        color: const Color(0xFFFFE8B8),
                        onTap: () {
                          Navigator.pushNamed(context, '/earnings');
                        },
                      ),
                      _buildActionCard(
                        title: 'Completed',
                        subtitle: '$completedJobs jobs done',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFFFD9D9),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JobRequestsPage(
                                initialStatus: 'completed',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        title: 'Map',
                        subtitle: 'Update live location',
                        icon: Icons.location_on_outlined,
                        color: const Color(0xFFDDF5E8),
                        onTap: () {
                          Navigator.pushNamed(context, '/repairman-map');
                        },
                      ),
                      _buildActionCard(
                        title: 'Profile',
                        subtitle: 'Manage your details',
                        icon: Icons.person_outline,
                        color: const Color(0xFFE9E3FF),
                        onTap: () {
                          Navigator.pushNamed(context, '/repairman-profile');
                        },
                      ),
                      _buildActionCard(
                        title: 'Services',
                        subtitle: 'Add what you offer',
                        icon: Icons.miscellaneous_services_outlined,
                        color: const Color(0xFFE8F1FF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RepairmanServicesPage(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        title: 'Verification',
                        subtitle: 'Submit KYC documents',
                        icon: Icons.verified_user_outlined,
                        color: const Color(0xFFE3F4EA),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RepairmanVerificationPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      stats == null) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (snapshot.hasError && stats == null) ...[
                    const SizedBox(height: 20),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/job-requests');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/repairman-map');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/repairman-profile');
          }
        },
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

  Widget _buildHeader(String repairmanName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Repairman Dashboard',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back, $repairmanName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationBellButton(
              iconColor: const Color(0xFF111827),
              backgroundColor: Colors.white,
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            const SizedBox(width: 10),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required int pendingJobs,
    required dynamic totalEarnings,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E6BE6), Color(0xFF5EA7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x223B82F6),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today at a glance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Stay on top of incoming work and keep emergency support ready.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric('Pending', '$pendingJobs'),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildHeroMetric(
                  'Earnings',
                  MoneyUtils.format(totalEarnings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isEmergencyEnabled
                  ? const Color(0xFFFFE4D6)
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.crisis_alert_outlined,
              color: _isEmergencyEnabled
                  ? const Color(0xFFE05A2A)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEmergencyEnabled
                      ? 'You are visible for urgent repair requests.'
                      : 'Turn this on to accept emergency repair work.',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEmergencyEnabled,
            onChanged: _isSavingEmergency ? null : _toggleEmergencyServices,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: const Color(0xFF1F2937)),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7C51),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStats {
  final int pendingJobs;
  final dynamic totalEarnings;
  final int completedJobs;
  final String repairmanName;

  const _DashboardStats({
    required this.pendingJobs,
    required this.totalEarnings,
    required this.completedJobs,
    required this.repairmanName,
  });
}
