import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/cart_provider.dart';
import 'screens/home/home_page.dart';
import 'screens/auth/role_selection_page.dart';
import 'screens/auth/login_page.dart';

void main() => runApp(const QuickFixApp());

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Georgia'), // Using Georgia for that Serif look
        home: const LoginScreen(),
      ),
    );
  }
}


