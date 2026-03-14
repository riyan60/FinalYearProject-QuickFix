import 'package:flutter/material.dart';

import '../../../services/repairman/job_service.dart';

class JobDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;

  const JobDetailsScreen({super.key, this.booking});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  bool _isUpdating = false;

  Map<String, dynamic> get _booking => widget.booking ?? const {};

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

  Future<void> _advanceStatus() async {
    final bookingId = (_booking['id'] ?? '').toString();
    final currentStatus = (_booking['status'] ?? '').toString();

    if (bookingId.isEmpty || currentStatus.isEmpty) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      if (currentStatus == 'pending') {
        await _jobService.acceptJob(bookingId);
      } else if (currentStatus == 'accepted') {
        await _jobService.startJob(bookingId);
      } else if (currentStatus == 'in_progress') {
        await _jobService.completeJob(bookingId);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDate = _parseDate(_booking['booking_date']);
    final status = (_booking['status'] ?? 'unknown').toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: const Color(0xFF4A80D4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking ${_booking['id'] ?? '-'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Service ${_booking['service_id'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('User ID: ${_booking['user_id'] ?? '-'}'),
                  Text('Repairman ID: ${_booking['repairman_id'] ?? '-'}'),
                  Text('Status: $status'),
                  Text(
                    'Schedule: ${_formatDate(scheduledDate)} • ${_booking['scheduled_time'] ?? 'Not set'}',
                  ),
                  Text('Amount: Rs ${_booking['total_amount'] ?? 0}'),
                  if (_booking['otp_verification'] != null) ...[
                    const SizedBox(height: 8),
                    Text('OTP: ${_booking['otp_verification']}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                _isUpdating ||
                    !['pending', 'accepted', 'in_progress'].contains(status)
                ? null
                : _advanceStatus,
            child: _isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    status == 'pending'
                        ? 'Accept Job'
                        : status == 'accepted'
                        ? 'Start Job'
                        : 'Complete Job',
                  ),
          ),
        ],
      ),
    );
  }
}
