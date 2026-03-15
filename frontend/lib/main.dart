import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user/cart_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/reset_pass_page.dart';
import 'screens/user/emergency/user_emergency_service_booking.dart';
import 'screens/user/emergency/user_emergency_service_booking_confirm.dart';
import 'screens/repairman/jobs/job_requests_page.dart';
import 'routes/app_routes.dart';
import 'screens/repairman/emergency/repairman_emergency_list.dart';
import 'screens/repairman/emergency/repairman_emergency_detail.dart';

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
        // home: const LoginScreen(), // Moved to routes
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.userEmergencyBooking: (context) => const UserEmergencyServiceBookingScreen(),
          AppRoutes.userEmergencyBookingConfirm: (context) => const UserEmergencyBookingConfirmScreen(),
          AppRoutes.jobRequests: (context) => const JobRequestsPage(),
          '/reset-password': (context) => const ResetPasswordPage(),
          AppRoutes.repairmanEmergencyList: (context) => const RepairmanEmergencyListScreen(),
          AppRoutes.repairmanEmergencyDetail: (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
            return RepairmanEmergencyDetailScreen(booking: args ?? {});
          },
        },
      ),
    );
  }
}

