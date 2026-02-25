import '../api_service.dart';

class JobService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getJobRequests() async {
    final response = await _apiService.get('/api/jobs/requests');
    return response['jobs'] ?? [];
  }

  Future<Map<String, dynamic>> acceptJob(String jobId) async {
    return await _apiService.post('/api/jobs/accept', {'jobId': jobId});
  }

  Future<Map<String, dynamic>> completeJob(String jobId) async {
    return await _apiService.post('/api/jobs/complete', {'jobId': jobId});
  }
}
