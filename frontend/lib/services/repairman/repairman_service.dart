import '../api_service.dart';

class RepairmanService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getRepairmanList() async {
    return await _apiService.getList('/api/repairmen');
  }

  Future<Map<String, dynamic>> getRepairmanProfile(String repairmanId) async {
    final repairmen = await getRepairmanList();
    return repairmen.firstWhere(
      (repairman) => repairman['id'] == repairmanId,
      orElse: () => <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getMyEarnings() async {
    return _apiService.get('/api/repairmen/me/earnings');
  }
}
