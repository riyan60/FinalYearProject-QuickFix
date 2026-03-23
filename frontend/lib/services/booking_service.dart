import 'api_service.dart';
import 'auth_service.dart';
import 'location_service.dart';
import '../models/booking_model.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  final ApiService _apiService = ApiService();

  /// Get current user location and create booking with lat/lng
  Future<Map<String, dynamic>> createBookingWithLocation({
    required String serviceId,
    required String repairmanId,
    required String bookingDate,
    required String scheduledTime,
    double totalAmount = 0,
    String paymentMethod = '',
    bool paidFromWallet = false,
    String bookingType = '',
    String bookingMode = '',
    double? hourlyRate,
    int? bookedHours,
    String repairmanName = '',
    String specialty = '',
    Map<String, dynamic>? extraData,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final role = (session['role'] ?? '').toString().trim().toLowerCase();
    if (role.isNotEmpty && role != 'user') {
      throw Exception('Only user accounts can create bookings.');
    }
    if (serviceId.trim().isEmpty) {
      throw Exception('Missing service ID for booking.');
    }
    if (repairmanId.trim().isEmpty) {
      throw Exception('Missing repairman ID for booking.');
    }

    final selectedLatitude =
        userLatitude ??
        double.tryParse('${session['selected_latitude'] ?? ''}');
    final selectedLongitude =
        userLongitude ??
        double.tryParse('${session['selected_longitude'] ?? ''}');

    double? bookingLatitude = selectedLatitude;
    double? bookingLongitude = selectedLongitude;

    if (bookingLatitude == null || bookingLongitude == null) {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        bookingLatitude = position.latitude;
        bookingLongitude = position.longitude;
      }
    }

    if (bookingLatitude == null || bookingLongitude == null) {
      throw Exception(
        'Location permission denied. Cannot create booking without location.',
      );
    }

    final bookingData = {
      'serviceId': serviceId,
      'repairmanId': repairmanId,
      'bookingDate': bookingDate,
      'scheduledTime': scheduledTime,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'paid_from_wallet': paidFromWallet,
      if (bookingType.trim().isNotEmpty) 'booking_type': bookingType.trim(),
      if (bookingMode.trim().isNotEmpty) 'booking_mode': bookingMode.trim(),
      if (hourlyRate != null) 'hourly_rate': hourlyRate,
      if (bookedHours != null) 'booked_hours': bookedHours,
      if (repairmanName.trim().isNotEmpty)
        'repairman_name': repairmanName.trim(),
      if (specialty.trim().isNotEmpty) 'specialty': specialty.trim(),
      'user_latitude': bookingLatitude,
      'user_longitude': bookingLongitude,
      ...?extraData,
    };

    try {
      return await _apiService.post('/api/bookings/create', bookingData);
    } catch (error) {
      final message = error.toString();
      if (message.contains('/api/bookings/create') && message.contains('404')) {
        return await _apiService.post('/api/bookings', bookingData);
      }
      rethrow;
    }
  }

  /// Get my bookings as List<Booking>
  Future<List<Booking>> getMyBookings() async {
    final responseData = await _apiService.getRaw('/api/bookings/my');

    final dynamic bookingsJson;
    if (responseData is Map<String, dynamic>) {
      bookingsJson = responseData['bookings'] ?? const [];
    } else if (responseData is List) {
      bookingsJson = responseData;
    } else {
      throw Exception('Unexpected bookings response from /api/bookings/my');
    }

    final bookings = <Booking>[];
    for (final item in (bookingsJson as List)) {
      if (item is! Map) continue;
      try {
        bookings.add(Booking.fromJson(Map<String, dynamic>.from(item)));
      } catch (error) {
        debugPrint('Skipping malformed booking entry: $error');
      }
    }

    bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return bookings;
  }

  /// Legacy method - use createBookingWithLocation instead
  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    return await createBookingWithLocation(
      serviceId: (bookingData['serviceId'] ?? '').toString(),
      repairmanId: (bookingData['repairmanId'] ?? '').toString(),
      bookingDate: (bookingData['bookingDate'] ?? '').toString(),
      scheduledTime: (bookingData['scheduledTime'] ?? '').toString(),
      totalAmount:
          double.tryParse('${bookingData['total_amount'] ?? ''}') ?? 0,
      paymentMethod: (bookingData['payment_method'] ?? '').toString(),
      paidFromWallet: bookingData['paid_from_wallet'] == true,
      bookingType: (bookingData['booking_type'] ?? '').toString(),
      bookingMode: (bookingData['booking_mode'] ?? '').toString(),
      hourlyRate: bookingData['hourly_rate'] is num
          ? (bookingData['hourly_rate'] as num).toDouble()
          : double.tryParse('${bookingData['hourly_rate'] ?? ''}'),
      bookedHours: bookingData['booked_hours'] is num
          ? (bookingData['booked_hours'] as num).toInt()
          : int.tryParse('${bookingData['booked_hours'] ?? ''}'),
      repairmanName: (bookingData['repairman_name'] ?? '').toString(),
      specialty: (bookingData['specialty'] ?? '').toString(),
      extraData: bookingData,
    );
  }

  Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
  ) async {
    return await _apiService.put('/api/bookings/$bookingId/status', {
      'status': status,
    });
  }

  Future<Map<String, dynamic>> respondToArrival(
    String bookingId,
    bool confirmed,
  ) async {
    return await _apiService.put('/api/bookings/$bookingId/status', {
      'arrival_confirmed': confirmed,
      'status': confirmed ? 'reached_destination' : 'booking_confirmed',
    });
  }
}
