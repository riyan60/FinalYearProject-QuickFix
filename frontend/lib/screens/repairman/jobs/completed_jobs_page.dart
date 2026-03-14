import 'package:flutter/material.dart';

import 'job_requests_page.dart';

class CompletedJobsPage extends StatelessWidget {
  const CompletedJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JobRequestsPage(initialStatus: 'completed');
  }
}
