import '../api_service.dart';
import '../../models/booking_model.dart';

class RepairmanService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getRepairmanList() async {
    return await _apiService.getList('/api/repairmen');
  }

  Future<Map<String, dynamic>> getRepairmanProfile(String repairmanId) async {
    return await _apiService.get('/api/repairmen/$repairmanId');
  }

  Future<Map<String, dynamic>> getMyEarnings() async {
    return _apiService.get('/api/repairmen/me/earnings');
  }

  Future<List<Booking>> getMyBookings() async {
    final responseData = await _apiService.get('/api/bookings/my');
    final bookingsJson = responseData['bookings'] ?? [];
    return bookingsJson.map<Booking>((json) => Booking.fromJson(json)).toList();
  }
}
