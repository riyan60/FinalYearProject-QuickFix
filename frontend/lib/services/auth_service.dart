import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    // Backend expects username, not email - use email as username
    final response = await _apiService.post('/api/auth/login', {
      'username': email,
      'password': password,
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
    // Backend expects: username, email, password, fullName, address, role
    // Frontend provides: name, email, password, phone, role
    // Mapping: name->username, name->fullName, phone->address
    // Backend has /register not /signup
    final response = await _apiService.post('/api/auth/register', {
      'username': name,
      'email': email,
      'password': password,
      'fullName': name,
      'address': phone,
      'role': role,
    });

    // Save token after successful signup
    if (response['token'] != null) {
      ApiService.setAuthToken(response['token']);
    }

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    // Clear token on logout
    ApiService.setAuthToken(null);
    return await _apiService.post('/api/auth/logout', {});
  }
}
