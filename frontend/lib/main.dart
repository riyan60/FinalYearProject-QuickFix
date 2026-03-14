import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user/cart_provider.dart';
import 'screens/auth/reset_pass_page.dart';
import 'screens/user/home/user_home_page.dart';
import 'screens/user/history/booking_history_page.dart';
import 'screens/auth/role_selection_page.dart';
import 'screens/auth/login_page.dart';
import 'screens/repairman/earnings/earnings_page.dart';
import 'screens/repairman/jobs/job_details.dart';
import 'screens/repairman/jobs/job_requests_page.dart';

void main() => runApp(const QuickFixApp());

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Georgia'),
        home: const LoginScreen(),
        routes: {
          '/job-details': (context) => const JobDetailsScreen(),
          '/job-requests': (context) => const JobRequestsPage(),
          '/earnings': (context) => const EarningsScreen(),
          '/booking-history': (context) => const BookingHistoryPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
        },
      ),
    );
  }
}
