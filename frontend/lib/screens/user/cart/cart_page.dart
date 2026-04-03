import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../core/utils/location_utils.dart';
import '../../../core/utils/money_utils.dart';
import '../../../models/service_model.dart';
import '../../../providers/user/cart_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/repairman/repairman_service.dart';
import '../../../services/booking_service.dart';
import '../../../services/payment_service.dart';
import '../../../services/wallet_service.dart';
import '../../profile/repairman_profile_page.dart';
import '../booking/booking_success_page.dart';

class ServiceCartEntry {
  final Service service;
  final int quantity;

  const ServiceCartEntry({
    required this.service,
    required this.quantity,
  });

  double get subtotal => service.price * quantity;

  ServiceCartEntry copyWith({
    Service? service,
    int? quantity,
  }) {
    return ServiceCartEntry(
      service: service ?? this.service,
      quantity: quantity ?? this.quantity,
    );
  }
}

enum _ConsumableProvision {
  userProvides,
  repairmanProvides,
}

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
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _repairmanSearchController =
      TextEditingController();
  final TextEditingController _walletTopUpController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  bool _useWallet = true;
  _ConsumableProvision _consumableProvision =
      _ConsumableProvision.userProvides;
  String? _selectedRepairmanId;
  Map<String, dynamic>? _selectedRepairmanData;
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
    _paymentService.dispose();
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

  List<ServiceCartEntry> _groupCartItems(List<Service> cartItems) {
    final grouped = <String, ServiceCartEntry>{};

    for (final service in cartItems) {
      final existing = grouped[service.id];
      if (existing == null) {
        grouped[service.id] = ServiceCartEntry(service: service, quantity: 1);
      } else {
        grouped[service.id] = existing.copyWith(quantity: existing.quantity + 1);
      }
    }

    return grouped.values.toList();
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

  Map<String, dynamic>? _selectedRepairmanFromList(
    List<Map<String, dynamic>> repairmen,
  ) {
    if (_selectedRepairmanId == null || _selectedRepairmanId!.isEmpty) {
      return null;
    }

    for (final repairman in repairmen) {
      if ((repairman['id'] ?? '').toString() == _selectedRepairmanId) {
        return repairman;
      }
    }

    return null;
  }

  bool _supportsConsumables(Service service) {
    return _normalizeCategory(service.category) == 'mechanic';
  }

  int _consumableEligibleCount(List<Service> cartItems) {
    return cartItems.where(_supportsConsumables).length;
  }

  bool _shouldShowConsumableChoice(List<Service> cartItems) {
    return _consumableEligibleCount(cartItems) > 0;
  }

  double _consumableChargePerItem() {
    return 450;
  }

  double _additionalConsumableCharge(List<Service> cartItems) {
    if (_consumableProvision != _ConsumableProvision.repairmanProvides ||
        !_shouldShowConsumableChoice(cartItems)) {
      return 0;
    }
    return _consumableEligibleCount(cartItems) * _consumableChargePerItem();
  }

  double _platformFee(List<Service> cartItems) {
    if (cartItems.isEmpty) return 0;
    return 9;
  }

  latlng.LatLng? _repairmanLocation(Map<String, dynamic>? repairman) {
    if (repairman == null) return null;
    final latitude = double.tryParse('${repairman['latitude'] ?? ''}');
    final longitude = double.tryParse('${repairman['longitude'] ?? ''}');
    if (latitude == null || longitude == null) {
      return null;
    }
    return latlng.LatLng(latitude, longitude);
  }

  double _travelDistanceKm(Map<String, dynamic>? repairman) {
    final userLocation = _preferredBookingLocation;
    final repairmanLocation = _repairmanLocation(repairman);
    if (userLocation == null || repairmanLocation == null) {
      return 0;
    }
    return calculateDistance(userLocation, repairmanLocation);
  }

  double _travelCharge(Map<String, dynamic>? repairman) {
    final distanceKm = _travelDistanceKm(repairman);
    if (distanceKm <= 2) return 0;
    return double.parse((distanceKm * 10).toStringAsFixed(2));
  }

  double _grandTotal(
    CartProvider cartProvider,
    Map<String, dynamic>? selectedRepairman,
  ) {
    return cartProvider.totalPrice +
        _additionalConsumableCharge(cartProvider.cartItems) +
        _platformFee(cartProvider.cartItems) +
        _travelCharge(selectedRepairman);
  }

  double _serviceLevelConsumableCharge(Service service) {
    if (_consumableProvision != _ConsumableProvision.repairmanProvides ||
        !_supportsConsumables(service)) {
      return 0;
    }
    return _consumableChargePerItem();
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

    final selectedRepairman =
        _selectedRepairmanData ??
        _selectedRepairmanFromList(
          _bookableRepairmen(await _repairmenFuture),
        );
    final totalAmount = _grandTotal(cartProvider, selectedRepairman);
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
      String? razorpayPaymentId;
      if (!_useWallet) {
        razorpayPaymentId = await _paymentService.startPayment(
          amountInPaise: (totalAmount * 100).round(),
        );
      }

      for (final service in cartProvider.cartItems) {
        final serviceConsumableCharge = _serviceLevelConsumableCharge(service);
        await _bookingService.createBookingWithLocation(
          serviceId: service.id,
          repairmanId: _selectedRepairmanId!,
          bookingDate: DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          ).toIso8601String(),
          scheduledTime: _formatTime(_selectedTime),
          totalAmount: service.price + serviceConsumableCharge,
          paymentMethod: _useWallet ? 'QuickFix Wallet' : 'Razorpay',
          paidFromWallet: _useWallet,
          extraData: {
            'base_service_amount': service.price,
            'consumable_charge': serviceConsumableCharge,
            'platform_fee': _platformFee(cartProvider.cartItems),
            'travel_charge': _travelCharge(selectedRepairman),
            'travel_distance_km': _travelDistanceKm(selectedRepairman),
            'consumables_provided_by':
                _consumableProvision == _ConsumableProvision.userProvides
                ? 'user'
                : 'repairman',
            if (_supportsConsumables(service))
              'consumables_note': _consumableProvision ==
                      _ConsumableProvision.userProvides
                  ? 'Customer will provide required oil or consumables.'
                  : 'Repairman will bring oil or consumables for this job.',
            if (!_useWallet && razorpayPaymentId != null) ...{
              'payment_gateway': 'razorpay',
              'payment_id': razorpayPaymentId,
              'payment_status': 'paid',
            },
          },
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
          final groupedCartItems = _groupCartItems(cartItems);
          final selectedRepairman = _selectedRepairmanData;
          final additionalConsumableCharge = _additionalConsumableCharge(
            cartItems,
          );
          final platformFee = _platformFee(cartItems);
          final travelCharge = _travelCharge(selectedRepairman);
          final travelDistanceKm = _travelDistanceKm(selectedRepairman);
          final grandTotal = _grandTotal(cartProvider, selectedRepairman);

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
                    ...groupedCartItems.map(
                      (entry) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.service.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.service.description,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${MoneyUtils.format(entry.service.price)} each',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subtotal: ${MoneyUtils.format(entry.subtotal)}',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        cartProvider.decrementService(
                                          entry.service.id,
                                        );
                                        final remaining = cartProvider.quantityFor(
                                          entry.service.id,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              remaining == 0
                                                  ? '${entry.service.name} removed from cart'
                                                  : '${entry.service.name} quantity updated to $remaining',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      '${entry.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Color(0xFF2B72E1),
                                      ),
                                      onPressed: () {
                                        cartProvider.addService(entry.service);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${entry.service.name} quantity updated to ${cartProvider.quantityFor(entry.service.id)}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                  final selectedRepairman =
                                      _selectedRepairmanFromList(
                                    bookableRepairmen,
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
                                        final rating = _repairmanRating(item);

                                        return DropdownMenuItem<String>(
                                          value: id,
                                          child: Text(
                                            '$name • ${rating.toStringAsFixed(1)}★',
                                          ),
                                        );
                                      })
                                      .toList();

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        initialValue: validSelectedRepairmanId,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Select repairman',
                                        ),
                                        items: dropdownItems,
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) {
                                                Map<String, dynamic>? next;
                                                for (final item
                                                    in bookableRepairmen) {
                                                  if (item['id']?.toString() ==
                                                      value) {
                                                    next =
                                                        Map<String, dynamic>.from(
                                                          item,
                                                        );
                                                    break;
                                                  }
                                                }
                                                setState(() {
                                                  _selectedRepairmanId = value;
                                                  _selectedRepairmanData = next;
                                                });
                                              },
                                      ),
                                      if (selectedRepairman != null) ...[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              final data =
                                                  Map<String, dynamic>.from(
                                                selectedRepairman,
                                              );
                                              final name = (data['name'] ??
                                                      'Repairman')
                                                  .toString();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      RepairmanProfilePage(
                                                    name: name,
                                                    rating: _repairmanRating(
                                                      data,
                                                    ).toStringAsFixed(1),
                                                    profileData: data,
                                                    userLocation:
                                                        _preferredBookingLocation,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.person_search_outlined,
                                            ),
                                            label: const Text(
                                              'View selected repairman profile',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_shouldShowConsumableChoice(cartItems))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8F3),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFFD9C7),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Materials & extra charges',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'For mechanic jobs, choose who will provide consumables like engine oil. Charges update before you book.',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      RadioListTile<_ConsumableProvision>(
                                        contentPadding: EdgeInsets.zero,
                                        value:
                                            _ConsumableProvision.userProvides,
                                        groupValue: _consumableProvision,
                                        title: const Text(
                                          'I will provide the oil / consumables',
                                        ),
                                        subtitle: const Text(
                                          'No extra consumable charge added.',
                                        ),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) {
                                                if (value == null) return;
                                                setState(() {
                                                  _consumableProvision = value;
                                                });
                                              },
                                      ),
                                      RadioListTile<_ConsumableProvision>(
                                        contentPadding: EdgeInsets.zero,
                                        value: _ConsumableProvision
                                            .repairmanProvides,
                                        groupValue: _consumableProvision,
                                        title: const Text(
                                          'Repairman will bring the oil / consumables',
                                        ),
                                        subtitle: Text(
                                          'Estimated extra charge: ${MoneyUtils.format(additionalConsumableCharge == 0 ? _consumableEligibleCount(cartItems) * _consumableChargePerItem() : additionalConsumableCharge)}',
                                        ),
                                        onChanged: _isSubmitting
                                            ? null
                                            : (value) {
                                                if (value == null) return;
                                                setState(() {
                                                  _consumableProvision = value;
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              if (_shouldShowConsumableChoice(cartItems))
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Item total',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              Text(
                                MoneyUtils.format(cartProvider.totalPrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          if (_shouldShowConsumableChoice(cartItems)) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _consumableProvision ==
                                          _ConsumableProvision.userProvides
                                      ? 'Customer-provided materials'
                                      : 'Repairman materials',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  additionalConsumableCharge == 0
                                      ? 'Rs 0'
                                      : MoneyUtils.format(
                                          additionalConsumableCharge,
                                        ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: additionalConsumableCharge == 0
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFE05A2A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Platform fee',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              Text(
                                MoneyUtils.format(platformFee),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          if (travelCharge > 0) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Travel fee (${travelDistanceKm.toStringAsFixed(1)} km)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                Text(
                                  MoneyUtils.format(travelCharge),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total payable',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                MoneyUtils.format(grandTotal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                            _walletBalance >= grandTotal
                                ? MoneyUtils.format(
                                    _walletBalance - grandTotal,
                                  )
                                : 'Insufficient balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _walletBalance >= grandTotal
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
