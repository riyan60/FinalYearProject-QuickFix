import 'package:flutter/material.dart';

import '../repairman/profile/repairman_profile_page.dart' as repairman_profile;

class RepairmanProfilePage extends StatelessWidget {
  final String name;
  final String rating;
  final Map<String, dynamic> profileData;

  const RepairmanProfilePage({
    super.key,
    required this.name,
    required this.rating,
    required this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    return repairman_profile.RepairmanProfilePage(
      name: name,
      rating: double.tryParse(rating) ?? 0.0,
      profileData: profileData,
    );
  }
}
