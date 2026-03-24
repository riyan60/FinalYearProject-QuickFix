import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../core/utils/money_utils.dart';
import '../map/repairman_preview_map_screen.dart';
import '../user/booking/hourly_repairman_booking_page.dart';

class RepairmanProfilePage extends StatelessWidget {
  final String name;
  final String rating;
  final Map<String, dynamic> profileData;
  final latlong.LatLng? userLocation;

  const RepairmanProfilePage({
    super.key,
    required this.name,
    required this.rating,
    required this.profileData,
    this.userLocation,
  });

  String _value(List<String> keys, String fallback) {
    for (final key in keys) {
      final value = profileData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final specialization = _value(
      ['specialization', 'category'],
      'General repair',
    );
    final bio = _value(
      ['bio'],
      'This repairman has not added a profile description yet.',
    );
    final experience = _value(['experience'], 'Not provided');
    final availability = _value(
      ['availability_status'],
      'Availability not provided',
    );
    final address = _value(['city', 'address'], 'Location not provided');
    final hourlyRate = _value(
      ['hourly_rate', 'hourlyRate', 'custom_price'],
      'Not provided',
    );
    final verified =
        (profileData['is_verified']?.toString().toLowerCase() == 'true');
    final repairmanLatitude = double.tryParse('${profileData['latitude'] ?? ''}');
    final repairmanLongitude = double.tryParse(
      '${profileData['longitude'] ?? ''}',
    );
    final canShowMap =
        userLocation != null &&
        repairmanLatitude != null &&
        repairmanLongitude != null;
    final repairmanId = (profileData['id'] ?? profileData['account_id'] ?? '')
        .toString();
    final isMockRepairman = profileData['is_mock'] == true;
    final isBestRepairman = profileData['is_best_repairman'] == true;
    final emergencyEnabled = profileData['emergency_service_enabled'] == true;
    final completedJobs = _value(
      ['completed_jobs', 'completedJobs', 'jobs_completed', 'total_completed_jobs'],
      '0',
    );
    final hourlyRateValue = double.tryParse(hourlyRate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Repairman Profile'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF3BA7B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    specialization,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (isBestRepairman) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Best Repairman',
                        style: TextStyle(
                          color: Color(0xFF8A5A00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  if (emergencyEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9D8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Emergency Services',
                        style: TextStyle(
                          color: Color(0xFFD35400),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildChip(Icons.star_rounded, rating),
                      _buildChip(
                        verified ? Icons.verified : Icons.verified_outlined,
                        verified ? 'Verified' : 'Not verified',
                      ),
                      _buildChip(Icons.bolt_outlined, availability),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'About',
              child: Text(
                bio,
                style: const TextStyle(
                  height: 1.5,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Work Details',
              child: Column(
                children: [
                  _infoRow('Experience', '$experience year(s)'),
                  _infoRow('Jobs Completed', completedJobs),
                  _infoRow('Hourly Rate', MoneyUtils.format(hourlyRate)),
                  _infoRow('Availability', availability),
                  _infoRow(
                    'Emergency Support',
                    emergencyEnabled ? 'Enabled' : 'Not enabled',
                  ),
                  _infoRow('Location', address),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: canShowMap
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RepairmanPreviewMapScreen(
                              repairmanName: name,
                              userLocation: userLocation!,
                              repairmanLocation: latlong.LatLng(
                                repairmanLatitude!,
                                repairmanLongitude!,
                              ),
                            ),
                          ),
                        );
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Show on map'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    repairmanId.isEmpty ||
                        isMockRepairman ||
                        hourlyRateValue == null ||
                        hourlyRateValue <= 0
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HourlyRepairmanBookingPage(
                              repairmanId: repairmanId,
                              repairmanName: name,
                              specialty: specialization,
                              hourlyRate: hourlyRateValue,
                              userLocation: userLocation,
                              repairmanLocation:
                                  repairmanLatitude != null &&
                                      repairmanLongitude != null
                                  ? latlong.LatLng(
                                      repairmanLatitude,
                                      repairmanLongitude,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6BE6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(isMockRepairman ? 'Display only' : 'Book now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
