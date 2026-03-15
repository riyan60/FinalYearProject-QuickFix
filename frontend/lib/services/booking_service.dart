import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'location_service.dart';
import '../../models/booking_model.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  /// Get current user location and create booking with lat/lng
  Future<Map<String, dynamic>> createBookingWithLocation({
    required String serviceId,
    required String repairmanId,
    required String bookingDate,
    required String scheduledTime,
  }) async {
    // Get user location
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      throw Exception(
        'Location permission denied. Cannot create booking without location.',
      );
    }

    final bookingData = {
      'serviceId': serviceId,
      'repairmanId': repairmanId,
      'bookingDate': bookingDate,
      'scheduledTime': scheduledTime,
      'user_latitude': position.latitude,
      'user_longitude': position.longitude,
    };

    return await _apiService.post('/api/bookings/create', bookingData);
  }

  /// Get my bookings as List<Booking>
  Future<List<Booking>> getMyBookings() async {
    final responseData = await _apiService.get('/api/bookings/my');
    final bookingsJson = responseData['bookings'] ?? [];
    return bookingsJson.map<Booking>((json) => Booking.fromJson(json)).toList();
  }

  /// Legacy method - use createBookingWithLocation instead
  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    return await _apiService.post('/api/bookings/create', bookingData);
  }

  Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    return await _apiService.put('/api/bookings/$bookingId/status', {
      'status': status,
    });
  }
}
