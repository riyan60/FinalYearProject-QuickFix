import 'package:flutter/material.dart';

import '../../chat/chat_detail_page.dart';
import '../../map/tracking_screen.dart';
import '../../auth/login_page.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/booking_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/review_service.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();
  late Future<List<Booking>> _bookingsFuture;
  String _selectedStatus = 'pending';
  bool _isHandlingSessionExpiry = false;
  String? _respondingBookingId;
  String? _completingBookingId;
  String? _cancellingBookingId;
  String? _reviewingBookingId;
  final Set<String> _reviewedBookingIds = <String>{};
  final Set<String> _reviewPromptedBookingIds = <String>{};
  bool _reviewSheetOpen = false;

  static const Color _pageColor = Color(0xFFF8F9FE);
  static const Color _primaryColor = Color(0xFF4A80D4);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE7ECF5);
  static const Set<String> _activeStatuses = {
    'accepted',
    'in_progress',
    'booking_confirmed',
    'reached_destination',
    'arrival_confirmed',
    'completion_pending_user',
    'completion_pending_repairman',
  };

  void _redirectToLoginIfNeeded(Object error) {
    final message = error.toString().toLowerCase();
    if (!message.contains('session expired') || _isHandlingSessionExpiry) {
      return;
    }
    _isHandlingSessionExpiry = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _bookingService.getMyBookings();
  }

  Future<void> _reloadBookings() async {
    await AuthService().getCurrentProfile();
    final future = _bookingService.getMyBookings();
    if (mounted) {
      setState(() {
        _bookingsFuture = future;
      });
    }
    await future;
  }

  Future<void> _respondToArrival(String bookingId, bool confirmed) async {
    setState(() {
      _respondingBookingId = bookingId;
    });

    try {
      await _bookingService.respondToArrival(bookingId, confirmed);
      if (!mounted) return;
      await _reloadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmed
                ? 'Arrival confirmed.'
                : 'Arrival denied. The repairman will need to confirm again.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _respondingBookingId = null;
        });
      }
    }
  }

  Future<void> _confirmCompletion(String bookingId) async {
    setState(() {
      _completingBookingId = bookingId;
    });

    try {
      await _bookingService.confirmCompletion(bookingId);
      if (!mounted) return;
      await _reloadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion confirmed. Thank you.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _completingBookingId = null;
        });
      }
    }
  }

  DateTime? _scheduledStartAt(Booking booking) {
    final rawTime = booking.scheduledTime.trim().toUpperCase();
    final baseDate = booking.bookingDate;
    if (rawTime.isEmpty) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day);
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(rawTime);
    if (match == null) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day);
    }

    final hour12 = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3);
    if (hour12 == null || minute == null || period == null) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day);
    }
    if (hour12 < 1 || hour12 > 12 || minute < 0 || minute > 59) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day);
    }

    var hour24 = hour12 % 12;
    if (period == 'PM') hour24 += 12;

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour24,
      minute,
    );
  }

  DateTime? _parseExtraDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['_seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num).toInt() * 1000,
      );
    }
    return null;
  }

  DateTime? _createdAt(Booking booking) {
    return _parseExtraDate(booking.extraData['created_at']) ??
        _parseExtraDate(booking.extraData['createdAt']);
  }

  DateTime? _cancelDeadline(Booking booking) {
    final createdAt = _createdAt(booking);
    final scheduledAt = _scheduledStartAt(booking);
    if (createdAt == null || scheduledAt == null) return null;

    final totalMs = scheduledAt.difference(createdAt).inMilliseconds;
    if (totalMs <= 0) return null;

    final allowedMs = (totalMs * 0.2).round();
    return createdAt.add(Duration(milliseconds: allowedMs));
  }

  bool _canCancelBooking(Booking booking) {
    final status = booking.status.trim().toLowerCase();
    if (status.isEmpty) return false;
    if ({
      'cancelled',
      'completed',
      'rejected',
      'completion_pending_user',
      'completion_pending_repairman',
    }.contains(status)) {
      return false;
    }

    final deadline = _cancelDeadline(booking);
    if (deadline == null) return false;
    final now = DateTime.now();
    return !now.isAfter(deadline);
  }

  Future<void> _cancelBooking(Booking booking) async {
    if (!_canCancelBooking(booking)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cancellation is allowed only in the first 20% of time before the scheduled slot.',
          ),
        ),
      );
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel booking?'),
          content: const Text(
            'You can cancel only during the first 20% of the time between booking creation and scheduled time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    setState(() {
      _cancellingBookingId = booking.id;
    });

    try {
      await _bookingService.updateBookingStatus(booking.id, 'cancelled');
      if (!mounted) return;
      await _reloadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingBookingId = null;
        });
      }
    }
  }

  Future<void> _openReviewSheet(Booking booking) async {
    if (!mounted || _reviewSheetOpen) return;
    _reviewSheetOpen = true;
    _ReviewDraft? draft;
    try {
      draft = await showModalBottomSheet<_ReviewDraft>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _ReviewSheet(
          title: booking.repairmanName.trim().isNotEmpty
              ? booking.repairmanName.trim()
              : 'Booking #${_shortBookingId(booking.id)}',
        ),
      );
    } finally {
      _reviewSheetOpen = false;
    }

    if (!mounted) {
      return;
    }

    _reviewPromptedBookingIds.add(booking.id);

    if (draft == null) return;

    setState(() {
      _reviewingBookingId = booking.id;
    });

    try {
      await _reviewService.addReview(
        bookingId: booking.id,
        rating: draft.rating,
        comment: draft.comment,
      );
      if (!mounted) return;
      setState(() {
        _reviewedBookingIds.add(booking.id);
      });
      await _reloadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reviewingBookingId = null;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'accepted':
      case 'in_progress':
      case 'booking_confirmed':
      case 'reached_destination':
      case 'completion_pending_repairman':
        return Colors.blue;
      case 'completion_pending_user':
        return Colors.deepOrange;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    final normalized = status.trim();
    if (normalized.isEmpty) return 'Pending';

    return normalized
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _shortBookingId(String id) {
    if (id.length <= 10) return id.toUpperCase();
    return id.substring(id.length - 10).toUpperCase();
  }

  String _formatAmount(double amount) {
    if (amount <= 0) return 'To be confirmed';
    return MoneyUtils.format(amount);
  }

  void _promptForPendingReviewIfNeeded(List<Booking> bookings) {
    if (_reviewSheetOpen) return;

    for (final booking in bookings) {
      if (booking.status.trim().toLowerCase() != 'completed') continue;
      if (booking.reviewSubmitted || _reviewedBookingIds.contains(booking.id)) {
        continue;
      }
      if (_reviewPromptedBookingIds.contains(booking.id)) continue;

      _reviewPromptedBookingIds.add(booking.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openReviewSheet(booking);
      });
      break;
    }
  }

  bool _isCompletedBooking(Booking booking) {
    return {
      'completed',
      'cancelled',
      'rejected',
    }.contains(booking.status.trim().toLowerCase());
  }

  bool _isActiveBooking(Booking booking) {
    return _activeStatuses.contains(booking.status.trim().toLowerCase());
  }

  bool _isPendingBooking(Booking booking) {
    return booking.status.trim().toLowerCase() == 'pending' ||
        booking.status.trim().isEmpty;
  }

  bool _isEmergencyBooking(Booking booking) {
    final emergencyRequest =
        booking.extraData['emergency_request'] ??
        booking.extraData['emergencyRequest'];
    final emergencyPriority =
        (booking.extraData['emergency_priority'] ??
                booking.extraData['emergencyPriority'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

    return emergencyRequest == true ||
        emergencyPriority == 'emergency' ||
        emergencyPriority == 'high';
  }

  int _compareByNearestBookingDate(Booking a, Booking b) {
    final now = DateTime.now();
    final aDiff = a.bookingDate.difference(now).inMilliseconds.abs();
    final bDiff = b.bookingDate.difference(now).inMilliseconds.abs();
    return aDiff.compareTo(bDiff);
  }

  List<Booking> _sortPendingBookings(List<Booking> bookings) {
    final sorted = List<Booking>.from(bookings);
    sorted.sort((a, b) {
      final emergencyComparison = (_isEmergencyBooking(b) ? 1 : 0).compareTo(
        _isEmergencyBooking(a) ? 1 : 0,
      );
      if (emergencyComparison != 0) return emergencyComparison;
      return _compareByNearestBookingDate(a, b);
    });
    return sorted;
  }

  List<Booking> _sortCompletedBookings(List<Booking> bookings) {
    final sorted = List<Booking>.from(bookings);
    sorted.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return sorted;
  }

  List<Booking> _filteredBookings(List<Booking> bookings) {
    final filtered = bookings.where((booking) {
      if (_selectedStatus == 'active') return _isActiveBooking(booking);
      if (_selectedStatus == 'completed') return _isCompletedBooking(booking);
      return _isPendingBooking(booking);
    }).toList();

    if (_selectedStatus == 'completed') return _sortCompletedBookings(filtered);
    return _sortPendingBookings(filtered);
  }

  bool _hasPrimaryAction(Booking booking) {
    final status = booking.status.trim().toLowerCase();
    return (booking.isDirectRepairmanBooking &&
            status == 'reached_destination' &&
            booking.arrivalConfirmedByUser != true) ||
        (status == 'completion_pending_user' &&
            !booking.userCompletionConfirmed) ||
        (status == 'completed' &&
            !booking.reviewSubmitted &&
            !_reviewedBookingIds.contains(booking.id)) ||
        _canCancelBooking(booking);
  }

  String _emptyMessage() {
    if (_selectedStatus == 'active') return 'No active bookings found';
    if (_selectedStatus == 'completed')
      return 'No completed or closed bookings yet';
    return 'No pending bookings right now';
  }

  String _heroTitle() {
    if (_selectedStatus == 'active') return 'Active Bookings';
    if (_selectedStatus == 'completed') return 'Completed Bookings';
    return 'Pending Bookings';
  }

  String _heroSubtitle() {
    if (_selectedStatus == 'active') {
      return 'Track repairmen, chat, and confirm progress.';
    }
    if (_selectedStatus == 'completed') {
      return 'Review completed, cancelled, and rejected bookings.';
    }
    return 'Review booking requests that are waiting for confirmation.';
  }

  Widget _buildHero(List<Booking> bookings) {
    final urgentCount = bookings.where(_isEmergencyBooking).length;
    final actionCount = bookings.where(_hasPrimaryAction).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.receipt_long, color: _primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _heroTitle(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _heroSubtitle(),
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Shown', bookings.length, _primaryColor),
              const SizedBox(width: 10),
              _metric('Urgent', urgentCount, Colors.deepOrange),
              const SizedBox(width: 10),
              _metric('Actions', actionCount, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterButton('pending', 'Pending'),
          const SizedBox(width: 8),
          _filterButton('active', 'Active'),
          const SizedBox(width: 8),
          _filterButton('completed', 'Completed'),
        ],
      ),
    );
  }

  Widget _filterButton(String value, String label) {
    final selected = _selectedStatus == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(
        value == 'pending'
            ? Icons.pending_actions_outlined
            : value == 'active'
            ? Icons.handyman_outlined
            : Icons.check_circle_outline,
        size: 18,
      ),
      selectedColor: const Color(0xFFE9EEF9),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _primaryColor : _borderColor),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF3559A8) : _textColor,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEF9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                color: _primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _emptyMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pull down to refresh when a booking status changes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final status = booking.status.isEmpty ? 'pending' : booking.status;
    final isDirectBooking = booking.isDirectRepairmanBooking;
    final directTitle = booking.specialty.trim().isNotEmpty
        ? booking.specialty.trim()
        : 'Direct Repairman Booking';
    final directMode = booking.bookingMode.trim().isNotEmpty
        ? _formatStatus(booking.bookingMode)
        : 'Custom';
    final serviceTitle = booking.serviceName.trim().isNotEmpty
        ? booking.serviceName.trim()
        : 'Service Booking';
    final providerLabel = booking.repairmanName.trim().isNotEmpty
        ? booking.repairmanName.trim()
        : booking.repairmanId;
    final showArrivalActions =
        isDirectBooking &&
        status == 'reached_destination' &&
        booking.arrivalConfirmedByUser != true;
    final arrivalMessage = booking.arrivalConfirmedByUser == true
        ? 'Arrival confirmed by you'
        : booking.arrivalConfirmedByUser == false
        ? 'Arrival not confirmed yet'
        : null;
    final canTrackRepairman =
        booking.repairmanId.trim().isNotEmpty &&
        booking.userLatitude != null &&
        booking.userLongitude != null &&
        ![
          'pending',
          'completed',
          'cancelled',
          'rejected',
          'completion_pending_user',
          'completion_pending_repairman',
        ].contains(status.toLowerCase());
    final canReview =
        status.toLowerCase() == 'completed' &&
        !booking.reviewSubmitted &&
        !_reviewedBookingIds.contains(booking.id);
    final canConfirmCompletion =
        status.toLowerCase() == 'completion_pending_user' &&
        !booking.userCompletionConfirmed;
    final canCancelBooking = _canCancelBooking(booking);
    final completionMessage = booking.userCompletionConfirmed
        ? booking.repairmanCompletionConfirmed
              ? 'Completion confirmed by both sides'
              : 'You confirmed completion. Waiting for repairman.'
        : booking.repairmanCompletionConfirmed
        ? 'Repairman marked this job complete. Please confirm completion.'
        : null;
    final issue =
        (booking.extraData['issue_description'] ??
                booking.extraData['issueDescription'] ??
                '')
            .toString()
            .trim();

    return BookingCard(
      id: _shortBookingId(booking.id),
      title: isDirectBooking ? directTitle : serviceTitle,
      subtitle: isDirectBooking
          ? 'Mode: $directMode'
          : booking.serviceId.isEmpty
          ? 'Service details unavailable'
          : 'Service ID: ${booking.serviceId}',
      provider: providerLabel.isEmpty
          ? 'Repairman assignment pending'
          : isDirectBooking
          ? 'Repairman: $providerLabel'
          : 'Repairman ID: ${booking.repairmanId}',
      date: _formatDate(booking.bookingDate),
      time: booking.scheduledTime.isEmpty ? 'Not set' : booking.scheduledTime,
      price: _formatAmount(booking.totalAmount),
      status: _formatStatus(status),
      statusColor: _statusColor(status),
      showArrivalActions: showArrivalActions,
      isResponding: _respondingBookingId == booking.id,
      onArrivalConfirmed: showArrivalActions
          ? () => _respondToArrival(booking.id, true)
          : null,
      onArrivalDenied: showArrivalActions
          ? () => _respondToArrival(booking.id, false)
          : null,
      arrivalMessage: arrivalMessage,
      completionMessage: completionMessage,
      canConfirmCompletion: canConfirmCompletion,
      isConfirmingCompletion: _completingBookingId == booking.id,
      onConfirmCompletion: canConfirmCompletion
          ? () => _confirmCompletion(booking.id)
          : null,
      canCancel: canCancelBooking,
      isCancelling: _cancellingBookingId == booking.id,
      onCancel: canCancelBooking ? () => _cancelBooking(booking) : null,
      isEmergency: _isEmergencyBooking(booking),
      onOpenChat: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              bookingId: booking.id,
              title: providerLabel.isEmpty ? 'Booking Chat' : providerLabel,
              subtitle: isDirectBooking ? directTitle : serviceTitle,
            ),
          ),
        );
      },
      onTrackRepairman: canTrackRepairman
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TrackingScreen(bookingId: booking.id, booking: booking),
                ),
              );
            }
          : null,
      canReview: canReview,
      isReviewing: _reviewingBookingId == booking.id,
      onReview: canReview ? () => _openReviewSheet(booking) : null,
      reviewSubmitted:
          booking.reviewSubmitted || _reviewedBookingIds.contains(booking.id),
      issue: issue,
      isDirectBooking: isDirectBooking,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _redirectToLoginIfNeeded(snapshot.error!);
            return Center(
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              ),
            );
          }

          final bookings = snapshot.data ?? [];
          _promptForPendingReviewIfNeeded(bookings);
          final visibleBookings = _filteredBookings(bookings);

          return RefreshIndicator(
            onRefresh: _reloadBookings,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildHero(visibleBookings),
                const SizedBox(height: 14),
                _buildFilterBar(),
                const SizedBox(height: 16),
                if (visibleBookings.isEmpty)
                  SizedBox(height: 360, child: _buildEmptyState())
                else
                  ...visibleBookings.map(_buildBookingCard),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewDraft {
  final int rating;
  final String comment;

  const _ReviewDraft({required this.rating, required this.comment});
}

class _ReviewSheet extends StatefulWidget {
  final String title;

  const _ReviewSheet({required this.title});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _ReviewDraft(
        rating: _selectedRating,
        comment: _commentController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Repairman',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(widget.title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _selectedRating = star;
                  });
                },
                icon: Icon(
                  star <= _selectedRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFF9800),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Write a review',
              hintText: 'Share your experience with the repairman',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String id;
  final String title;
  final String subtitle;
  final String provider;
  final String date;
  final String time;
  final String price;
  final String status;
  final Color statusColor;
  final bool showArrivalActions;
  final bool isResponding;
  final VoidCallback? onArrivalConfirmed;
  final VoidCallback? onArrivalDenied;
  final String? arrivalMessage;
  final String? completionMessage;
  final VoidCallback? onOpenChat;
  final VoidCallback? onTrackRepairman;
  final bool isEmergency;
  final bool canConfirmCompletion;
  final bool isConfirmingCompletion;
  final VoidCallback? onConfirmCompletion;
  final bool canReview;
  final bool isReviewing;
  final VoidCallback? onReview;
  final bool reviewSubmitted;
  final bool canCancel;
  final bool isCancelling;
  final VoidCallback? onCancel;
  final String issue;
  final bool isDirectBooking;

  const BookingCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.provider,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    required this.statusColor,
    this.showArrivalActions = false,
    this.isResponding = false,
    this.onArrivalConfirmed,
    this.onArrivalDenied,
    this.arrivalMessage,
    this.completionMessage,
    this.onOpenChat,
    this.onTrackRepairman,
    this.isEmergency = false,
    this.canConfirmCompletion = false,
    this.isConfirmingCompletion = false,
    this.onConfirmCompletion,
    this.canReview = false,
    this.isReviewing = false,
    this.onReview,
    this.reviewSubmitted = false,
    this.canCancel = false,
    this.isCancelling = false,
    this.onCancel,
    this.issue = '',
    this.isDirectBooking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(
                  isDirectBooking
                      ? Icons.engineering_outlined
                      : Icons.home_repair_service_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #$id',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (isEmergency) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Emergency',
                          style: TextStyle(
                            color: Color(0xFFD9481C),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$date - $time',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (issue.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                issue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onOpenChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open Chat'),
                ),
                if (onTrackRepairman != null)
                  TextButton.icon(
                    onPressed: onTrackRepairman,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Track Repairman'),
                  ),
                if (canReview)
                  TextButton.icon(
                    onPressed: isReviewing ? null : onReview,
                    icon: isReviewing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.star_outline_rounded),
                    label: const Text('Rate Repairman'),
                  ),
                if (canConfirmCompletion)
                  TextButton.icon(
                    onPressed: isConfirmingCompletion
                        ? null
                        : onConfirmCompletion,
                    icon: isConfirmingCompletion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: const Text('Confirm Completion'),
                  ),
                if (canCancel)
                  TextButton.icon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Booking'),
                  ),
                if (reviewSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Review Submitted',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showArrivalActions) ...[
            const SizedBox(height: 12),
            const Text(
              'Has the repairman reached your location?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isResponding || onArrivalDenied == null
                        ? null
                        : onArrivalDenied,
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isResponding || onArrivalConfirmed == null
                        ? null
                        : onArrivalConfirmed,
                    child: isResponding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Yes'),
                  ),
                ),
              ],
            ),
          ],
          if (arrivalMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                arrivalMessage!,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (completionMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                completionMessage!,
                style: const TextStyle(
                  color: Color(0xFF9A5B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
