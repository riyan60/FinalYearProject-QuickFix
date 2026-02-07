import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> signup(String name, String email, String password, String phone) async {
    return await _apiService.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });
  }

  Future<Map<String, dynamic>> logout() async {
    return await _apiService.post('/auth/logout', {});
  }
}
