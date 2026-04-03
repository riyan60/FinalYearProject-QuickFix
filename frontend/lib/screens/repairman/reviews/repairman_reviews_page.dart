import 'package:flutter/material.dart';

import '../../../services/review_service.dart';

class RepairmanReviewsPage extends StatefulWidget {
  const RepairmanReviewsPage({super.key});

  @override
  State<RepairmanReviewsPage> createState() => _RepairmanReviewsPageState();
}

class _RepairmanReviewsPageState extends State<RepairmanReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _reviewService.getMyRepairmanReviews();
  }

  Future<void> _reload() async {
    final future = _reviewService.getMyRepairmanReviews();
    setState(() {
      _reviewsFuture = future;
    });
    await future;
  }

  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is Map && value['_seconds'] is num) {
      date = DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num).toInt() * 1000,
      );
    }

    if (date == null) return 'Unknown date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildStars(num rating) {
    final safeRating = rating.toInt().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < safeRating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFFF9800),
          size: 18,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final reviews = snapshot.data ?? const [];
          if (reviews.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.reviews_outlined, size: 56, color: Colors.blueGrey),
                  SizedBox(height: 16),
                  Text(
                    'No reviews yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Customer reviews will appear here after completed bookings are reviewed.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final userName = (review['user_name'] ?? '').toString().trim();
                final comment = (review['comment'] ?? '').toString().trim();
                final rating = review['rating'] is num ? review['rating'] as num : 0;
                final specialty = (review['specialty'] ?? '').toString().trim();
                final serviceName = (review['service_name'] ?? '').toString().trim();
                final title = specialty.isNotEmpty
                    ? specialty
                    : serviceName.isNotEmpty
                    ? serviceName
                    : 'Completed Booking';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.isNotEmpty ? userName : 'Customer',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(review['created_at']),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStars(rating),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          comment,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
