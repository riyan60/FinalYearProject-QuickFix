import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/booking_model.dart';
import 'auth_service.dart';
import 'booking_service.dart';
import 'repairman/repairman_service.dart';

class NotificationService {
  final BookingService _bookingService = BookingService();
  final RepairmanService _repairmanService = RepairmanService();

  String _scopeKey(String suffix) {
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final role = (session['role'] ?? 'guest').toString().trim().toLowerCase();
    final accountId = (session['accountId'] ?? session['id'] ?? 'guest')
        .toString()
        .trim();
    return 'notifications_${role}_${accountId}_$suffix';
  }

  Future<List<AppNotification>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scopeKey('items'));
    if (raw == null || raw.isEmpty) return const <AppNotification>[];

    final decoded = json.decode(raw);
    if (decoded is! List) return const <AppNotification>[];

    return decoded
        .whereType<Map>()
        .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = notifications.map((item) => item.toJson()).toList();
    await prefs.setString(_scopeKey('items'), json.encode(payload));
  }

  Future<void> markAllRead() async {
    final notifications = await loadNotifications();
    final updated = notifications
        .map((item) => item.isRead ? item : item.copyWith(isRead: true))
        .toList();
    await saveNotifications(updated);
  }

  Future<void> markRead(String id) async {
    final notifications = await loadNotifications();
    final updated = notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    await saveNotifications(updated);
  }

  Future<List<AppNotification>> syncNotifications() async {
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final role = (session['role'] ?? '').toString().trim().toLowerCase();
    if (role.isEmpty) return loadNotifications();

    final notifications = await loadNotifications();
    final generated = <AppNotification>[];

    try {
      if (role == 'user') {
        generated.addAll(await _syncUserBookings());
      } else if (role == 'repairman') {
        generated.addAll(await _syncRepairmanBookings());
        generated.addAll(await _syncVerificationStatus());
      }
    } catch (_) {
      return notifications;
    }

    if (generated.isEmpty) {
      return notifications;
    }

    final merged = [...generated, ...notifications];
    final deduped = <String, AppNotification>{};
    for (final item in merged) {
      deduped[item.id] = item;
    }

    final output = deduped.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await saveNotifications(output);
    return output;
  }

  Future<List<AppNotification>> _syncUserBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final previous = _readStringMap(
      prefs.getString(_scopeKey('user_booking_status')),
    );
    final current = <String, String>{};
    final generated = <AppNotification>[];

    final bookings = await _bookingService.getMyBookings();
    final isFirstSync = previous.isEmpty;
    for (final booking in bookings) {
      current[booking.id] = booking.status;
      final oldStatus = previous[booking.id];

      if (isFirstSync) {
        continue;
      }

      if (oldStatus == null) {
        generated.add(
          _buildNotification(
            id: 'booking_created_${booking.id}_${booking.status}',
            type: 'booking',
            title: 'Booking created',
            body:
                'Your ${_bookingLabel(booking)} booking has been created with status ${_statusLabel(booking.status)}.',
          ),
        );
        continue;
      }

      if (oldStatus != booking.status) {
        generated.add(
          _buildNotification(
            id: 'booking_status_${booking.id}_${booking.status}',
            type: 'booking',
            title: 'Booking update',
            body:
                'Your ${_bookingLabel(booking)} booking is now ${_statusLabel(booking.status)}.',
          ),
        );
      }
    }

    await prefs.setString(
      _scopeKey('user_booking_status'),
      json.encode(current),
    );
    return generated;
  }

  Future<List<AppNotification>> _syncRepairmanBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final previousStatuses = _readStringMap(
      prefs.getString(_scopeKey('repairman_booking_status')),
    );
    final previousPendingCount =
        prefs.getInt(_scopeKey('repairman_pending_count')) ?? 0;
    final currentStatuses = <String, String>{};
    final generated = <AppNotification>[];

    final bookings = await _repairmanService.getMyBookings();
    final isFirstSync =
        previousStatuses.isEmpty &&
        !prefs.containsKey(_scopeKey('repairman_pending_count'));
    var pendingCount = 0;

    for (final booking in bookings) {
      currentStatuses[booking.id] = booking.status;
      if (booking.status == 'pending') {
        pendingCount++;
      }

      final oldStatus = previousStatuses[booking.id];
      if (!isFirstSync && oldStatus != null && oldStatus != booking.status) {
        generated.add(
          _buildNotification(
            id: 'repairman_booking_${booking.id}_${booking.status}',
            type: 'job',
            title: 'Job status updated',
            body:
                'Job ${booking.id} is now ${_statusLabel(booking.status)}.',
          ),
        );
      }
    }

    if (!isFirstSync && pendingCount > previousPendingCount) {
      final added = pendingCount - previousPendingCount;
      generated.add(
        _buildNotification(
          id: 'pending_jobs_$pendingCount',
          type: 'job',
          title: 'New job request${added > 1 ? 's' : ''}',
          body:
              added == 1
                  ? 'You have 1 new pending job request.'
                  : 'You have $added new pending job requests.',
        ),
      );
    }

    await prefs.setString(
      _scopeKey('repairman_booking_status'),
      json.encode(currentStatuses),
    );
    await prefs.setInt(_scopeKey('repairman_pending_count'), pendingCount);
    return generated;
  }

  Future<List<AppNotification>> _syncVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final previousStatus =
        prefs.getString(_scopeKey('verification_status')) ?? '';

    final response = await _repairmanService.getMyVerification();
    final verification = Map<String, dynamic>.from(
      (response['verification'] as Map?) ?? const <String, dynamic>{},
    );
    final currentStatus = (verification['status'] ?? 'unverified')
        .toString()
        .trim()
        .toLowerCase();

    await prefs.setString(_scopeKey('verification_status'), currentStatus);
    if (previousStatus.isEmpty || previousStatus == currentStatus) {
      return const <AppNotification>[];
    }

    final rejectionReason = (verification['rejection_reason'] ?? '')
        .toString()
        .trim();

    return [
      _buildNotification(
        id: 'verification_$currentStatus',
        type: 'verification',
        title: 'Verification update',
        body: currentStatus == 'rejected' && rejectionReason.isNotEmpty
            ? 'Your verification was rejected: $rejectionReason'
            : 'Your verification status is now ${_statusLabel(currentStatus)}.',
      ),
    ];
  }

  AppNotification _buildNotification({
    required String id,
    required String title,
    required String body,
    required String type,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
    );
  }

  Map<String, String> _readStringMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, String>{};
    final decoded = json.decode(raw);
    if (decoded is! Map) return <String, String>{};
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return 'updated';
    return normalized
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _bookingLabel(Booking booking) {
    final serviceName = booking.serviceName.trim();
    final specialty = booking.specialty.trim();
    if (serviceName.isNotEmpty) return serviceName;
    if (specialty.isNotEmpty) return specialty;
    return 'service';
  }
}
