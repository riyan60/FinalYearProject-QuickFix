import 'api_service.dart';

class PasswordResetService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> requestOtp(String username) async {
    return _apiService.post('/api/password/request-otp', {
      'username': username,
    });
  }

  Future<Map<String, dynamic>> resendOtp(String username) async {
    return _apiService.post('/api/password/resend-otp', {'username': username});
  }

  Future<Map<String, dynamic>> verifyOtp(String username, String otp) async {
    return _apiService.post('/api/password/verify-otp', {
      'username': username,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> resetPassword(
    String username,
    String newPassword,
  ) async {
    return _apiService.post('/api/password/reset-password', {
      'username': username,
      'newPassword': newPassword,
    });
  }
}
