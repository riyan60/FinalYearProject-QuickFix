import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/utils/location_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../services/booking_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/wallet_service.dart';
import 'booking_success_page.dart';

enum _HourlyBookingMode { byHours, payAsYouGo }

class HourlyRepairmanBookingPage extends StatefulWidget {
  final String repairmanId;
  final String repairmanName;
  final String specialty;
  final double hourlyRate;
  final latlng.LatLng? userLocation;
  final latlng.LatLng? repairmanLocation;

  const HourlyRepairmanBookingPage({
    super.key,
    required this.repairmanId,
    required this.repairmanName,
    required this.specialty,
    required this.hourlyRate,
    this.userLocation,
    this.repairmanLocation,
  });

  @override
  State<HourlyRepairmanBookingPage> createState() =>
      _HourlyRepairmanBookingPageState();
}

class _HourlyRepairmanBookingPageState
    extends State<HourlyRepairmanBookingPage> {
  final BookingService _bookingService = BookingService();
  final WalletService _walletService = WalletService();
  final PaymentService _paymentService = PaymentService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _hours = 1;
  _HourlyBookingMode _bookingMode = _HourlyBookingMode.byHours;
  bool _useWallet = true;
  bool _isSubmitting = false;
  double _walletBalance = 0;

  double get _serviceAmount => _bookingMode == _HourlyBookingMode.byHours
      ? widget.hourlyRate * _hours
      : widget.hourlyRate;

  double get _platformFee => 9;

  double get _travelDistanceKm {
    if (widget.userLocation == null || widget.repairmanLocation == null) {
      return 0;
    }
    return calculateDistance(widget.userLocation!, widget.repairmanLocation!);
  }

  double get _travelCharge {
    if (_travelDistanceKm <= 2) return 0;
    return double.parse((_travelDistanceKm * 10).toStringAsFixed(2));
  }

  double get _totalAmount => _serviceAmount + _platformFee + _travelCharge;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final balance = await _walletService.getBalance();
    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a booking date and time first.')),
      );
      return;
    }

    if (_useWallet && _walletBalance < _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? razorpayPaymentId;
      if (!_useWallet) {
        razorpayPaymentId = await _paymentService.startPayment(
          amountInPaise: (_totalAmount * 100).round(),
        );
      }

      await _bookingService.createBookingWithLocation(
        serviceId: _bookingMode == _HourlyBookingMode.byHours
            ? 'Hourly booking (${_hours} hr) - ${widget.specialty}'
            : 'Pay as you go - ${widget.specialty}',
        repairmanId: widget.repairmanId,
        bookingDate: DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        ).toIso8601String(),
        scheduledTime: _formatTime(_selectedTime),
        totalAmount: _totalAmount,
        paymentMethod: _useWallet ? 'QuickFix Wallet' : 'Razorpay',
        paidFromWallet: _useWallet,
        bookingType: 'direct_repairman',
        bookingMode: _bookingMode == _HourlyBookingMode.byHours
            ? 'by_hours'
            : 'pay_as_you_go',
        hourlyRate: widget.hourlyRate,
        bookedHours: _bookingMode == _HourlyBookingMode.byHours ? _hours : 0,
        repairmanName: widget.repairmanName,
        specialty: widget.specialty,
        extraData: {
          'booking_type': 'direct_repairman',
          'booking_mode': _bookingMode == _HourlyBookingMode.byHours
              ? 'by_hours'
              : 'pay_as_you_go',
          'hourly_rate': widget.hourlyRate,
          'service_amount': _serviceAmount,
          'platform_fee': _platformFee,
          'travel_charge': _travelCharge,
          'travel_distance_km': _travelDistanceKm,
          'booked_hours': _bookingMode == _HourlyBookingMode.byHours
              ? _hours
              : 0,
          'repairman_name': widget.repairmanName,
          'specialty': widget.specialty,
          if (!_useWallet && razorpayPaymentId != null) ...{
            'payment_gateway': 'razorpay',
            'payment_id': razorpayPaymentId,
            'payment_status': 'paid',
          },
        },
        userLatitude: widget.userLocation?.latitude,
        userLongitude: widget.userLocation?.longitude,
      );

      if (_useWallet) {
        final updatedBalance = await _walletService.deduct(_totalAmount);
        if (mounted) {
          setState(() {
            _walletBalance = updatedBalance;
          });
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(
            bookedCount: 1,
            scheduledDate: _selectedDate!,
            scheduledTime: _formatTime(_selectedTime),
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book by Hour'),
        backgroundColor: const Color(0xFF2E6BE6),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.repairmanName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.specialty,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hourly rate: ${MoneyUtils.format(widget.hourlyRate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E6BE6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Charges',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _chargeRow(
                  _bookingMode == _HourlyBookingMode.byHours
                      ? 'Service amount ($_hours hr)'
                      : 'Service amount',
                  MoneyUtils.format(_serviceAmount),
                ),
                const SizedBox(height: 10),
                _chargeRow('Platform fee', MoneyUtils.format(_platformFee)),
                if (_travelCharge > 0) ...[
                  const SizedBox(height: 10),
                  _chargeRow(
                    'Travel fee (${_travelDistanceKm.toStringAsFixed(1)} km)',
                    MoneyUtils.format(_travelCharge),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _chargeRow(
                  'Total payable',
                  MoneyUtils.format(_totalAmount),
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Booking Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SegmentedButton<_HourlyBookingMode>(
                  segments: const [
                    ButtonSegment<_HourlyBookingMode>(
                      value: _HourlyBookingMode.byHours,
                      label: Text('By hours'),
                    ),
                    ButtonSegment<_HourlyBookingMode>(
                      value: _HourlyBookingMode.payAsYouGo,
                      label: Text('Pay as you go'),
                    ),
                  ],
                  selected: {_bookingMode},
                  onSelectionChanged: _isSubmitting
                      ? null
                      : (selection) {
                          setState(() {
                            _bookingMode = selection.first;
                          });
                        },
                ),
                const SizedBox(height: 16),
                if (_bookingMode == _HourlyBookingMode.byHours) ...[
                  const Text(
                    'Select Hours',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _hours > 1 && !_isSubmitting
                            ? () {
                                setState(() {
                                  _hours--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: Text(
                          '$_hours hour${_hours == 1 ? '' : 's'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: !_isSubmitting
                            ? () {
                                setState(() {
                                  _hours++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Pay as you go starts at ${MoneyUtils.format(widget.hourlyRate)}. Additional time can be settled directly with the repairman.',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_formatDate(_selectedDate)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_formatTime(_selectedTime)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet balance: ${MoneyUtils.format(_walletBalance)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _useWallet,
                  title: const Text('Use wallet for hourly booking'),
                  subtitle: Text(
                    _useWallet
                        ? 'Amount will be deducted from your wallet.'
                        : 'You will pay online via Razorpay before booking is confirmed.',
                  ),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _useWallet = value;
                          });
                        },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontSize: 16)),
                Text(
                  MoneyUtils.format(_totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E6BE6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6BE6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Confirm Hourly Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chargeRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 18 : 14,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            color: emphasize ? const Color(0xFF2E6BE6) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
