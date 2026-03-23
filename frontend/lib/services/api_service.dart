import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';

class ApiService {
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBaseUrl.isNotEmpty) return envBaseUrl;

    const androidTarget = String.fromEnvironment(
      'ANDROID_DEVICE_TARGET',
      defaultValue: 'emulator',
    );

    if (kIsWeb) return ApiConstants.defaultWebBaseUrl;
    if (Platform.isAndroid) {
      return androidTarget.toLowerCase() == 'physical'
          ? ApiConstants.defaultAndroidPhysicalDeviceBaseUrl
          : ApiConstants.defaultAndroidEmulatorBaseUrl;
    }
    return ApiConstants.defaultDesktopBaseUrl;
  }

  // Token for authenticated requests
  static String? _authToken;

  // Set the auth token after login
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  // Get the auth token
  static String? get authToken => _authToken;

  // Common headers including Authorization
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  Exception _buildHttpException(
    http.Response response,
    String fallbackMessage,
  ) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message != null && message.toString().isNotEmpty) {
          return Exception(message.toString());
        }
      }
    } catch (_) {
      // Ignore decode failures and fall back to status-based message.
    }
    final body = response.body.trim();
    final preview = body.isEmpty
        ? ''
        : body.length > 160
        ? '${body.substring(0, 160)}...'
        : body;
    final suffix = preview.isEmpty ? '' : ' | Response: $preview';
    return Exception('$fallbackMessage: ${response.statusCode}$suffix');
  }

  Exception _buildNetworkException(
    Object error,
    String endpoint,
  ) {
    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      if (message.contains('network is unreachable') ||
          message.contains('failed host lookup') ||
          message.contains('connection refused')) {
        return Exception(
          'Cannot reach the backend at $baseUrl$endpoint. '
          'If you are using a real phone, start Flutter with '
          '--dart-define=ANDROID_DEVICE_TARGET=physical '
          'or --dart-define=API_BASE_URL=http://YOUR_PC_IP:5000. '
          'Android emulator should use ${ApiConstants.defaultAndroidEmulatorBaseUrl}. '
          'Physical device default is ${ApiConstants.defaultAndroidPhysicalDeviceBaseUrl}.',
        );
      }
    }
    return Exception(error.toString().replaceFirst('Exception: ', ''));
  }

  Future<dynamic> getRaw(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw _buildHttpException(
          response,
          'Failed to load data from $endpoint',
        );
      }
    } catch (error) {
      throw _buildNetworkException(error, endpoint);
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final data = await getRaw(endpoint);
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw Exception('Expected object response for $endpoint');
  }

  Future<List<dynamic>> getList(String endpoint) async {
    final data = await getRaw(endpoint);
    if (data is List) {
      return data;
    }
    throw Exception('Expected list response for $endpoint');
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw _buildHttpException(
          response,
          'Failed to post data to $endpoint',
        );
      }
    } catch (error) {
      throw _buildNetworkException(error, endpoint);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw _buildHttpException(
          response,
          'Failed to update data at $endpoint',
        );
      }
    } catch (error) {
      throw _buildNetworkException(error, endpoint);
    }
  }
}
