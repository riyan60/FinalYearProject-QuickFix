import 'package:flutter/material.dart';

import '../../../services/repairman/repairman_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final RepairmanService _repairmanService = RepairmanService();
  late final Future<Map<String, dynamic>> _earningsFuture = _repairmanService
      .getMyEarnings();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: const Color(0xFF4A80D4),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              ),
            );
          }

          final data = snapshot.data ?? const {};
          final bookings = (data['bookings'] as List?) ?? const [];
          final totalEarnings = data['total_earnings'] ?? 0;
          final completedJobs = data['completed_jobs'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs $totalEarnings',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Completed Jobs: $completedJobs'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Completed Bookings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (bookings.isEmpty)
                const Text('No completed jobs yet.')
              else
                ...bookings.map((item) {
                  final booking = Map<String, dynamic>.from(item as Map);
                  final date = _parseDate(booking['booking_date']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('Service ${booking['service_id'] ?? '-'}'),
                      subtitle: Text(
                        '${_formatDate(date)} • ${booking['scheduled_time'] ?? 'Not set'}',
                      ),
                      trailing: Text(
                        'Rs ${booking['total_amount'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
