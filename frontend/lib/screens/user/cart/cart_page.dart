import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/utils/money_utils.dart';
import '../../../providers/user/cart_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/wallet_service.dart';
import '../booking/booking_success_page.dart';

class CartPage extends StatefulWidget {
  final String? initialRepairmanId;
  final latlng.LatLng? initialUserLocation;

  const CartPage({
    super.key,
    this.initialRepairmanId,
    this.initialUserLocation,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final BookingService _bookingService = BookingService();
  final RepairmanService _repairmanService = RepairmanService();
  final WalletService _walletService = WalletService();
  final TextEditingController _repairmanSearchController =
      TextEditingController();
  final TextEditingController _walletTopUpController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  bool _useWallet = true;
  String? _selectedRepairmanId;
  double _walletBalance = 0;
  late final Future<List<dynamic>> _repairmenFuture = _repairmanService
      .getRepairmanList();

  latlng.LatLng? get _preferredBookingLocation {
    if (widget.initialUserLocation != null) {
      return widget.initialUserLocation;
    }

    final session = AuthService.currentSession ?? const <String, dynamic>{};
    final latitude = double.tryParse('${session['selected_latitude'] ?? ''}');
    final longitude = double.tryParse('${session['selected_longitude'] ?? ''}');
    if (latitude == null || longitude == null) {
      return null;
    }
    return latlng.LatLng(latitude, longitude);
  }

  @override
  void initState() {
    super.initState();
    _selectedRepairmanId = widget.initialRepairmanId;
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _repairmanSearchController.dispose();
    _walletTopUpController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    final balance = await _walletService.getBalance();
    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
    });
  }

  Future<void> _showTopUpDialog() async {
    _walletTopUpController.text = '';
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money to Wallet'),
        content: TextField(
          controller: _walletTopUpController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter top-up amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_walletTopUpController.text.trim());
              Navigator.pop(context, value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    try {
      final updated = await _walletService.topUp(amount);
      if (!mounted) return;
      setState(() {
        _walletBalance = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wallet updated. New balance: ${MoneyUtils.format(updated)}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  List<Map<String, dynamic>> _bookableRepairmen(List<dynamic> repairmen) {
    return repairmen
        .whereType<Map>()
        .map((repairman) => Map<String, dynamic>.from(repairman))
        .where((item) => item['is_mock'] != true)
        .toList();
  }

  String _normalizeCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('electric')) return 'electrician';
    if (normalized.contains('plumb')) return 'plumber';
    if (normalized.contains('carpent')) return 'carpenter';
    if (normalized.contains('mechanic')) return 'mechanic';
    if (normalized.contains('clean')) return 'cleaning';
    if (normalized.contains('ac')) return 'ac repair';
    return normalized;
  }

  Set<String> _requiredCategories(List<dynamic> cartItems) {
    return cartItems
        .map((item) => _normalizeCategory(item.category))
        .where((category) => category.isNotEmpty)
        .toSet();
  }

  Set<String> _repairmanCategories(Map<String, dynamic> item) {
    final categories = <String>{};

    void addValue(dynamic value) {
      if (value == null) return;
      final normalized = _normalizeCategory(value.toString());
      if (normalized.isNotEmpty) {
        categories.add(normalized);
      }
    }

    addValue(item['specialization']);
    addValue(item['category']);
    addValue(item['profession']);

    final skills = item['skills'];
    if (skills is List) {
      for (final skill in skills) {
        addValue(skill);
      }
    }

    return categories;
  }

  double _repairmanRating(Map<String, dynamic> item) {
    final rating = item['rating'];
    if (rating is num) {
      return rating.toDouble();
    }
    return double.tryParse('$rating') ?? 0;
  }

  List<Map<String, dynamic>> _filteredRepairmen(
    List<dynamic> repairmen,
    List<dynamic> cartItems,
  ) {
    final requiredCategories = _requiredCategories(cartItems);
    final query = _repairmanSearchController.text.trim().toLowerCase();

    final filtered = _bookableRepairmen(repairmen).where((item) {
      final repairmanCategories = _repairmanCategories(item);
      final matchesCategory =
          requiredCategories.isEmpty ||
          requiredCategories.every(repairmanCategories.contains);
      if (!matchesCategory) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = (item['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final ratingCompare = _repairmanRating(b).compareTo(_repairmanRating(a));
      if (ratingCompare != 0) {
        return ratingCompare;
      }

      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    return filtered;
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

    final totalAmount = cartProvider.totalPrice;
    if (_useWallet && _walletBalance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance. Please add money first.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      for (final service in cartProvider.cartItems) {
        await _bookingService.createBookingWithLocation(
          serviceId: service.id,
          repairmanId: _selectedRepairmanId!,
          bookingDate: DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          ).toIso8601String(),
          scheduledTime: _formatTime(_selectedTime),
          totalAmount: service.price,
          paymentMethod: _useWallet ? 'QuickFix Wallet' : 'Cash on Service',
          paidFromWallet: _useWallet,
          userLatitude: _preferredBookingLocation?.latitude,
          userLongitude: _preferredBookingLocation?.longitude,
        );
      }

      if (_useWallet) {
        final updatedBalance = await _walletService.deduct(totalAmount);
        if (mounted) {
          setState(() {
            _walletBalance = updatedBalance;
          });
        }
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
                            MoneyUtils.format(service.price),
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
                              TextField(
                                controller: _repairmanSearchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  hintText: 'Search repairman by name',
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
                                  final bookableRepairmen =
                                      _filteredRepairmen(
                                    repairmen,
                                    cartItems,
                                  );
                                  if (bookableRepairmen.isEmpty) {
                                    final categories = _requiredCategories(
                                      cartItems,
                                    );
                                    final categoryLabel = categories.join(', ');

                                    return Text(
                                      categoryLabel.isEmpty
                                          ? 'No bookable repairmen available.'
                                          : 'No repairmen found for $categoryLabel.',
                                      style: const TextStyle(
                                        color: Colors.red,
                                      ),
                                    );
                                  }

                                  final validSelectedRepairmanId =
                                      bookableRepairmen.any(
                                        (item) =>
                                            item['id']?.toString() ==
                                            _selectedRepairmanId,
                                      )
                                      ? _selectedRepairmanId
                                      : null;

                                  final dropdownItems = bookableRepairmen.map((
                                    item,
                                  ) {
                                        final id = (item['id'] ?? '')
                                            .toString();
                                        final name =
                                            (item['name'] ?? 'Repairman')
                                                .toString();
                                        final status =
                                            (item['availability_status'] ??
                                                    'unknown')
                                                .toString();
                                        final rating = _repairmanRating(item);

                                        return DropdownMenuItem<String>(
                                          value: id,
                                          child: Text(
                                            '$name • ${rating.toStringAsFixed(1)}★ • $status',
                                          ),
                                        );
                                      })
                                      .toList();

                                  return DropdownButtonFormField<String>(
                                    initialValue: validSelectedRepairmanId,
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
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F8FC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'QuickFix Wallet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _showTopUpDialog,
                                          child: const Text('Add Money'),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Available balance: ${MoneyUtils.format(_walletBalance)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: _useWallet,
                                      title: const Text('Use wallet for this booking'),
                                      subtitle: Text(
                                        _useWallet
                                            ? 'Booking amount will be deducted from wallet after the booking is saved in the database.'
                                            : 'Booking will be created without wallet deduction.',
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
                          MoneyUtils.format(cartProvider.totalPrice),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_useWallet)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Wallet after booking:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            _walletBalance >= cartProvider.totalPrice
                                ? MoneyUtils.format(
                                    _walletBalance - cartProvider.totalPrice,
                                  )
                                : 'Insufficient balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _walletBalance >= cartProvider.totalPrice
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    if (_useWallet) const SizedBox(height: 12),
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
