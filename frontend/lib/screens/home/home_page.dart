import 'package:flutter/material.dart';

import '../user/home/user_home_page.dart' as user_home;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const user_home.UserHome();
  }
}
