import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  final dynamic userData;

  const UserProfilePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userData != null) ...[
              Text('Name: ${userData.name}'),
              Text('Username: ${userData.username}'),
              Text('Email: ${userData.email}'),
              Text('Phone: ${userData.phone}'),
              Text('Website: ${userData.website}'),
              Text('Company: ${userData.company.name}'),
              Text('Address: ${userData.address.street}, ${userData.address.suite}, ${userData.address.city}, ${userData.address.zipcode}'),
            ] else ...[
              const Text('No user data available'),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement delete account functionality here
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }
}
