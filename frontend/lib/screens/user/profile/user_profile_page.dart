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
import '../../shared/feedback_contact_page.dart';

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
      backgroundColor: const Color(0xFFF1F5FB),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E5CC8), Color(0xFF2B86D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -10,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -60,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        secondaryText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFE3EEFF)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tertiaryText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD6E7FF)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeaderPill(
                            icon: Icons.workspace_premium_outlined,
                            label: 'QuickFix User',
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderPill(
                            icon: Icons.account_balance_wallet_outlined,
                            label: MoneyUtils.format(_walletBalance),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C4A86), Color(0xFF178F9E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C4A86).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.wallet_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'QuickFix Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        MoneyUtils.format(_walletBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Top up once and pay instantly during bookings.',
                        style: TextStyle(color: Color(0xFFDDF5F7)),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _showTopUpDialog,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0C4A86),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Money'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.badge_outlined,
                        label: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.calendar_today_outlined,
                        label: 'My Bookings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingHistoryPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.notifications_none_rounded,
                        label: 'Alerts',
                        onTap: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                    ),
                  ],
                ),
                _buildSection('Account', [
                  _buildListTile(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Wallet',
                    subtitle: 'Top up and manage wallet balance',
                    onTap: _showTopUpDialog,
                  ),
                  _buildListTile(
                    context,
                    Icons.badge_outlined,
                    'Account Details',
                    subtitle: 'View and update profile details',
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
                    Icons.lock_outline_rounded,
                    'Privacy',
                    subtitle: 'Session and account privacy information',
                    onTap: () => _openInfoPage(
                      context,
                      'Privacy',
                      'Authenticated requests use the current session token. Sensitive account fields are not editable from this screen yet.',
                    ),
                  ),
                ]),
                _buildSection('Support', [
                  _buildListTile(
                    context,
                    Icons.feedback_outlined,
                    'Feedback & Contact',
                    subtitle: 'Share feedback or contact support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FeedbackContactPage(
                            initialFeedbackType: 'user',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    context,
                    Icons.help_outline_rounded,
                    'Help & Support',
                    subtitle: 'Get help for booking or payment issues',
                    onTap: () => _openInfoPage(
                      context,
                      'Help & Support',
                      'For booking issues, use the booking ID from history and the time of the issue so it can be checked against backend records.',
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.info_outline_rounded,
                    'Terms and Policies',
                    subtitle: 'Important usage guidelines',
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
                    Icons.flag_outlined,
                    'Report a Problem',
                    subtitle: 'Raise a technical or service issue',
                    onTap: () => _openInfoPage(
                      context,
                      'Report a problem',
                      'If something fails, capture the screen, the booking ID, and the time so the backend data can be checked.',
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.person_add_alt_1_outlined,
                    'Switch Account',
                    subtitle: 'Sign in with another account',
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
                    Icons.logout_rounded,
                    'Log Out',
                    subtitle: 'Sign out from this device',
                    danger: true,
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
          padding: const EdgeInsets.only(left: 6, bottom: 10, top: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5EAF2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildHeaderPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4EAF3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E6BE6)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFEAF0FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: danger ? const Color(0xFFC62828) : const Color(0xFF2459C7),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: danger ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }
}
