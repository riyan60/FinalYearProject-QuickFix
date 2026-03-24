import 'package:flutter/material.dart';

import '../../chat/chat_detail_page.dart';
import '../../map/tracking_screen.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';
import '../../../services/review_service.dart';

void main() => runApp(const MaterialApp(home: BookingHistoryPage()));

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();
  late Future<List<Booking>> _bookingsFuture;
  String? _respondingBookingId;
  String? _reviewingBookingId;
  final Set<String> _reviewedBookingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _bookingService.getMyBookings();
  }

  Future<void> _reloadBookings() async {
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
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _respondingBookingId = null;
        });
      }
    }
  }

  Future<void> _openReviewSheet(Booking booking) async {
    int selectedRating = 5;
    final commentController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate Repairman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.repairmanName.trim().isNotEmpty
                        ? booking.repairmanName.trim()
                        : 'Booking #${_shortBookingId(booking.id)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        onPressed: () {
                          setModalState(() {
                            selectedRating = star;
                          });
                        },
                        icon: Icon(
                          star <= selectedRating
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
                    controller: commentController,
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
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final comment = commentController.text.trim();
    commentController.dispose();

    if (submitted != true) return;

    setState(() {
      _reviewingBookingId = booking.id;
    });

    try {
      await _reviewService.addReview(
        bookingId: booking.id,
        rating: selectedRating,
        comment: comment,
      );
      if (!mounted) return;
      setState(() {
        _reviewedBookingIds.add(booking.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
        return Colors.blue;
      case 'cancelled':
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Booking History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
              ),
            );
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reloadBookings,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      'No bookings found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reloadBookings,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final status =
                    booking.status.isEmpty ? 'pending' : booking.status;
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
                    !['pending', 'completed', 'cancelled']
                        .contains(status.toLowerCase());
                final canReview =
                    status.toLowerCase() == 'completed' &&
                    !_reviewedBookingIds.contains(booking.id);

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
                  time: booking.scheduledTime.isEmpty
                      ? 'Not set'
                      : booking.scheduledTime,
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
                  onOpenChat: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          bookingId: booking.id,
                          title: providerLabel.isEmpty
                              ? 'Booking Chat'
                              : providerLabel,
                          subtitle: isDirectBooking
                              ? directTitle
                              : serviceTitle,
                        ),
                      ),
                    );
                  },
                  onTrackRepairman: canTrackRepairman
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrackingScreen(
                                bookingId: booking.id,
                                booking: booking,
                              ),
                            ),
                          );
                        }
                      : null,
                  canReview: canReview,
                  isReviewing: _reviewingBookingId == booking.id,
                  onReview: canReview ? () => _openReviewSheet(booking) : null,
                  reviewSubmitted:
                      _reviewedBookingIds.contains(booking.id),
                );
              },
            ),
          );
        },
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
  final VoidCallback? onOpenChat;
  final VoidCallback? onTrackRepairman;
  final bool canReview;
  final bool isReviewing;
  final VoidCallback? onReview;
  final bool reviewSubmitted;

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
    this.onOpenChat,
    this.onTrackRepairman,
    this.canReview = false,
    this.isReviewing = false,
    this.onReview,
    this.reviewSubmitted = false,
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
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.build, color: Colors.blue),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
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
                  '$date • $time',
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
                    onPressed:
                        isResponding || onArrivalDenied == null
                            ? null
                            : onArrivalDenied,
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isResponding || onArrivalConfirmed == null
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
        ],
      ),
    );
  }
}
