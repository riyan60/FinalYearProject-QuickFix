import 'package:flutter/material.dart';

import 'dynamic_service_list_screen.dart';

class ElectricianListScreen extends StatelessWidget {
  const ElectricianListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicServiceListScreen(
      categoryTitle: 'Electrician',
      categoryIcon: Icons.bolt,
      subtitle: 'Professional electrical services',
    );
  }
}
