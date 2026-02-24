import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    final response = await _apiService.post('/api/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });

    // Save token after successful login
    if (response['token'] != null) {
      ApiService.setAuthToken(response['token']);
    }

    return response;
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String phone,
    String role,
  ) async {
    final response = await _apiService.post('/api/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    });

    // Save token after successful signup
    if (response['token'] != null) {
      ApiService.setAuthToken(response['token']);
    }

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    // Call logout API first (with token) then clear the token
    final response = await _apiService.post('/api/auth/logout', {});
    // Clear token after successful logout
    ApiService.setAuthToken(null);
    return response;
  }
}
