import 'package:flutter/material.dart';

import 'job_requests_page.dart';

class ActiveJobsPage extends StatelessWidget {
  const ActiveJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JobRequestsPage(initialStatus: 'active');
  }
}
