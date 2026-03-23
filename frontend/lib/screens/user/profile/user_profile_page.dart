import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_utils.dart';
import '../../../providers/notification_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/wallet_service.dart';
import '../../../widgets/notification_bell_button.dart';
import '../../auth/login_page.dart';
import '../../location/location_picker_screen.dart';
import '../cart/cart_page.dart';
import '../history/booking_history_page.dart';
import '../home/user_home_page.dart';
import 'user_profile_edit_page.dart';

class InfoPage extends StatelessWidget {
  final String title;
  final String body;

  const InfoPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  final dynamic userData;

  const UserProfilePage({super.key, this.userData});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final WalletService _walletService = WalletService();
  final TextEditingController _walletTopUpController = TextEditingController();
  double _walletBalance = 0;

  Map<String, dynamic> get _profileData {
    final session = AuthService.currentSession ?? <String, dynamic>{};
    final incoming = widget.userData is Map
        ? Map<String, dynamic>.from(widget.userData as Map)
        : <String, dynamic>{};
    return {...session, ...incoming};
  }

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationProvider>().sync();
    });
  }

  @override
  void dispose() {
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

  String _value(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  void _openInfoPage(BuildContext context, String title, String body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoPage(title: title, body: body),
      ),
    );
  }

  Future<void> _showTopUpDialog() async {
    _walletTopUpController.text = '';
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: TextField(
          controller: _walletTopUpController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter amount',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                double.tryParse(_walletTopUpController.text.trim()),
              );
            },
            child: const Text('Add Money'),
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
            'Wallet topped up successfully. Balance: ${MoneyUtils.format(updated)}',
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

  @override
  Widget build(BuildContext context) {
    final data = _profileData;
    final displayName = _value(
      data,
      ['name', 'username', 'identity'],
      'QuickFix Account',
    );
    final secondaryText = _value(
      data,
      ['email', 'identity', 'accountId'],
      'Signed-in account',
    );
    final tertiaryText = _value(data, ['phone', 'role'], 'User');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          NotificationBellButton(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFD6E9FF),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF4A90E2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          secondaryText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          tertiaryText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F4C81), Color(0xFF3BA7B8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QuickFix Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Balance: ${MoneyUtils.format(_walletBalance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use wallet money while booking. Wallet deductions happen for bookings that are successfully saved in the database.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _showTopUpDialog,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F4C81),
                        ),
                        child: const Text('Add Money'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection('Account Info', [
                  _buildListTile(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Wallet',
                    onTap: _showTopUpDialog,
                  ),
                  _buildListTile(
                    context,
                    Icons.badge_outlined,
                    'Account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.notifications_none,
                    'Notifications',
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.lock,
                    'Privacy',
                    onTap: () => _openInfoPage(
                      context,
                      'Privacy',
                      'Authenticated requests use the current session token. Sensitive account fields are not editable from this screen yet.',
                    ),
                  ),
                ]),
                _buildSection('Support & About', [
                  _buildListTile(
                    context,
                    Icons.calendar_today_outlined,
                    'My Bookings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookingHistoryPage(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.help,
                    'Help & Support',
                    onTap: () => _openInfoPage(
                      context,
                      'Help & Support',
                      'For booking issues, use the booking ID from history and the time of the issue so it can be checked against backend records.',
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.info,
                    'Terms and Policies',
                    onTap: () => _openInfoPage(
                      context,
                      'Terms and Policies',
                      'Use QuickFix with valid account information and complete bookings through the app so statuses, payments, and reviews stay consistent.',
                    ),
                  ),
                ]),
                _buildSection('Actions', [
                  _buildListTile(
                    context,
                    Icons.flag,
                    'Report a problem',
                    onTap: () => _openInfoPage(
                      context,
                      'Report a problem',
                      'If something fails, capture the screen, the booking ID, and the time so the backend data can be checked.',
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.person_add,
                    'Switch account',
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.logout,
                    'Log out',
                    onTap: () async {
                      await AuthService().logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHome()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingHistoryPage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
