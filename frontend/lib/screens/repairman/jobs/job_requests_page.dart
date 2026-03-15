import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/repairman/job_provider.dart';
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

  @override
  void initState() {
    super.initState();
    jobProvider = Provider.of<JobProvider>(context, listen: false);
    _selectedStatus = widget.initialStatus;
    jobProvider.loadJobs(status: _selectedStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    jobProvider.loadJobs(status: _selectedStatus);
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

  Future<void> _updateJobStatus(String bookingId, String status) async {
    try {
      await jobProvider.updateJobStatus(bookingId, status);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Job $status')));
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
                                      child: Text(() {
                                        if (_selectedStatus == 'pending') {
                                          return 'Accept';
                                        } else if ((booking['status'] ?? '')
                                                .toString()
                                                .toLowerCase() ==
                                            'accepted') {
                                          return 'Start';
                                        } else if ((booking['status'] ?? '')
                                                .toString()
                                                .toLowerCase() ==
                                            'in_progress') {
                                          return 'Complete';
                                        } else {
                                          return 'Done';
                                        }
                                      }()),
                                    ),
                                  ),
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
