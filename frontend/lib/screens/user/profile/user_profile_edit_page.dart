import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  String _value(Map<String, dynamic> data, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthService.currentSession ?? <String, dynamic>{};

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFDCEAFF),
            child: Icon(Icons.person, size: 54, color: Color(0xFF4A90E2)),
          ),
          const SizedBox(height: 24),
          _infoCard('Name', _value(session, ['name', 'username'], 'Unavailable')),
          _infoCard(
            'Email / Login',
            _value(session, ['email', 'identity'], 'Unavailable'),
          ),
          _infoCard('Phone', _value(session, ['phone'], 'Unavailable')),
          _infoCard('Role', _value(session, ['role'], 'user')),
          _infoCard('Account ID', _value(session, ['accountId'], 'Unavailable')),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'User profile updates are not exposed by the backend yet, so this screen shows the active session details instead of a fake editable form.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
