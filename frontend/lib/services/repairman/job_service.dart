import '../api_service.dart';

class JobService {
  final ApiService _apiService = ApiService();

  static const Set<String> _activeStatuses = {
    'accepted',
    'in_progress',
    'booking_confirmed',
    'reached_destination',
    'arrival_confirmed',
    'completion_pending_user',
    'completion_pending_repairman',
  };

  Future<List<dynamic>> getJobRequests() async {
    return getMyJobs(status: 'pending');
  }

  Future<List<dynamic>> getMyJobs({String? status}) async {
    final params = status != null && status.isNotEmpty ? '?status=$status' : '';
    try {
      final response = await _apiService.get('/api/repairmen/me/jobs$params');
      final jobs = (response['jobs'] as List?) ?? const [];
      if (jobs.isNotEmpty || status == null || status.isEmpty) {
        return jobs;
      }
    } catch (error) {
      if (status == null || status.isEmpty) rethrow;
    }

    final fallbackResponse = await _apiService.getRaw('/api/bookings/my');
    final dynamic rawBookings = fallbackResponse is Map<String, dynamic>
        ? (fallbackResponse['bookings'] ?? const [])
        : fallbackResponse;
    final bookings = rawBookings is List ? rawBookings : const [];

    if (status == null || status.isEmpty) {
      return bookings;
    }

    return bookings.where((item) {
      if (item is! Map) return false;
      final bookingStatus = (item['status'] ?? '').toString().toLowerCase();
      if (status == 'active') {
        return _activeStatuses.contains(bookingStatus);
      }
      return bookingStatus == status.toLowerCase();
    }).toList();
  }

  Future<Map<String, dynamic>> acceptJob(
    String bookingId, {
    String fallbackStatus = 'accepted',
  }) async {
    try {
      return await _apiService.post(
        '/api/repairmen/me/jobs/$bookingId/accept',
        {},
      );
    } catch (error) {
      final message = error.toString();
      if (message.contains('404')) {
        try {
          return await _apiService.put('/api/bookings/$bookingId/status', {
            'status': fallbackStatus,
          });
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> startJob(
    String bookingId, {
    String fallbackStatus = 'in_progress',
  }) async {
    try {
      return await _apiService.post(
        '/api/repairmen/me/jobs/$bookingId/start',
        {},
      );
    } catch (error) {
      final message = error.toString();
      if (message.contains('404')) {
        try {
          return await _apiService.put('/api/bookings/$bookingId/status', {
            'status': fallbackStatus,
          });
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reachDestination(String bookingId) async {
    return startJob(bookingId, fallbackStatus: 'reached_destination');
  }

  Future<Map<String, dynamic>> completeJob(String bookingId) async {
    try {
      return await _apiService.post(
        '/api/repairmen/me/jobs/$bookingId/complete',
        {},
      );
    } catch (error) {
      final message = error.toString();
      if (
          message.contains('404') ||
          message.contains('Cannot complete booking from current status')) {
        try {
          return await _apiService.put('/api/bookings/$bookingId/status', {
            'status': 'completed',
          });
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectJob(String bookingId) async {
    return await _apiService.put('/api/bookings/$bookingId/status', {
      'status': 'rejected',
    });
  }
}
