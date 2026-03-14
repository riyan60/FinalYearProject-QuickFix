import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user/cart_provider.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../services/booking_service.dart';
import '../booking/booking_success_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final BookingService _bookingService = BookingService();
  final RepairmanService _repairmanService = RepairmanService();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  String? _selectedRepairmanId;
  late final Future<List<dynamic>> _repairmenFuture = _repairmanService
      .getRepairmanList();

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

  Future<void> _submitBooking(CartProvider cartProvider) async {
    if (_selectedRepairmanId == null || _selectedRepairmanId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a repairman first.')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a booking date and time first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      for (final service in cartProvider.cartItems) {
        await _bookingService.createBooking({
          'serviceId': service.id,
          'repairmanId': _selectedRepairmanId,
          'bookingDate': DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          ).toIso8601String(),
          'scheduledTime': _formatTime(_selectedTime),
        });
      }

      final bookedCount = cartProvider.cartItems.length;
      cartProvider.clearCart();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessPage(
            bookedCount: bookedCount,
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
        title: const Text('Cart'),
        backgroundColor: const Color(0xFF2B72E1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.cartItems;

          if (cartItems.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  children: [
                    ...cartItems.map(
                      (service) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(
                            'Rs ${service.price.toStringAsFixed(2)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              cartProvider.removeService(service);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${service.name} removed from cart',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Choose repairman',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FutureBuilder<List<dynamic>>(
                                future: _repairmenFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const LinearProgressIndicator();
                                  }

                                  if (snapshot.hasError) {
                                    return const Text(
                                      'Failed to load repairmen.',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }

                                  final repairmen = snapshot.data ?? [];
                                  if (repairmen.isEmpty) {
                                    return const Text(
                                      'No repairmen available.',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }

                                  final dropdownItems = repairmen
                                      .whereType<Map>()
                                      .map((repairman) {
                                        final item = Map<String, dynamic>.from(
                                          repairman,
                                        );
                                        final id = (item['id'] ?? '')
                                            .toString();
                                        final name =
                                            (item['name'] ?? 'Repairman')
                                                .toString();
                                        final status =
                                            (item['availability_status'] ??
                                                    'unknown')
                                                .toString();

                                        return DropdownMenuItem<String>(
                                          value: id,
                                          child: Text('$name ($status)'),
                                        );
                                      })
                                      .where((item) => item.value != null)
                                      .toList();

                                  return DropdownButtonFormField<String>(
                                    initialValue: _selectedRepairmanId,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Select repairman',
                                    ),
                                    items: dropdownItems,
                                    onChanged: _isSubmitting
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedRepairmanId = value;
                                            });
                                          },
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Schedule your booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _pickDate,
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(_formatDate(_selectedDate)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _pickTime,
                                      icon: const Icon(Icons.access_time),
                                      label: Text(_formatTime(_selectedTime)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs ${cartProvider.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitBooking(cartProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                'Proceed to Book',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
