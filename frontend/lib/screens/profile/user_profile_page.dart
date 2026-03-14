import 'package:flutter/material.dart';

import '../user/profile/user_profile_page.dart' as user_profile;

class UserProfilePage extends StatelessWidget {
  final dynamic userData;

  const UserProfilePage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return user_profile.UserProfilePage(userData: userData);
  }
}
