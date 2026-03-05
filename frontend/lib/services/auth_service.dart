import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    String role,
  ) async {
    final response = await _apiService.post('/api/auth/login', {
      'username': username,
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
    final normalizedRole = role == 'client'
        ? 'user'
        : role == 'technician'
            ? 'repairman'
            : role;

    final response = await _apiService.post('/api/auth/register', {
      'username': name,
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'address': '',
      'role': normalizedRole,
    });

    // Save token after successful signup
    if (response['token'] != null) {
      ApiService.setAuthToken(response['token']);
    }

    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      return await _apiService.post('/api/auth/logout', {});
    } catch (_) {
      return {'message': 'Logged out locally'};
    } finally {
      ApiService.setAuthToken(null);
    }
  }
}
