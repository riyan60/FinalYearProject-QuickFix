import 'package:flutter/material.dart';

import 'dynamic_service_list_screen.dart';

class CarpenterListScreen extends StatelessWidget {
  const CarpenterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicServiceListScreen(
      categoryTitle: 'Carpenter',
      categoryIcon: Icons.handyman,
      subtitle: 'Professional carpentry services',
    );
  }
}
