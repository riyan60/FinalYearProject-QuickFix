import 'api_service.dart';

class FeedbackService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> submitFeedback({
    required String feedbackType,
    required String subject,
    required String message,
    required String contactName,
    required String contactPhone,
    int? rating,
  }) async {
    final payload = <String, dynamic>{
      'feedback_type': feedbackType,
      'subject': subject,
      'message': message,
      'contact_name': contactName,
      'contact_phone': contactPhone,
    };
    if (rating != null) {
      payload['rating'] = rating;
    }
    return _apiService.post('/api/feedback', payload);
  }
}
