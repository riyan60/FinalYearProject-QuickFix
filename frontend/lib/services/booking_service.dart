import 'api_service.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getBookings(String userId) async {
    final response = await _apiService.get('/bookings?userId=$userId');
    return response['bookings'];
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    return await _apiService.post('/bookings', bookingData);
  }

  Future<Map<String, dynamic>> updateBooking(String bookingId, Map<String, dynamic> updateData) async {
    return await _apiService.post('/bookings/$bookingId', updateData);
  }
}
