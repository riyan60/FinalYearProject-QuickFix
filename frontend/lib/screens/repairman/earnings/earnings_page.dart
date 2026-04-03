import 'package:flutter/material.dart';

import '../../../core/utils/money_utils.dart';
import '../../../services/repairman/repairman_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final RepairmanService _repairmanService = RepairmanService();

  bool _isLoading = true;
  bool _isWithdrawing = false;
  Map<String, dynamic> _earnings = const <String, dynamic>{};
  List<Map<String, dynamic>> _withdrawals = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _repairmanService.getMyEarnings(),
        _repairmanService.getWithdrawalHistory(),
      ]);

      if (!mounted) return;
      setState(() {
        _earnings = Map<String, dynamic>.from(results[0] as Map);
        _withdrawals = List<Map<String, dynamic>>.from(results[1] as List);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['_seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num).toInt() * 1000,
      );
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _bookingTitle(Map<String, dynamic> booking) {
    final bookingType = (booking['booking_type'] ?? '').toString().trim();
    if (bookingType == 'direct_repairman') {
      final specialty = (booking['specialty'] ?? '').toString().trim();
      final mode = (booking['booking_mode'] ?? '').toString().trim();
      if (specialty.isNotEmpty && mode.isNotEmpty) {
        final formattedMode = mode
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
            )
            .join(' ');
        return '$specialty - $formattedMode';
      }
      if (specialty.isNotEmpty) return specialty;
      return 'Direct Repairman Booking';
    }

    final serviceName = (booking['service_name'] ?? '').toString().trim();
    if (serviceName.isNotEmpty) return serviceName;

    final serviceId = (booking['service_id'] ?? '').toString().trim();
    return serviceId.isEmpty ? 'Service Booking' : 'Service $serviceId';
  }

  double _toAmount(dynamic value) {
    return MoneyUtils.normalize(value);
  }

  Future<void> _showWithdrawDialog() async {
    final totalEarnings = _toAmount(_earnings['total_earnings']);
    final withdrawnAmount = _withdrawals.fold<double>(
      0,
      (sum, item) => sum + _toAmount(item['amount']),
    );
    final availableAmount = totalEarnings - withdrawnAmount;

    final amountController = TextEditingController(
      text: availableAmount > 0 ? availableAmount.toStringAsFixed(0) : '',
    );
    final accountHolderController = TextEditingController();
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ifscController = TextEditingController();
    final noteController = TextEditingController();

    final payload = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Earnings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available to withdraw: ${MoneyUtils.format(availableAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountHolderController,
                decoration: const InputDecoration(labelText: 'Account Holder'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ifscController,
                decoration: const InputDecoration(labelText: 'IFSC Code'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Optional',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'amount': amountController.text.trim(),
                'account_holder': accountHolderController.text.trim(),
                'bank_name': bankNameController.text.trim(),
                'account_number': accountNumberController.text.trim(),
                'ifsc_code': ifscController.text.trim(),
                'note': noteController.text.trim(),
              });
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );

    amountController.dispose();
    accountHolderController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    noteController.dispose();

    if (payload == null) return;

    setState(() {
      _isWithdrawing = true;
    });

    try {
      await _repairmanService.requestWithdrawal(
        amount: double.tryParse(payload['amount'] ?? '') ?? 0,
        accountHolder: payload['account_holder'] ?? '',
        bankName: payload['bank_name'] ?? '',
        accountNumber: payload['account_number'] ?? '',
        ifscCode: payload['ifsc_code'] ?? '',
        note: payload['note'] ?? '',
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted successfully.'),
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
          _isWithdrawing = false;
        });
      }
    }
  }

  Widget _buildSummaryCard() {
    final totalEarnings = _toAmount(_earnings['total_earnings']);
    final completedJobs = _earnings['completed_jobs'] ?? 0;
    final withdrawnAmount = _withdrawals.fold<double>(
      0,
      (sum, item) => sum + _toAmount(item['amount']),
    );
    final availableAmount = totalEarnings - withdrawnAmount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF3BA7B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            MoneyUtils.format(totalEarnings),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed Jobs: $completedJobs',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Available',
                  value: MoneyUtils.format(availableAmount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  label: 'Withdrawn',
                  value: MoneyUtils.format(withdrawnAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isWithdrawing || availableAmount <= 0
                  ? null
                  : _showWithdrawDialog,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F4C81),
              ),
              child: _isWithdrawing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Withdraw Earnings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Withdrawal History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_withdrawals.isEmpty)
          const Text('No withdrawal requests yet.')
        else
          ..._withdrawals.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(MoneyUtils.format(item['amount'])),
                subtitle: Text(
                  '${item['bank_name'] ?? 'Bank'} - ${_formatDate(_parseDate(item['requested_at']))}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (item['status'] ?? 'requested').toString(),
                    style: const TextStyle(
                      color: Color(0xFF8A5A00),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBookingsSection() {
    final bookings = (_earnings['bookings'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Bookings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          const Text('No completed jobs yet.')
        else
          ...bookings.map((item) {
            final booking = Map<String, dynamic>.from(item as Map);
            final date = _parseDate(booking['booking_date']);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(_bookingTitle(booking)),
                subtitle: Text(
                  '${_formatDate(date)} - ${booking['scheduled_time'] ?? 'Not set'}',
                ),
                trailing: Text(
                  MoneyUtils.format(booking['total_amount']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: const Color(0xFF4A80D4),
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildWithdrawalSection(),
                  const SizedBox(height: 20),
                  _buildBookingsSection(),
                ],
              ),
            ),
    );
  }
}
