import 'api_service.dart';

class ChatService {
  final ApiService _apiService = ApiService();

  String _normalizeBookingId(String bookingId) {
    final normalized = bookingId.trim();
    if (normalized.isEmpty) {
      throw Exception('Booking ID is missing for this chat.');
    }
    return normalized;
  }

  Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    final normalizedBookingId = _normalizeBookingId(bookingId);
    final response = await _apiService.get(
      '/api/bookings/$normalizedBookingId/messages',
    );
    final rawMessages = (response['messages'] as List?) ?? const [];
    return rawMessages
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    String bookingId,
    String message,
  ) async {
    final normalizedBookingId = _normalizeBookingId(bookingId);
    return await _apiService.post(
      '/api/bookings/$normalizedBookingId/messages',
      {
        'message': message,
      },
    );
  }
}
