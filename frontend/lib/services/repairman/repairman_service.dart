import '../api_service.dart';

class RepairmanService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getRepairmanList() async {
    final response = await _apiService.get('/api/repairman/list');
    return response['repairmen'] ?? [];
  }

  Future<Map<String, dynamic>> getRepairmanProfile(String repairmanId) async {
    return await _apiService.get('/api/repairman/$repairmanId');
  }
}
