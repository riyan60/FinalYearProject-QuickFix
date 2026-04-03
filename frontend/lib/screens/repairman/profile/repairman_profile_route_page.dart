import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import 'repairman_profile_page.dart';

class RepairmanProfileRoutePage extends StatelessWidget {
  const RepairmanProfileRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthService.currentSession ?? const <String, dynamic>{};

    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService().getCurrentProfile(),
      builder: (context, snapshot) {
        final response = snapshot.data;
        final profile = Map<String, dynamic>.from(
          (response?['profile'] as Map?) ?? session,
        );
        final name = (profile['name'] ?? session['name'] ?? 'Repairman')
            .toString();
        final rating = double.tryParse(
              '${profile['rating'] ?? session['rating'] ?? 0}',
            ) ??
            0;

        if (snapshot.connectionState == ConnectionState.waiting &&
            response == null &&
            session.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError && profile.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load repairman profile.\n${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return RepairmanProfilePage(
          name: name,
          rating: rating,
          profileData: profile,
        );
      },
    );
  }
}
