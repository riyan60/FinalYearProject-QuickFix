import '../../mock/mock_repairmen.dart';
import '../../models/booking_model.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/money_utils.dart';
import '../api_service.dart';
import '../auth_service.dart';

class RepairmanService {
  final ApiService _apiService = ApiService();
  static const String _withdrawalsPrefix = 'repairman_withdrawals_';

  Future<List<dynamic>> getRepairmanList() async {
    final mergedRepairmen = <String, Map<String, dynamic>>{};

    void addAll(Iterable<Map<String, dynamic>> repairmen, {required bool isMock}) {
      for (final repairman in repairmen) {
        final normalized = _normalizeRepairman(repairman, isMock: isMock);
        final id = (normalized['id'] ?? '').toString();
        if (id.isEmpty) continue;
        mergedRepairmen[id] = {
          ...?mergedRepairmen[id],
          ...normalized,
        };
      }
    }

    addAll(mockRepairmen, isMock: true);

    try {
      final response = await _apiService.getList('/api/repairmen');
      addAll(
        response.whereType<Map>().map((item) => Map<String, dynamic>.from(item)),
        isMock: false,
      );
    } catch (_) {
      // Keep local and Firebase data if the API is unavailable.
    }

    return mergedRepairmen.values.toList();
  }

  Future<Map<String, dynamic>> getRepairmanProfile(String repairmanId) async {
    try {
      return await _apiService.get('/api/repairmen/$repairmanId');
    } catch (_) {
      final repairmen = await getRepairmanList();
      for (final repairman in repairmen.whereType<Map>()) {
        final data = Map<String, dynamic>.from(repairman);
        if (data['id']?.toString() == repairmanId) {
          return data;
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyEarnings() async {
    try {
      return await _apiService.get('/api/repairmen/me/earnings');
    } catch (_) {
      final bookings = await getMyBookings();
      final completedBookings = bookings
          .where((booking) => booking.status == 'completed')
          .toList();
      final totalEarnings = completedBookings.fold<double>(
        0,
        (sum, booking) => sum + booking.totalAmount,
      );

      return {
        'total_earnings': totalEarnings,
        'completed_jobs': completedBookings.length,
        'bookings': completedBookings.map((booking) => booking.toJson()).toList(),
      };
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(
    Map<String, dynamic> data,
  ) async {
    return _apiService.put('/api/repairmen/me/profile', data);
  }

  Future<Map<String, dynamic>> getMyVerification() async {
    return _apiService.get('/api/repairmen/me/verification');
  }

  Future<Map<String, dynamic>> submitMyVerification(
    Map<String, dynamic> data,
  ) async {
    return _apiService.post('/api/repairmen/me/verification', data);
  }

  Future<List<Map<String, dynamic>>> getMyLinkedServices() async {
    final response = await _apiService.get('/api/repairmen/me/services');
    final rawServices = (response['services'] as List?) ?? const [];
    return rawServices
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> addMyService({
    String serviceId = '',
    String serviceName = '',
    String category = '',
    String description = '',
    double customPrice = 0,
  }) async {
    return _apiService.post('/api/repairmen/me/services', {
      if (serviceId.trim().isNotEmpty) 'serviceId': serviceId,
      if (serviceName.trim().isNotEmpty) 'service_name': serviceName,
      if (category.trim().isNotEmpty) 'category': category,
      if (description.trim().isNotEmpty) 'description': description,
      'custom_price': customPrice,
    });
  }

  String _withdrawalsKey() {
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final accountId = session['accountId'] ?? session['id'];
    if (accountId != null && accountId.toString().trim().isNotEmpty) {
      return '$_withdrawalsPrefix${accountId.toString().trim()}';
    }
    return '${_withdrawalsPrefix}guest';
  }

  Future<List<Map<String, dynamic>>> getWithdrawalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_withdrawalsKey());
    if (raw == null || raw.isEmpty) return const <Map<String, dynamic>>[];

    final decoded = json.decode(raw);
    if (decoded is! List) return const <Map<String, dynamic>>[];

    final items = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    items.sort((a, b) {
      final left = DateTime.tryParse('${a['requested_at'] ?? ''}') ?? DateTime(2000);
      final right = DateTime.tryParse('${b['requested_at'] ?? ''}') ?? DateTime(2000);
      return right.compareTo(left);
    });
    return items;
  }

  Future<double> getWithdrawnTotal() async {
    final history = await getWithdrawalHistory();
    return history.fold<double>(0, (sum, item) {
      final value = item['amount'];
      final amount = MoneyUtils.normalize(value);
      return sum + amount;
    });
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String accountHolder,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    String note = '',
  }) async {
    final normalizedAmount = MoneyUtils.normalize(amount);

    if (normalizedAmount <= 0) {
      throw Exception('Withdrawal amount must be greater than zero.');
    }
    if (accountHolder.trim().isEmpty) {
      throw Exception('Account holder name is required.');
    }
    if (bankName.trim().isEmpty) {
      throw Exception('Bank name is required.');
    }
    if (accountNumber.trim().isEmpty) {
      throw Exception('Account number is required.');
    }
    if (ifscCode.trim().isEmpty) {
      throw Exception('IFSC code is required.');
    }

    final earnings = await getMyEarnings();
    final totalEarningsValue = earnings['total_earnings'];
    final totalEarnings = totalEarningsValue is num
        ? totalEarningsValue.toDouble()
        : double.tryParse('$totalEarningsValue') ?? 0;
    final withdrawnTotal = await getWithdrawnTotal();
    final available = totalEarnings - withdrawnTotal;

    if (normalizedAmount > MoneyUtils.normalize(available)) {
      throw Exception('Withdrawal amount exceeds available earnings.');
    }

    final prefs = await SharedPreferences.getInstance();
    final history = await getWithdrawalHistory();
    final request = <String, dynamic>{
      'id': 'wd_${DateTime.now().millisecondsSinceEpoch}',
      'amount': normalizedAmount,
      'account_holder': accountHolder.trim(),
      'bank_name': bankName.trim(),
      'account_number': accountNumber.trim(),
      'ifsc_code': ifscCode.trim().toUpperCase(),
      'note': note.trim(),
      'status': 'requested',
      'requested_at': DateTime.now().toIso8601String(),
    };

    final updated = [request, ...history];
    await prefs.setString(_withdrawalsKey(), json.encode(updated));
    return request;
  }

  Future<List<Booking>> getMyBookings() async {
    final responseData = await _apiService.get('/api/bookings/my');
    final bookingsJson = responseData['bookings'] ?? [];
    return bookingsJson.map<Booking>((json) => Booking.fromJson(json)).toList();
  }

  Map<String, dynamic> _normalizeRepairman(
    Map<String, dynamic> raw, {
    required bool isMock,
  }) {
    final normalized = Map<String, dynamic>.from(raw);
    final latitude = normalized['latitude'] ?? normalized['lat'];
    final longitude = normalized['longitude'] ?? normalized['lng'];
    final specialization =
        normalized['specialization'] ??
        normalized['profession'] ??
        normalized['category'];

    return {
      ...normalized,
      'id':
          normalized['id'] ??
          normalized['account_id'] ??
          normalized['accountId'] ??
          normalized['uid'] ??
          '',
      'name': normalized['name'] ?? normalized['username'] ?? 'Repairman',
      'specialization': specialization ?? 'General repair',
      'category':
          normalized['category'] ??
          specialization ??
          ((normalized['skills'] is List && (normalized['skills'] as List).isNotEmpty)
              ? '${(normalized['skills'] as List).first}'
              : 'General repair'),
      'latitude': latitude,
      'longitude': longitude,
      'availability_status':
          normalized['availability_status'] ??
          normalized['availabilityStatus'] ??
          'available',
      'emergency_service_enabled':
          normalized['emergency_service_enabled'] == true ||
          normalized['emergencyServiceEnabled'] == true ||
          '${normalized['emergency_service_enabled'] ?? normalized['emergencyServiceEnabled']}'.toLowerCase() ==
              'true',
      'verification_status':
          normalized['verification_status'] ??
          normalized['verificationStatus'] ??
          (normalized['is_verified'] == true ? 'verified' : 'unverified'),
      'verification_rejection_reason':
          normalized['verification_rejection_reason'] ??
          normalized['verificationRejectionReason'] ??
          '',
      'is_mock': normalized['is_mock'] ?? isMock,
    };
  }
}
