import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user/cart_provider.dart';
import 'providers/repairman/job_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/reset_pass_page.dart';
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
  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Georgia'),
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
        },
      ),
    );
  }
}
