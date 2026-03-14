import 'package:flutter/material.dart';

import '../../../services/repairman/job_service.dart';
import 'job_details.dart';

class JobRequestsPage extends StatefulWidget {
  final String initialStatus;

  const JobRequestsPage({super.key, this.initialStatus = 'pending'});

  @override
  State<JobRequestsPage> createState() => _JobRequestsPageState();
}

class _JobRequestsPageState extends State<JobRequestsPage> {
  final JobService _jobService = JobService();
  late String _selectedStatus;
  late Future<List<dynamic>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _jobsFuture = _loadJobs();
  }

  Future<List<dynamic>> _loadJobs() async {
    if (_selectedStatus == 'active') {
      final jobs = await _jobService.getMyJobs();
      return jobs.where((booking) {
        if (booking is! Map) return false;
        final status = (booking['status'] ?? '').toString().toLowerCase();
        return status == 'accepted' || status == 'in_progress';
      }).toList();
    }

    return _jobService.getMyJobs(status: _selectedStatus);
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _jobsFuture = _loadJobs();
    });
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

  Future<void> _updateJobStatus(String bookingId, String status) async {
    try {
      if (status == 'accepted') {
        await _jobService.acceptJob(bookingId);
      } else if (status == 'in_progress') {
        await _jobService.startJob(bookingId);
      } else if (status == 'completed') {
        await _jobService.completeJob(bookingId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
      await _refreshJobs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
                  _jobsFuture = _loadJobs();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshJobs,
              child: FutureBuilder<List<dynamic>>(
                future: _jobsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                      ),
                    );
                  }

                  final jobs = snapshot.data ?? [];
                  if (jobs.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedStatus == 'active'
                            ? 'No active jobs found'
                            : 'No ${_selectedStatus.replaceAll('_', ' ')} jobs found',
                      ),
                    );
                  }

                  return ListView.builder(
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
                                'Service ${booking['service_id'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'User ${booking['user_id'] ?? '-'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                '${_formatDate(scheduledDate)} • ${booking['scheduled_time'] ?? 'Time not set'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                'Amount: Rs ${booking['total_amount'] ?? 0}',
                                style: const TextStyle(color: Colors.black54),
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _selectedStatus == 'completed'
                                          ? null
                                          : () {
                                              if (_selectedStatus ==
                                                  'pending') {
                                                _updateJobStatus(
                                                  bookingId,
                                                  'accepted',
                                                );
                                              } else if ((booking['status'] ??
                                                          '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'accepted') {
                                                _updateJobStatus(
                                                  bookingId,
                                                  'in_progress',
                                                );
                                              } else if ((booking['status'] ??
                                                          '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'in_progress') {
                                                _updateJobStatus(
                                                  bookingId,
                                                  'completed',
                                                );
                                              }
                                            },
                                      child: Text(
                                        _selectedStatus == 'pending'
                                            ? 'Accept'
                                            : (booking['status'] ?? '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'accepted'
                                            ? 'Start'
                                            : (booking['status'] ?? '')
                                                      .toString()
                                                      .toLowerCase() ==
                                                  'in_progress'
                                            ? 'Complete'
                                            : 'Done',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
