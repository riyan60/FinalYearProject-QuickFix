import 'package:flutter/material.dart';

import 'dynamic_service_list_screen.dart';

class MechanicListScreen extends StatelessWidget {
  const MechanicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicServiceListScreen(
      categoryTitle: 'Mechanic',
      categoryIcon: Icons.directions_car,
      subtitle: 'Professional car repair services',
    );
  }
}
