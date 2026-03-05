import 'package:flutter/material.dart';

import 'dynamic_service_list_screen.dart';

class CleaningListScreen extends StatelessWidget {
  const CleaningListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicServiceListScreen(
      categoryTitle: 'Cleaning',
      categoryIcon: Icons.cleaning_services,
      subtitle: 'Professional cleaning services',
    );
  }
}
