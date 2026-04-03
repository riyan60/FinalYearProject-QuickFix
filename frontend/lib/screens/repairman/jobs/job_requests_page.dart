import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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
  late JobProvider jobProvider;
  late String _selectedStatus;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    jobProvider = Provider.of<JobProvider>(context, listen: false);
    _selectedStatus = widget.initialStatus;
    jobProvider.loadJobs(status: _selectedStatus);
    _startLocationSharing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    jobProvider.loadJobs(status: _selectedStatus);
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
    jobProvider.refresh();
    if (mounted) setState(() {});
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
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

  bool _isDirectBooking(Map<String, dynamic> booking) {
    return (booking['booking_type'] ?? '').toString() == 'direct_repairman';
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
      if (status == 'completion_pending_repairman') return 'Confirm Completion';
      return 'Done';
    }

    if (status == 'pending') return 'Accept';
    if (status == 'accepted') return 'Start';
    if (status == 'completion_pending_user') return 'Waiting for User';
    if (status == 'completion_pending_repairman') return 'Confirm Completion';
    if (status == 'in_progress') return 'Complete';
    return 'Done';
  }

  Future<void> _updateJobStatus(String bookingId, String status) async {
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
    }
  }

  Future<void> _rejectJob(String bookingId) async {
    await _updateJobStatus(bookingId, 'rejected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repairman Jobs'),
        backgroundColor: const Color(0xFF4A80D4),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'pending',
                  label: Text('Requests'),
                ),
                ButtonSegment<String>(value: 'active', label: Text('Active')),
                ButtonSegment<String>(
                  value: 'completed',
                  label: Text('Completed'),
                ),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedStatus = selection.first;
                });
                jobProvider.loadJobs(status: _selectedStatus);
              },
            ),
          ),
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jobs = provider.jobs;
                if (jobs.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedStatus == 'active'
                          ? 'No active jobs found'
                          : 'No ${_selectedStatus.replaceAll('_', ' ')} jobs found',
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final booking = Map<String, dynamic>.from(
                        jobs[index] as Map,
                      );
                      final bookingId = (booking['id'] ?? '').toString();
                      final scheduledDate = _parseDate(booking['booking_date']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking $bookingId',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isDirectBooking(booking)
                                    ? '${booking['specialty'] ?? 'Direct repairman booking'}'
                                    : (booking['service_name'] ?? '').toString().trim().isNotEmpty
                                    ? '${booking['service_name']}'
                                    : 'Service ${booking['service_id'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_isDirectBooking(booking))
                                Text(
                                  'Mode: ${_formatStatus((booking['booking_mode'] ?? '').toString())}',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              Text(
                                (booking['user_name'] ?? '').toString().trim().isNotEmpty
                                    ? 'User ${booking['user_name']}'
                                    : 'User ${booking['user_id'] ?? '-'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                '${_formatDate(scheduledDate)} • ${booking['scheduled_time'] ?? 'Time not set'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Status: ${_formatStatus((booking['status'] ?? '').toString())}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Amount: ${MoneyUtils.format(booking['total_amount'])}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              if (booking['actual_duration_minutes'] != null)
                                Text(
                                  'Worked: ${booking['actual_duration_minutes']} min',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              if (booking['arrival_confirmed_by_user'] == true)
                                const Text(
                                  'User confirmed arrival',
                                  style: TextStyle(color: Colors.green),
                                ),
                              if ((booking['repairman_completion_confirmed'] == true) &&
                                  (booking['user_completion_confirmed'] != true))
                                const Text(
                                  'Completion confirmed by you. Waiting for user.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              if ((booking['user_completion_confirmed'] == true) &&
                                  (booking['repairman_completion_confirmed'] != true))
                                const Text(
                                  'User confirmed completion. Confirm from your side.',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JobDetailsScreen(
                                              booking: booking,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('View Details'),
                                    ),
                                  ),
                                  if (_selectedStatus != 'completed') ...[
                                    const SizedBox(width: 12),
                                    if ((booking['status'] ?? '')
                                            .toString()
                                            .toLowerCase() ==
                                        'pending') ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _rejectJob(bookingId),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            _actionLabel(booking) ==
                                                    'Waiting for User'
                                                ? null
                                                : () {
                                                    final nextStatus =
                                                        _nextStatus(booking);
                                                    if (nextStatus != null) {
                                                      _updateJobStatus(
                                                        bookingId,
                                                        nextStatus,
                                                      );
                                                    }
                                                  },
                                        child: Text(_actionLabel(booking)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
