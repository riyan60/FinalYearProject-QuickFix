import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_utils.dart';
import '../../../providers/repairman/job_provider.dart';
import '../../../services/location_service.dart';
import 'job_details.dart';

class JobRequestsPage extends StatefulWidget {
  final String initialStatus;

  const JobRequestsPage({super.key, this.initialStatus = 'pending'});

  @override
  State<JobRequestsPage> createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  late final JobProvider jobProvider;
  late String _selectedStatus;
  Timer? _locationTimer;
  String? _updatingBookingId;
  String? _rejectingBookingId;

  static const Color _pageColor = Color(0xFFF8F9FE);
  static const Color _primaryColor = Color(0xFF4A80D4);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE7ECF5);

  @override
  void initState() {
    super.initState();
    jobProvider = Provider.of<JobProvider>(context, listen: false);
    _selectedStatus = widget.initialStatus;
    jobProvider.loadJobs(status: _selectedStatus);
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

      _locationTimer?.cancel();
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
      debugPrint('Repairman location sharing error: $e');
    }
  }

  Future<void> _refreshJobs() async {
    await jobProvider.loadJobs(status: _selectedStatus);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['_seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num).toInt() * 1000,
      );
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatStatus(String status) {
    final normalized = status.trim();
    if (normalized.isEmpty) return 'Pending';
    return normalized
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _shortBookingId(String id) {
    if (id.length <= 10) return id.toUpperCase();
    return id.substring(id.length - 10).toUpperCase();
  }

  bool _isDirectBooking(Map<String, dynamic> booking) {
    return (booking['booking_type'] ?? '').toString() == 'direct_repairman';
  }

  bool _isEmergencyBooking(Map<String, dynamic> booking) {
    final emergencyRequest =
        booking['emergency_request'] ?? booking['emergencyRequest'];
    final emergencyPriority =
        (booking['emergency_priority'] ?? booking['emergencyPriority'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return emergencyRequest == true ||
        emergencyPriority == 'emergency' ||
        emergencyPriority == 'high';
  }

  String _bookingTitle(Map<String, dynamic> booking) {
    final serviceName = (booking['service_name'] ?? '').toString().trim();
    final specialty = (booking['specialty'] ?? '').toString().trim();
    final serviceId = (booking['service_id'] ?? '').toString().trim();

    if (_isDirectBooking(booking)) {
      return specialty.isNotEmpty ? specialty : 'Direct Repairman Booking';
    }
    if (serviceName.isNotEmpty) return serviceName;
    return serviceId.isNotEmpty ? 'Service $serviceId' : 'Service Booking';
  }

  String _bookingSubtitle(Map<String, dynamic> booking) {
    if (_isDirectBooking(booking)) {
      final mode = (booking['booking_mode'] ?? '').toString().trim();
      return mode.isEmpty ? 'Mode: Custom' : 'Mode: ${_formatStatus(mode)}';
    }
    final serviceId = (booking['service_id'] ?? '').toString().trim();
    return serviceId.isEmpty
        ? 'Service details unavailable'
        : 'Service ID: $serviceId';
  }

  String _customerLabel(Map<String, dynamic> booking) {
    final userName = (booking['user_name'] ?? '').toString().trim();
    if (userName.isNotEmpty) return 'User: $userName';
    final userId = (booking['user_id'] ?? '').toString().trim();
    return userId.isEmpty ? 'User details unavailable' : 'User ID: $userId';
  }

  String _amountLabel(dynamic amount) {
    final numeric = amount is num ? amount.toDouble() : double.tryParse('$amount');
    if (numeric == null || numeric <= 0) return 'To be confirmed';
    return MoneyUtils.format(numeric);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
      case 'in_progress':
      case 'booking_confirmed':
      case 'reached_destination':
      case 'completion_pending_repairman':
        return Colors.blue;
      case 'completion_pending_user':
        return Colors.deepOrange;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String? _nextStatus(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (_isDirectBooking(booking)) {
      if (status == 'pending') return 'booking_confirmed';
      if (status == 'booking_confirmed') return 'reached_destination';
      if (status == 'reached_destination') return 'completed';
      if (status == 'arrival_confirmed') return 'completed';
      if (status == 'completion_pending_repairman') return 'completed';
      return null;
    }

    if (status == 'pending') return 'accepted';
    if (status == 'accepted') return 'in_progress';
    if (status == 'in_progress') return 'completed';
    if (status == 'completion_pending_repairman') return 'completed';
    return null;
  }

  String _actionLabel(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString().toLowerCase();
    if (_isDirectBooking(booking)) {
      if (status == 'pending') return 'Confirm';
      if (status == 'booking_confirmed') return 'Reached';
      if (status == 'arrival_confirmed') return 'Complete';
      if (status == 'reached_destination') return 'Complete';
      if (status == 'completion_pending_user') return 'Waiting for User';
      if (status == 'completion_pending_repairman') return 'Confirm';
      return 'Done';
    }

    if (status == 'pending') return 'Accept';
    if (status == 'accepted') return 'Start';
    if (status == 'completion_pending_user') return 'Waiting for User';
    if (status == 'completion_pending_repairman') return 'Confirm';
    if (status == 'in_progress') return 'Complete';
    return 'Done';
  }

  String? _progressMessage(Map<String, dynamic> booking) {
    if (booking['repairman_completion_confirmed'] == true &&
        booking['user_completion_confirmed'] != true) {
      return 'Completion confirmed by you. Waiting for user.';
    }
    if (booking['user_completion_confirmed'] == true &&
        booking['repairman_completion_confirmed'] != true) {
      return 'User confirmed completion. Confirm from your side.';
    }
    if (booking['arrival_confirmed_by_user'] == true) {
      return 'User confirmed arrival.';
    }
    return null;
  }

  Future<void> _updateJobStatus(String bookingId, String status) async {
    setState(() {
      _updatingBookingId = bookingId;
    });

    try {
      await jobProvider.updateJobStatus(bookingId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Job ${_formatStatus(status)}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingBookingId = null;
        });
      }
    }
  }

  Future<void> _rejectJob(String bookingId) async {
    setState(() {
      _rejectingBookingId = bookingId;
    });

    try {
      await jobProvider.updateJobStatus(bookingId, 'rejected');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _rejectingBookingId = null;
        });
      }
    }
  }

  Future<void> _openDetails(Map<String, dynamic> booking) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => JobDetailsScreen(booking: booking)),
    );
    if (changed == true && mounted) {
      await _refreshJobs();
    }
  }

  List<Map<String, dynamic>> _normalizedJobs(List<dynamic> rawJobs) {
    final jobs = rawJobs
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    jobs.sort((a, b) {
      final emergencyComparison = (_isEmergencyBooking(b) ? 1 : 0).compareTo(
        _isEmergencyBooking(a) ? 1 : 0,
      );
      if (_selectedStatus == 'pending' && emergencyComparison != 0) {
        return emergencyComparison;
      }
      final dateA = _parseDate(a['booking_date']) ?? DateTime(1970);
      final dateB = _parseDate(b['booking_date']) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return jobs;
  }

  Widget _buildHero(List<Map<String, dynamic>> jobs) {
    final emergencyCount = jobs.where(_isEmergencyBooking).length;
    final actionCount = jobs.where((booking) {
      final action = _actionLabel(booking);
      return _nextStatus(booking) != null && action != 'Waiting for User';
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.pending_actions, color: _primaryColor),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review customer bookings and move jobs forward.',
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Shown', jobs.length, _primaryColor),
              const SizedBox(width: 10),
              _metric('Urgent', emergencyCount, Colors.deepOrange),
              const SizedBox(width: 10),
              _metric('Actions', actionCount, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterButton('pending', 'Requests'),
          const SizedBox(width: 8),
          _filterButton('active', 'Active'),
          const SizedBox(width: 8),
          _filterButton('completed', 'Completed'),
        ],
      ),
    );
  }

  Widget _filterButton(String value, String label) {
    final selected = _selectedStatus == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(
        value == 'pending'
            ? Icons.pending_actions_outlined
            : value == 'active'
            ? Icons.handyman_outlined
            : Icons.check_circle_outline,
        size: 18,
      ),
      selectedColor: const Color(0xFFE9EEF9),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? _primaryColor : _borderColor,
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF3559A8) : _textColor,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        setState(() {
          _selectedStatus = value;
        });
        jobProvider.loadJobs(status: value);
      },
    );
  }

  Widget _buildEmptyState() {
    final message = _selectedStatus == 'active'
        ? 'No active jobs found'
        : _selectedStatus == 'completed'
        ? 'No completed jobs yet'
        : 'No pending requests right now';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                color: _primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pull down to refresh when new customer bookings arrive.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> booking) {
    final bookingId = (booking['id'] ?? '').toString();
    final status = (booking['status'] ?? 'pending').toString();
    final scheduledDate = _parseDate(booking['booking_date']);
    final scheduledTime = (booking['scheduled_time'] ?? 'Time not set')
        .toString();
    final issue = (booking['issue_description'] ?? '').toString().trim();
    final nextStatus = _nextStatus(booking);
    final actionLabel = _actionLabel(booking);
    final canAdvance = nextStatus != null && actionLabel != 'Waiting for User';
    final isRejecting = _rejectingBookingId == bookingId;
    final isUpdating = _updatingBookingId == bookingId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _statusColor(status).withOpacity(0.12),
                child: Icon(
                  _isDirectBooking(booking)
                      ? Icons.engineering_outlined
                      : Icons.home_repair_service_outlined,
                  color: _statusColor(status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${_shortBookingId(bookingId)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _bookingTitle(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bookingSubtitle(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _customerLabel(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (_isEmergencyBooking(booking)) ...[
                      const SizedBox(height: 6),
                      _smallBadge(
                        label: 'Emergency',
                        color: const Color(0xFFD9481C),
                        backgroundColor: const Color(0xFFFFECE8),
                      ),
                    ],
                  ],
                ),
              ),
              _smallBadge(
                label: _formatStatus(status),
                color: _statusColor(status),
                backgroundColor: _statusColor(status).withOpacity(0.1),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_formatDate(scheduledDate)} - $scheduledTime',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              Text(
                _amountLabel(booking['total_amount']),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (issue.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                issue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (_progressMessage(booking) != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _progressMessage(booking)!,
                style: const TextStyle(
                  color: Color(0xFF9A5B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _openDetails(booking),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Details'),
              ),
              if (status.toLowerCase() == 'pending')
                TextButton.icon(
                  onPressed: isRejecting ? null : () => _rejectJob(bookingId),
                  icon: isRejecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Reject'),
                ),
              if (canAdvance)
                TextButton.icon(
                  onPressed: isUpdating
                      ? null
                      : () => _updateJobStatus(bookingId, nextStatus!),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(actionLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallBadge({
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        title: const Text(
          'Job Requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<JobProvider>(
        builder: (context, provider, child) {
          final jobs = _normalizedJobs(provider.jobs);

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshJobs,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildHero(jobs),
                const SizedBox(height: 14),
                _buildFilterBar(),
                const SizedBox(height: 16),
                if (jobs.isEmpty)
                  SizedBox(height: 360, child: _buildEmptyState())
                else
                  ...jobs.map(_buildJobCard),
              ],
            ),
          );
        },
      ),
    );
  }
}
