import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/utils/location_utils.dart';
import '../../../services/booking_service.dart';
import '../../../services/repairman/repairman_service.dart';
import 'booking_success_page.dart';

class UserEmergencyServiceBookingScreen extends StatefulWidget {
  final latlng.LatLng? userLocation;
  final String locationLabel;

  const UserEmergencyServiceBookingScreen({
    super.key,
    this.userLocation,
    this.locationLabel = 'Current location',
  });

  @override
  State<UserEmergencyServiceBookingScreen> createState() =>
      _UserEmergencyServiceBookingScreenState();
}

class _UserEmergencyServiceBookingScreenState
    extends State<UserEmergencyServiceBookingScreen> {
  final RepairmanService _repairmanService = RepairmanService();
  final BookingService _bookingService = BookingService();
  final TextEditingController _issueController = TextEditingController();

  static const List<String> _serviceTypes = [
    'Electrician',
    'Plumber',
    'AC Repair',
    'Mechanic',
  ];

  late final Future<List<dynamic>> _repairmenFuture = _repairmanService
      .getRepairmanList();
  String _selectedService = _serviceTypes.first;
  bool _isEmergencyPriority = true;
  String? _selectedRepairmanId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  String _normalizeCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('electric')) return 'electrician';
    if (normalized.contains('plumb')) return 'plumber';
    if (normalized.contains('ac')) return 'ac repair';
    if (normalized.contains('mechanic')) return 'mechanic';
    return normalized;
  }

  double _repairmanRating(Map<String, dynamic> item) {
    final rating = item['rating'];
    if (rating is num) return rating.toDouble();
    return double.tryParse('$rating') ?? 0;
  }

  double _repairmanHourlyRate(Map<String, dynamic> item) {
    final rate = item['hourly_rate'] ?? item['hourlyRate'] ?? item['custom_price'];
    if (rate is num) return rate.toDouble();
    return double.tryParse('$rate') ?? 0;
  }

  Set<String> _repairmanCategories(Map<String, dynamic> item) {
    final categories = <String>{};

    void addValue(dynamic value) {
      if (value == null) return;
      final normalized = _normalizeCategory(value.toString());
      if (normalized.isNotEmpty) categories.add(normalized);
    }

    addValue(item['specialization']);
    addValue(item['category']);

    final skills = item['skills'];
    if (skills is List) {
      for (final skill in skills) {
        addValue(skill);
      }
    }

    return categories;
  }

  List<Map<String, dynamic>> _filteredRepairmen(List<dynamic> repairmen) {
    final selectedCategory = _normalizeCategory(_selectedService);
    final filtered = repairmen
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
          final emergencyEnabled = item['emergency_service_enabled'] == true;
          final available =
              (item['availability_status'] ?? '').toString().toLowerCase() ==
              'available';
          return emergencyEnabled &&
              available &&
              _repairmanCategories(item).contains(selectedCategory);
        })
        .toList();

    filtered.sort((a, b) {
      if (widget.userLocation != null) {
        final latA = double.tryParse('${a['latitude'] ?? ''}');
        final lngA = double.tryParse('${a['longitude'] ?? ''}');
        final latB = double.tryParse('${b['latitude'] ?? ''}');
        final lngB = double.tryParse('${b['longitude'] ?? ''}');

        final distanceA = latA != null && lngA != null
            ? calculateDistance(
                widget.userLocation!,
                latlng.LatLng(latA, lngA),
              )
            : double.infinity;
        final distanceB = latB != null && lngB != null
            ? calculateDistance(
                widget.userLocation!,
                latlng.LatLng(latB, lngB),
              )
            : double.infinity;

        final distanceCompare = distanceA.compareTo(distanceB);
        if (distanceCompare != 0) return distanceCompare;
      }

      return _repairmanRating(b).compareTo(_repairmanRating(a));
    });

    return filtered;
  }

  String _distanceLabel(Map<String, dynamic> repairman) {
    if (widget.userLocation == null) return 'Distance unavailable';
    final latitude = double.tryParse('${repairman['latitude'] ?? ''}');
    final longitude = double.tryParse('${repairman['longitude'] ?? ''}');
    if (latitude == null || longitude == null) return 'Distance unavailable';
    final distance = calculateDistance(
      widget.userLocation!,
      latlng.LatLng(latitude, longitude),
    );
    return '${distance.toStringAsFixed(1)} km away';
  }

  Future<void> _submitEmergencyRequest(List<Map<String, dynamic>> repairmen) async {
    final selectedRepairman = repairmen.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['id']?.toString() == _selectedRepairmanId,
          orElse: () => null,
        );

    if (selectedRepairman == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an emergency repairman first.')),
      );
      return;
    }

    final issue = _issueController.text.trim();
    if (issue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the issue before continuing.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';

    try {
      await _bookingService.createBookingWithLocation(
        serviceId: 'Emergency Service - $_selectedService',
        repairmanId: (selectedRepairman['id'] ?? '').toString(),
        bookingDate: DateTime(now.year, now.month, now.day).toIso8601String(),
        scheduledTime: '$hour:$minute $suffix',
        totalAmount: _repairmanHourlyRate(selectedRepairman),
        paymentMethod: 'Cash on Service',
        paidFromWallet: false,
        bookingType: 'direct_repairman',
        bookingMode: 'emergency',
        hourlyRate: _repairmanHourlyRate(selectedRepairman),
        bookedHours: 0,
        repairmanName: (selectedRepairman['name'] ?? '').toString(),
        specialty: _selectedService,
        extraData: {
          'issue_description': issue,
          'emergency_priority': _isEmergencyPriority ? 'emergency' : 'normal',
          'emergency_request': true,
        },
        userLatitude: widget.userLocation?.latitude,
        userLongitude: widget.userLocation?.longitude,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(
            bookedCount: 1,
            scheduledDate: now,
            scheduledTime: '$hour:$minute $suffix',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    final isSelected = _selectedService == title;
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _selectedService = title;
                _selectedRepairmanId = null;
              });
            },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCE8FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF2E6BE6), width: 1.2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _isEmergencyPriority = isSelected;
                });
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.red.shade200) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.red : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.notifications_active,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Emergency Service',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _repairmenFuture,
        builder: (context, snapshot) {
          final repairmen = _filteredRepairmen(snapshot.data ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: [
                    _buildServiceCard('Electrician', Icons.bolt, Colors.red),
                    _buildServiceCard('Plumber', Icons.water_drop, Colors.blue),
                    _buildServiceCard(
                      'AC Repair',
                      Icons.ac_unit,
                      Colors.blueAccent,
                    ),
                    _buildServiceCard(
                      'Mechanic',
                      Icons.build,
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Location',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.locationLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Describe the issue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _issueController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Type your problem here...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Priority',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityButton('Normal', !_isEmergencyPriority),
                    const SizedBox(width: 10),
                    _buildPriorityButton('Emergency', _isEmergencyPriority),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nearest Available Technicians',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (repairmen.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No emergency-enabled repairmen are available for this service right now.',
                    ),
                  )
                else
                  ...repairmen.map((repairman) {
                    final repairmanId = (repairman['id'] ?? '').toString();
                    final isSelected = repairmanId == _selectedRepairmanId;
                    final hourlyRate = _repairmanHourlyRate(repairman);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? const BorderSide(
                                color: Color(0xFF2E6BE6),
                                width: 1.2,
                              )
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        onTap: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _selectedRepairmanId = repairmanId;
                                });
                              },
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (repairman['name'] ?? 'Repairman').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9D8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Emergency',
                                style: TextStyle(
                                  color: Color(0xFFD35400),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${_repairmanRating(repairman).toStringAsFixed(1)} star - ${_distanceLabel(repairman)} - Rs ${hourlyRate.toStringAsFixed(0)}/hr',
                          ),
                        ),
                        trailing: Radio<String>(
                          value: repairmanId,
                          groupValue: _selectedRepairmanId,
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedRepairmanId = value;
                                  });
                                },
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting
                ? null
                : () async {
                    final repairmen = _filteredRepairmen(
                      await _repairmenFuture,
                    );
                    await _submitEmergencyRequest(repairmen);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05A2A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.crisis_alert_outlined),
            label: Text(
              _isSubmitting
                  ? 'Sending request...'
                  : 'Request Emergency Service',
            ),
          ),
        ),
      ),
    );
  }
}
