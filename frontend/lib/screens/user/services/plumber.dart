import 'package:flutter/material.dart';

import 'dynamic_service_list_screen.dart';

class PlumberListScreen extends StatelessWidget {
  const PlumberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicServiceListScreen(
      categoryTitle: 'Plumber',
      categoryIcon: Icons.water_drop,
      subtitle: 'Professional plumbing services',
    );
  }
}
