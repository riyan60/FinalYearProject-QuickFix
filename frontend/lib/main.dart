import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user/cart_provider.dart';
import 'providers/repairman/job_provider.dart';
import 'providers/notification_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/reset_pass_page.dart';
import 'screens/notifications/notifications_page.dart';
import 'screens/user/home/user_home_page.dart';
import 'screens/user/history/booking_history_page.dart';

import 'screens/auth/login_page.dart';
import 'screens/repairman/earnings/earnings_page.dart';
import 'screens/repairman/dashboard/repairman_home_page.dart';
import 'screens/repairman/jobs/job_details.dart';
import 'screens/repairman/jobs/job_requests_page.dart';
import 'screens/repairman/profile/repairman_profile_route_page.dart';
import 'screens/location/location_picker_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.restoreSession();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  static _AppBootstrapState of(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppBootstrapState>();
    assert(state != null, 'AppBootstrap not found in context');
    return state!;
  }

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Key _appKey = UniqueKey();

  Future<void> reloadApplication() async {
    await AuthService.restoreSession();
    if (!mounted) return;
    setState(() {
      _appKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return QuickFixApp(key: _appKey, onReloadApp: reloadApplication);
  }
}

class QuickFixApp extends StatelessWidget {
  final Future<void> Function() onReloadApp;

  const QuickFixApp({super.key, required this.onReloadApp});

  @override
  Widget build(BuildContext context) {
    final session = AuthService.currentSession;
    final role = (session?['role'] ?? '').toString();
    final Widget home = role == 'repairman'
        ? const DashboardPage()
        : session != null
        ? const UserHome()
        : const LoginScreen();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => JobProvider()),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Georgia'),
        builder: (context, child) {
          return GlobalPullToReload(
            onReload: onReloadApp,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: home,
        routes: {
          '/job-details': (context) => const JobDetailsScreen(),
          '/job-requests': (context) =>
              const JobRequestsPage(initialStatus: 'pending'),
          '/earnings': (context) => const EarningsScreen(),
          '/booking-history': (context) => const BookingHistoryPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
          '/repairman-profile': (context) => const RepairmanProfileRoutePage(),
          '/repairman-map': (context) => const LocationPickerScreen(),
          '/notifications': (context) => const NotificationsPage(),
        },
      ),
    );
  }
}

class GlobalPullToReload extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onReload;

  const GlobalPullToReload({
    super.key,
    required this.child,
    required this.onReload,
  });

  @override
  State<GlobalPullToReload> createState() => _GlobalPullToReloadState();
}

class _GlobalPullToReloadState extends State<GlobalPullToReload> {
  static const double _triggerDistance = 110;
  static const double _topActivationZone = 80;

  double _pullDistance = 0;
  bool _trackingPull = false;
  bool _reloading = false;

  void _handleDragStart(DragStartDetails details) {
    if (_reloading) return;
    _trackingPull = details.globalPosition.dy <= _topActivationZone;
    if (!_trackingPull && _pullDistance != 0) {
      setState(() {
        _pullDistance = 0;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_trackingPull || _reloading) return;
    final nextDistance =
        (_pullDistance + details.delta.dy).clamp(
          0.0,
          _triggerDistance * 1.4,
        ) as double;
    if (nextDistance == _pullDistance) return;
    setState(() {
      _pullDistance = nextDistance;
    });
  }

  Future<void> _handleDragEnd() async {
    if (!_trackingPull) return;
    _trackingPull = false;

    if (_pullDistance >= _triggerDistance && !_reloading) {
      setState(() {
        _reloading = true;
      });
      await widget.onReload();
      if (!mounted) return;
      setState(() {
        _reloading = false;
        _pullDistance = 0;
      });
      return;
    }

    if (_pullDistance != 0) {
      setState(() {
        _pullDistance = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pullDistance / _triggerDistance).clamp(0.0, 1.0) as double;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: (_) => _handleDragEnd(),
      onVerticalDragCancel: () {
        _handleDragEnd();
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: _reloading || progress > 0 ? 6 : 0,
                child: LinearProgressIndicator(
                  value: _reloading ? null : progress,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF3559A8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
