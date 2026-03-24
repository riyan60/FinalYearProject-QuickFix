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
}
