import '../../models/service_model.dart';
import '../api_service.dart';

class ServiceCatalogService {
  final ApiService _apiService = ApiService();

  static const Map<String, List<String>> _categoryKeywords = {
    'ac repair': ['ac', 'refrigerant', 'compressor', 'coil', 'cooling'],
    'electrician': ['electric', 'wiring', 'circuit', 'fan', 'light'],
    'plumber': ['plumb', 'pipe', 'leak', 'drain', 'tap', 'bathroom'],
    'carpenter': ['carpenter', 'furniture', 'wood', 'shelf', 'door'],
    'mechanic': ['mechanic', 'engine', 'oil', 'brake', 'battery', 'tire'],
    'cleaning': ['clean', 'carpet', 'window', 'office', 'renovation'],
  };

  Future<List<Service>> getAllServices() async {
    final response = await _apiService.getList('/api/services');
    return response
        .whereType<Map>()
        .map((item) => Service.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Service>> getServicesByCategory(String category) async {
    final normalizedCategory = category.trim().toLowerCase();
    final allServices = await getAllServices();

    final matches = allServices.where((service) {
      final serviceCategory = service.category.trim().toLowerCase();
      if (serviceCategory == normalizedCategory) {
        return true;
      }

      final keywords = _categoryKeywords[normalizedCategory];
      if (keywords == null || keywords.isEmpty) {
        return false;
      }

      final haystack = '${service.name} ${service.description}'.toLowerCase();
      return keywords.any(haystack.contains);
    }).toList();

    return matches;
  }
}
