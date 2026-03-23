import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_utils.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/location_service.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../auth/login_page.dart';
import '../../location/location_picker_screen.dart';
import '../dashboard/repairman_home_page.dart';
import '../earnings/earnings_page.dart';
import '../jobs/job_requests_page.dart';
import 'repairman_services_page.dart';
import 'repairman_verification_page.dart';

class InfoPage extends StatelessWidget {
  final String title;
  final String body;

  const InfoPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class RepairmanProfilePage extends StatefulWidget {
  final String name;
  final double rating;
  final Map<String, dynamic> profileData;

  const RepairmanProfilePage({
    super.key,
    required this.name,
    required this.rating,
    required this.profileData,
  });

  @override
  State<RepairmanProfilePage> createState() => _RepairmanProfilePageState();
}

class _RepairmanProfilePageState extends State<RepairmanProfilePage> {
  Timer? _locationTimer;
  bool _isSharingLocation = false;

  Map<String, dynamic> get _profileData {
    final session = AuthService.currentSession ?? <String, dynamic>{};
    return {...session, ...widget.profileData};
  }

  @override
  void initState() {
    super.initState();
    _startLocationSharing();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().sync();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  String _value(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  void _openInfoPage(BuildContext context, String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoPage(title: title, body: body),
      ),
    );
  }

  Future<void> _startLocationSharing() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) return;

      await LocationService.updateRepairmanLocation(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _isSharingLocation = true;
      });

      _locationTimer = Timer.periodic(const Duration(seconds: 5), (
        timer,
      ) async {
        final newPosition = await LocationService.getCurrentPosition();
        if (newPosition == null) return;
        await LocationService.updateRepairmanLocation(
          newPosition.latitude,
          newPosition.longitude,
        );
      });
    } catch (e) {
      debugPrint('Location sharing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _profileData;
    final displayName = _value(
      data,
      ['name', 'username', 'identity'],
      widget.name,
    );
    final secondaryText = _value(
      data,
      ['email', 'identity', 'accountId'],
      'Signed-in account',
    );
    final tertiaryText = _value(
      data,
      ['phone', 'specialization', 'role'],
      'Repairman',
    );
    final ratingText = widget.rating.toStringAsFixed(1);
    final availability = _value(
      data,
      ['availability_status'],
      'Availability not provided',
    );
    final verificationStatus = _value(
      data,
      ['verification_status'],
      data['is_verified'] == true ? 'verified' : 'unverified',
    );
    final hourlyRate = _value(
      data,
      ['hourly_rate', 'hourlyRate', 'custom_price'],
      'Unavailable',
    );
    final experience = _value(data, ['experience'], 'Not provided');
    final address = _value(data, ['address', 'city'], 'Not provided');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          NotificationBellButton(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EarningsScreen()),
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
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          secondaryText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          tertiaryText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Verification: ${verificationStatus.replaceAll('_', ' ')}',
                            style: const TextStyle(color: Colors.white),
                          ),
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
                    onPressed: () => _openInfoPage(
                      context,
                      'Account details',
                      'Rating: $ratingText\nAvailability: $availability\nHourly rate: ${MoneyUtils.format(hourlyRate)}\nExperience: $experience year(s)\nAddress: $address',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(180, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Account details',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection('Account Info', [
                  _buildListTile(
                    context,
                    Icons.badge_outlined,
                    'Account',
                    onTap: () => _openInfoPage(
                      context,
                      'Account',
                      'Account ID: ${_value(data, ['accountId', 'account_id'], 'Unavailable')}\nRole: ${_value(data, ['role'], 'repairman')}\nLogin: $secondaryText',
                    ),
                  ),
                  _buildListTile(
                    context,
                    _isSharingLocation
                        ? Icons.location_on_outlined
                        : Icons.location_off_outlined,
                    'Live location',
                    onTap: () => _openInfoPage(
                      context,
                      'Live location',
                      _isSharingLocation
                          ? 'Live location sharing is active for this repairman account.'
                          : 'Live location sharing is currently off. Enable device location permission to share updates.',
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.lock,
                    'Verification',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RepairmanVerificationPage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.notifications_none,
                    'Notifications',
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy',
                    onTap: () => _openInfoPage(
                      context,
                      'Privacy',
                      'Authenticated requests use the current session token. Sensitive account fields are not editable from this screen yet.',
                    ),
                  ),
                ]),
                _buildSection('Work & Support', [
                  _buildListTile(
                    context,
                    Icons.miscellaneous_services_outlined,
                    'My Services',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RepairmanServicesPage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.calendar_today_outlined,
                    'My Jobs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JobRequestsPage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.attach_money,
                    'Earnings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EarningsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.help,
                    'Help & Support',
                    onTap: () => _openInfoPage(
                      context,
                      'Help & Support',
                      'For repairman issues, keep the booking ID and time of the issue so the backend records can be checked quickly.',
                    ),
                  ),
                ]),
                _buildSection('Actions', [
                  _buildListTile(
                    context,
                    Icons.flag,
                    'Report a problem',
                    onTap: () => _openInfoPage(
                      context,
                      'Report a problem',
                      'If something fails, capture the screen, the booking ID, and the time so the repairman workflow can be checked.',
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.person_add,
                    'Switch account',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.logout,
                    'Log out',
                    onTap: () async {
                      await AuthService().logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
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
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobRequestsPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            );
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

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
