import 'dart:convert';

import '../mock/mock_users.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static Map<String, dynamic>? _currentSession;
  static const String _tokenKey = 'auth_token';
  static const String _sessionKey = 'auth_session';

  static Map<String, dynamic>? get currentSession => _currentSession;

  static void mergeSessionProfile(Map<String, dynamic> profile) {
    _currentSession = {
      ...?_currentSession,
      ...profile,
    };
  }

  static Future<void> updateSessionData(Map<String, dynamic> data) async {
    _currentSession = {
      ...?_currentSession,
      ...data,
    };
    await _persistSession();
  }

  static Future<void> restoreSession() async {
    ApiService.setUnauthorizedHandler(clearLocalSession);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final rawSession = prefs.getString(_sessionKey);

    if (token != null && token.isNotEmpty) {
      ApiService.setAuthToken(token);
    }

    if (rawSession != null && rawSession.isNotEmpty) {
      final decoded = json.decode(rawSession);
      if (decoded is Map) {
        _currentSession = Map<String, dynamic>.from(decoded);
      }
    }
  }

  static Future<void> clearLocalSession() async {
    ApiService.setAuthToken(null);
    _currentSession = null;
    await _persistSession();
  }

  static Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = ApiService.authToken;

    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }

    if (_currentSession != null) {
      await prefs.setString(_sessionKey, json.encode(_currentSession));
    } else {
      await prefs.remove(_sessionKey);
    }
  }

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

    final profile = response['profile'];

    _currentSession = {
      'accountId': response['accountId'],
      'role': response['role'],
      'identity': username,
      if (username.contains('@')) 'email': username,
      if (!username.contains('@')) 'username': username,
      if (profile is Map) ...Map<String, dynamic>.from(profile),
    };
    await _persistSession();

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
      _currentSession = {
        'accountId': response['accountId'],
        'role': response['role'] ?? normalizedRole,
        'username': name,
        'name': name,
        'email': email,
        'phone': phone,
      };
      await _persistSession();
    }

    return response;
  }

  Future<Map<String, dynamic>> getCurrentProfile() async {
    final mergedProfile = <String, dynamic>{};
    var accountId = _currentSession?['accountId'];
    var role = _currentSession?['role'];

    final localProfile = _findMockUserProfile();
    if (localProfile.isNotEmpty) {
      mergedProfile.addAll(localProfile);
    }

    try {
      final response = await _apiService.get('/api/auth/me');
      final profile = response['profile'];
      if (profile is Map) {
        mergedProfile.addAll(Map<String, dynamic>.from(profile));
      }
      accountId = response['accountId'] ?? accountId;
      role = response['role'] ?? role;
    } catch (_) {
      // Keep mock and Firebase data when the API is unavailable.
    }

    if (mergedProfile.isNotEmpty || accountId != null || role != null) {
      _currentSession = {
        ...?_currentSession,
        ...mergedProfile,
        if (accountId != null) 'accountId': accountId,
        if (role != null) 'role': role,
      };
    }
    await _persistSession();
    return {
      'accountId': accountId,
      'role': role,
      'profile': Map<String, dynamic>.from(mergedProfile),
    };
  }

  Future<Map<String, dynamic>> updateCurrentProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await _apiService.put('/api/auth/me', data);
    final profile = response['profile'];
    if (profile is Map) {
      mergeSessionProfile(Map<String, dynamic>.from(profile));
      await _persistSession();
    }
    return response;
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      return await _apiService.post('/api/auth/logout', {});
    } catch (_) {
      return {'message': 'Logged out locally'};
    } finally {
      await clearLocalSession();
    }
  }

  Map<String, dynamic> _findMockUserProfile() {
    final session = _currentSession ?? const <String, dynamic>{};
    final accountId = (session['accountId'] ?? session['id'] ?? '')
        .toString()
        .trim();
    final email = (session['email'] ?? '').toString().trim().toLowerCase();
    final name = (session['name'] ?? session['username'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    for (final user in mockUsers) {
      final userId = (user['id'] ?? '').toString().trim();
      final userEmail = (user['email'] ?? '').toString().trim().toLowerCase();
      final userName = (user['name'] ?? '').toString().trim().toLowerCase();

      final matches =
          (accountId.isNotEmpty && userId == accountId) ||
          (email.isNotEmpty && userEmail == email) ||
          (name.isNotEmpty && userName == name);

      if (matches) {
        return Map<String, dynamic>.from(user);
      }
    }

    return const <String, dynamic>{};
  }
}
