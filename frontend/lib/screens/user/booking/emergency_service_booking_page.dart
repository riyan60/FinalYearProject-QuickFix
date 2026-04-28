import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/utils/location_utils.dart';
import '../../../core/utils/money_utils.dart';
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

  static const Color _accentColor = Color(0xFFE05A2A);
  static const Color _accentDark = Color(0xFFB8321B);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _pageColor = Color(0xFFF5F7FB);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6B7280);

  Color _alpha(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

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
    final rate =
        item['hourly_rate'] ?? item['hourlyRate'] ?? item['custom_price'];
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

  Future<void> _submitEmergencyRequest(
    List<Map<String, dynamic>> repairmen,
  ) async {
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

  String _selectedRepairmanSummary(List<Map<String, dynamic>> repairmen) {
    final selectedRepairman = repairmen.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['id']?.toString() == _selectedRepairmanId,
          orElse: () => null,
        );

    if (selectedRepairman == null) return 'Choose a technician';
    return (selectedRepairman['name'] ?? 'Selected technician').toString();
  }

  Widget _buildSectionTitle(String title, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
      ],
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color) {
    final isSelected = _selectedService == title;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _selectedService = title;
                _selectedRepairmanId = null;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEFE8) : _surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accentColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _alpha(color, 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? _accentDark : _textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _accentColor, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool emergencyValue,
  }) {
    final isSelected = _isEmergencyPriority == emergencyValue;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _isEmergencyPriority = emergencyValue;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFEFE8) : _surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _accentColor : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: isSelected ? _accentColor : _mutedTextColor),
                  const Spacer(),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? _accentColor : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _accentDark : _textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on, color: _accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dispatch location',
                  style: TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.locationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianCard(Map<String, dynamic> repairman) {
    final repairmanId = (repairman['id'] ?? '').toString();
    final isSelected = repairmanId == _selectedRepairmanId;
    final hourlyRate = _repairmanHourlyRate(repairman);
    final rating = _repairmanRating(repairman);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _selectedRepairmanId = repairmanId;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accentColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: isSelected
                  ? const Color(0xFFFFEFE8)
                  : const Color(0xFFF3F4F6),
              child: Icon(
                Icons.engineering_outlined,
                color: isSelected ? _accentColor : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (repairman['name'] ?? 'Repairman').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFE8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Emergency',
                          style: TextStyle(
                            color: _accentDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(
                        Icons.star_rounded,
                        rating == 0
                            ? 'New'
                            : '${rating.toStringAsFixed(1)} rating',
                      ),
                      _infoChip(Icons.near_me_outlined, _distanceLabel(repairman)),
                      _infoChip(
                        Icons.payments_outlined,
                        '${MoneyUtils.format(hourlyRate)}/hr',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Radio<String>(
              value: repairmanId,
              groupValue: _selectedRepairmanId,
              activeColor: _accentColor,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _selectedRepairmanId = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(Icons.support_agent_outlined, color: _mutedTextColor, size: 34),
          SizedBox(height: 10),
          Text(
            'No emergency technicians available',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textColor),
          ),
          SizedBox(height: 4),
          Text(
            'Try another service category or check again shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        backgroundColor: _pageColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Service',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _repairmenFuture,
        builder: (context, snapshot) {
          final repairmen = _filteredRepairmen(snapshot.data ?? []);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _alpha(Colors.white, 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.emergency_share_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Rapid repair help',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Book the nearest available $_selectedService for urgent support.',
                              style: TextStyle(
                                color: _alpha(Colors.white, 0.9),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _heroMetric(
                                  Icons.person_search_outlined,
                                  '${repairmen.length}',
                                  'available',
                                ),
                                const SizedBox(width: 10),
                                _heroMetric(
                                  Icons.schedule_outlined,
                                  'Now',
                                  _isEmergencyPriority ? 'priority' : 'normal',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Choose service'),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.65,
                        children: [
                          _buildServiceCard(
                            'Electrician',
                            Icons.bolt,
                            const Color(0xFFE11D48),
                          ),
                          _buildServiceCard(
                            'Plumber',
                            Icons.water_drop,
                            const Color(0xFF0EA5E9),
                          ),
                          _buildServiceCard(
                            'AC Repair',
                            Icons.ac_unit,
                            const Color(0xFF2563EB),
                          ),
                          _buildServiceCard(
                            'Mechanic',
                            Icons.build,
                            const Color(0xFFF97316),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildLocationCard(),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Describe the issue'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _issueController,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Example: leaking pipe near kitchen sink',
                          filled: true,
                          fillColor: _surfaceColor,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 58),
                            child: Icon(
                              Icons.report_problem_outlined,
                              color: _accentColor,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: _accentColor,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildSectionTitle('Priority'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildPriorityButton(
                            label: 'Normal',
                            subtitle: 'Urgent, standard queue',
                            icon: Icons.timelapse_outlined,
                            emergencyValue: false,
                          ),
                          const SizedBox(width: 10),
                          _buildPriorityButton(
                            label: 'Emergency',
                            subtitle: 'Highest dispatch priority',
                            icon: Icons.priority_high_rounded,
                            emergencyValue: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        'Available technicians',
                        trailing: repairmen.isEmpty
                            ? null
                            : '${repairmen.length} found',
                      ),
                      const SizedBox(height: 10),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (repairmen.isEmpty)
                        _buildEmptyState()
                      else
                        ...repairmen.map(_buildTechnicianCard),
                      const SizedBox(height: 86),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<List<dynamic>>(
        future: _repairmenFuture,
        builder: (context, snapshot) {
          final repairmen = _filteredRepairmen(snapshot.data ?? []);
          final canSubmit =
              !_isSubmitting &&
              snapshot.hasData &&
              repairmen.isNotEmpty &&
              _selectedRepairmanId != null;
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected',
                          style: TextStyle(
                            color: _mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedRepairmanSummary(repairmen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: canSubmit
                          ? () => _submitEmergencyRequest(repairmen)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD1D5DB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.crisis_alert_outlined),
                      label: Text(_isSubmitting ? 'Sending' : 'Request'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroMetric(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: _alpha(Colors.white, 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _alpha(Colors.white, 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$value ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        color: _alpha(Colors.white, 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
