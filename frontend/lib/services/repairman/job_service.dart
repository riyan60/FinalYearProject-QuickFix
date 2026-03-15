import '../api_service.dart';
import '../../models/booking_model.dart';

class JobService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getJobRequests() async {
    final response = await _apiService.get(
      '/api/repairmen/me/jobs?status=pending',
    );
    return response['jobs'] ?? [];
  }

  Future<List<dynamic>> getMyJobs({String? status}) async {
    final params = status != null ? '?status=$status' : '';
    final response = await _apiService.get('/api/repairmen/me/jobs$params');
    return response['jobs'] ?? [];
  }

  Future<Map<String, dynamic>> acceptJob(String bookingId) async {
    return await _apiService.post(
      '/api/repairmen/me/jobs/$bookingId/accept',
      {},
    );
  }

  Future<Map<String, dynamic>> startJob(String bookingId) async {
    return await _apiService.post(
      '/api/repairmen/me/jobs/$bookingId/start',
      {},
    );
  }

  Future<Map<String, dynamic>> completeJob(String bookingId) async {
    return await _apiService.post(
      '/api/repairmen/me/jobs/$bookingId/complete',
      {},
    );
  }
}
