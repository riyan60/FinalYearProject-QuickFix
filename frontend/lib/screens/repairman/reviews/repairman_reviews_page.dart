import 'package:flutter/material.dart';

class RepairmanReviewsPage extends StatelessWidget {
  const RepairmanReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews_outlined, size: 56, color: Colors.blueGrey),
            SizedBox(height: 16),
            Text(
              'Customer reviews are recorded after completed bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'The backend currently supports creating reviews, but it does not expose a review list endpoint yet. This screen stays informational until that endpoint exists.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
