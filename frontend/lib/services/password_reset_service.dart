import 'api_service.dart';

class PasswordResetService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> requestOtp(String identifier) async {
    return _apiService.post('/api/password/request-otp', {
      'username': identifier,
      'email': identifier,
      'identifier': identifier,
    });
  }

  Future<Map<String, dynamic>> resendOtp(String identifier) async {
    return _apiService.post('/api/password/resend-otp', {
      'username': identifier,
      'email': identifier,
      'identifier': identifier,
    });
  }

  Future<Map<String, dynamic>> verifyOtp(String identifier, String otp) async {
    return _apiService.post('/api/password/verify-otp', {
      'username': identifier,
      'email': identifier,
      'identifier': identifier,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> resetPassword(
    String identifier,
    String newPassword,
  ) async {
    return _apiService.post('/api/password/reset-password', {
      'username': identifier,
      'email': identifier,
      'identifier': identifier,
      'newPassword': newPassword,
    });
  }
}
