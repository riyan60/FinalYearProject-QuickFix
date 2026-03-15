import 'api_service.dart';

class CityService {
  final ApiService _apiService = ApiService();

  Future<List<String>> getCities() async {
    final response = await _apiService.getList('/api/location/cities');
    return response
        .whereType<Map>()
        .map((item) => (item['name'] ?? item['city'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
