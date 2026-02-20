import 'api_service.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getMyBookings() async {
    final response = await _apiService.get('/api/booking/my-bookings');
    return response['bookings'] ?? [];
  }

  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    return await _apiService.post('/api/booking/create', bookingData);
  }

  Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    Map<String, dynamic> updateData,
  ) async {
    return await _apiService.put(
      '/api/booking/update-status/$bookingId',
      updateData,
    );
  }
}
