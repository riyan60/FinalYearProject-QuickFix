import 'package:flutter/material.dart';

import '../../chat/chat_detail_page.dart';
import '../../repairman/map/repairman_tracking_screen.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/booking_model.dart';
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

  bool get _isDirectBooking =>
      (_booking['booking_type'] ?? '').toString() == 'direct_repairman';

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

  bool get _hasUserLocation {
    final lat = double.tryParse('${_booking['user_latitude'] ?? _booking['userLatitude'] ?? ''}');
    final lng = double.tryParse('${_booking['user_longitude'] ?? _booking['userLongitude'] ?? ''}');
    return lat != null && lng != null;
  }

  void _openUserLocation() {
    if (!_hasUserLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User location is not available for this booking.')),
      );
      return;
    }

    final booking = Booking.fromJson(_booking);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepairmanTrackingScreen(booking: booking),
      ),
    );
  }

  Future<void> _advanceStatus() async {
    final bookingId = (_booking['id'] ?? '').toString();
    final currentStatus = (_booking['status'] ?? '').toString().toLowerCase();

    if (bookingId.isEmpty || currentStatus.isEmpty) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      if (_isDirectBooking) {
        if (currentStatus == 'pending') {
          await _jobService.acceptJob(
            bookingId,
            fallbackStatus: 'booking_confirmed',
          );
        } else if (currentStatus == 'booking_confirmed') {
          await _jobService.reachDestination(bookingId);
        } else if (currentStatus == 'reached_destination' ||
            currentStatus == 'arrival_confirmed' ||
            currentStatus == 'completion_pending_repairman') {
          await _jobService.completeJob(bookingId);
        }
      } else {
        if (currentStatus == 'pending') {
          await _jobService.acceptJob(bookingId);
        } else if (currentStatus == 'accepted') {
          await _jobService.startJob(bookingId);
        } else if (currentStatus == 'in_progress' ||
            currentStatus == 'completion_pending_repairman') {
          await _jobService.completeJob(bookingId);
        }
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

  Future<void> _rejectJob() async {
    final bookingId = (_booking['id'] ?? '').toString();
    final currentStatus = (_booking['status'] ?? '').toString().toLowerCase();
    if (bookingId.isEmpty || currentStatus != 'pending') return;

    setState(() {
      _isUpdating = true;
    });

    try {
      await _jobService.rejectJob(bookingId);
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

  String _buttonLabel(String status) {
    if (_isDirectBooking) {
      if (status == 'pending') return 'Confirm Booking';
      if (status == 'booking_confirmed') return 'Reached Destination';
      if (status == 'arrival_confirmed') {
        return 'Complete & Calculate Pay';
      }
      if (status == 'reached_destination') return 'Complete & Calculate Pay';
      if (status == 'completion_pending_user') return 'Waiting for User';
      if (status == 'completion_pending_repairman') {
        return 'Confirm Completion';
      }
      return 'Done';
    }

    if (status == 'pending') return 'Accept Job';
    if (status == 'accepted') return 'Start Job';
    if (status == 'completion_pending_user') return 'Waiting for User';
    if (status == 'completion_pending_repairman') return 'Confirm Completion';
    return 'Complete Job';
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDate = _parseDate(_booking['booking_date']);
    final reachedDate = _parseDate(_booking['reached_destination_at']);
    final completedDate = _parseDate(_booking['completed_at']);
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
                    _isDirectBooking
                        ? '${_booking['specialty'] ?? 'Direct repairman booking'}'
                        : (_booking['service_name'] ?? '').toString().trim().isNotEmpty
                        ? '${_booking['service_name']}'
                        : 'Service ${_booking['service_id'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isDirectBooking)
                    Text(
                      'Mode: ${_formatStatus((_booking['booking_mode'] ?? '').toString())}',
                    ),
                  Text(
                    (_booking['user_name'] ?? '').toString().trim().isNotEmpty
                        ? 'User: ${_booking['user_name']}'
                        : 'User ID: ${_booking['user_id'] ?? '-'}',
                  ),
                  Text(
                    (_booking['repairman_name'] ?? '').toString().trim().isNotEmpty
                        ? 'Repairman: ${_booking['repairman_name']}'
                        : 'Repairman ID: ${_booking['repairman_id'] ?? '-'}',
                  ),
                  Text('Status: ${_formatStatus(status)}'),
                  Text(
                    'Schedule: ${_formatDate(scheduledDate)} • ${_booking['scheduled_time'] ?? 'Not set'}',
                  ),
                  Text('Amount: ${MoneyUtils.format(_booking['total_amount'])}'),
                  if (_booking['hourly_rate'] != null)
                    Text('Hourly Rate: ${MoneyUtils.format(_booking['hourly_rate'])}'),
                  if (reachedDate != null)
                    Text('Reached: ${_formatDate(reachedDate)}'),
                  if (_booking['actual_duration_minutes'] != null)
                    Text(
                      'Worked Minutes: ${_booking['actual_duration_minutes']}',
                    ),
                  if (_booking['arrival_confirmed_by_user'] == true)
                    const Text(
                      'User confirmed arrival',
                      style: TextStyle(color: Colors.green),
                    ),
                  if (_booking['repairman_completion_confirmed'] == true &&
                      _booking['user_completion_confirmed'] != true)
                    const Text(
                      'Completion confirmed by you. Waiting for user confirmation.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  if (_booking['user_completion_confirmed'] == true &&
                      _booking['repairman_completion_confirmed'] != true)
                    const Text(
                      'User confirmed completion. Confirm from your side.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  if ((_booking['issue_description'] ?? '').toString().trim().isNotEmpty)
                    Text(
                      'Issue: ${_booking['issue_description']}',
                    ),
                  if ((_booking['emergency_priority'] ?? '').toString().trim().isNotEmpty)
                    Text(
                      'Priority: ${_formatStatus((_booking['emergency_priority'] ?? '').toString())}',
                    ),
                  if (_booking['calculated_amount'] != null)
                    Text(
                      'Calculated Pay: ${MoneyUtils.format(_booking['calculated_amount'])}',
                    ),
                  if (completedDate != null)
                    Text('Completed: ${_formatDate(completedDate)}'),
                  if (_booking['otp_verification'] != null) ...[
                    const SizedBox(height: 8),
                    Text('OTP: ${_booking['otp_verification']}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              final bookingId = (_booking['id'] ?? '').toString();
              if (bookingId.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    bookingId: bookingId,
                    title: (_booking['user_name'] ?? '').toString().trim().isNotEmpty
                        ? '${_booking['user_name']}'
                        : 'Booking Chat',
                    subtitle: _isDirectBooking
                        ? (_booking['specialty'] ?? 'Direct repairman booking')
                            .toString()
                        : ((_booking['service_name'] ?? '').toString().trim().isNotEmpty
                              ? '${_booking['service_name']}'
                              : 'Service ${_booking['service_id'] ?? '-'}'),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Open Chat'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openUserLocation,
            icon: const Icon(Icons.location_on_outlined),
            label: Text(
              _hasUserLocation ? 'Track User Location' : 'User Location Unavailable',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                _isUpdating ||
                    ![
                      'pending',
                      'accepted',
                      'in_progress',
                      'booking_confirmed',
                      'reached_destination',
                      'arrival_confirmed',
                      'completion_pending_repairman',
                    ].contains(status)
                    || _buttonLabel(status) == 'Waiting for User'
                ? null
                : _advanceStatus,
            child: _isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_buttonLabel(status)),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isUpdating ? null : _rejectJob,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject Booking'),
            ),
          ],
        ],
      ),
    );
  }
}
