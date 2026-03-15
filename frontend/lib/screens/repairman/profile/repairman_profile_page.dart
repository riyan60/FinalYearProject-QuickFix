import 'package:flutter/material.dart';
import 'dart:async';
import '../../../services/location_service.dart';
import '../../location/location_picker_screen.dart';
import '../dashboard/repairman_home_page.dart';
import '../jobs/job_requests_page.dart';

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

  @override
  void initState() {
    super.initState();
    _startLocationSharing();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationSharing() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) return;

      await LocationService.updateRepairmanLocation(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _isSharingLocation = true;
        });
      }

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
      // Handle error, e.g. permission denied
      debugPrint('Location sharing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rateLabel = widget.profileData['hourlyRate']?.toString() ??
        widget.profileData['hourly_rate']?.toString() ??
        widget.profileData['custom_price']?.toString() ??
        'Rate unavailable';
    final availability =
        widget.profileData['availability_status']?.toString() ??
            'Availability not provided';
    final bio = widget.profileData['bio']?.toString() ??
        'No profile description is available for this repairman yet.';
    final experience =
        widget.profileData['experience']?.toString() ?? 'Not provided';
    final address = widget.profileData['address']?.toString() ?? 'Not provided';
    final verified =
        (widget.profileData['is_verified']?.toString() ?? 'false')
                    .toLowerCase() ==
                'true'
            ? 'Verified'
            : 'Not verified';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF3B82F6),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rateLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 5; i++)
                          Icon(
                            i < widget.rating.floor()
                                ? Icons.star
                                : (i < widget.rating &&
                                        widget.rating % 1 != 0)
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.orange,
                            size: 16,
                          ),
                      ],
                    ),
                    Text(
                      widget.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      availability,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSharingLocation
                            ? Colors.green.withAlpha(51)
                            : Colors.orange.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isSharingLocation
                              ? Colors.green
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSharingLocation
                                ? Icons.location_on
                                : Icons.location_off,
                            color: _isSharingLocation
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSharingLocation
                                ? 'Live location sharing ON'
                                : 'Location sharing OFF',
                            style: TextStyle(
                              color: _isSharingLocation
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Text(
                      bio,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Work Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.work_history_outlined,
                          'Experience',
                          experience,
                        ),
                        _detailRow(
                          Icons.location_on_outlined,
                          'Address',
                          address,
                        ),
                        _detailRow(
                          Icons.verified_outlined,
                          'Verification',
                          verified,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            minimumSize: const Size(150, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange.withAlpha(128),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Booking',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobRequestsPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54),
              ),
              child: Center(child: Icon(icon, size: 20, color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
