import 'api_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> addReview({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    return _apiService.post('/api/reviews', {
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> getMyRepairmanReviews() async {
    final response = await _apiService.get('/api/reviews/me');
    final rawReviews = response['reviews'];
    if (rawReviews is! List) return const [];

    return rawReviews
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
