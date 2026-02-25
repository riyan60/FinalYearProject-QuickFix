import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(),
            ),
            SizedBox(height: 20),
            Text('QuickFix Loading...'),
          ],
        ),
      ),
    );
  }
}
