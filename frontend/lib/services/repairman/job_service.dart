import '../api_service.dart';

class JobService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getMyJobs({String? status}) async {
    final response = await _apiService.get('/api/bookings/my');
    final bookings = (response['bookings'] as List?) ?? const [];

    if (status == null || status.isEmpty) {
      return bookings;
    }

    return bookings.where((booking) {
      if (booking is! Map) return false;
      return (booking['status'] ?? '').toString().toLowerCase() ==
          status.toLowerCase();
    }).toList();
  }

  Future<List<dynamic>> getJobRequests() async {
    return getMyJobs(status: 'pending');
  }

  Future<Map<String, dynamic>> acceptJob(String jobId) async {
    return _apiService.put('/api/bookings/$jobId/status', {
      'status': 'accepted',
    });
  }

  Future<Map<String, dynamic>> startJob(String jobId) async {
    return _apiService.put('/api/bookings/$jobId/status', {
      'status': 'in_progress',
    });
  }

  Future<Map<String, dynamic>> completeJob(String jobId) async {
    return _apiService.put('/api/bookings/$jobId/status', {
      'status': 'completed',
    });
  }
}
