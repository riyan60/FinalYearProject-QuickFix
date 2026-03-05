import 'package:flutter/material.dart';

import 'dynamic_service_list_screen.dart';

class ACRepairListScreen extends StatelessWidget {
  const ACRepairListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicServiceListScreen(
      categoryTitle: 'AC Repair',
      categoryIcon: Icons.ac_unit,
      subtitle: 'Professional AC cooling services',
    );
  }
}
