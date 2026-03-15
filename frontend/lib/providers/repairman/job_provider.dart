import 'package:flutter/foundation.dart';
import '../../../services/repairman/job_service.dart';

class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();
  List<dynamic> _jobs = [];
  bool _isLoading = false;
  String _currentStatus = 'pending';

  List<dynamic> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String get currentStatus => _currentStatus;

  Future<void> loadJobs({String status = 'pending'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentStatus = status;
      _jobs = await _jobService.getMyJobs(status: status);
    } catch (e) {
      debugPrint('Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateJobStatus(String bookingId, String status) async {
    try {
      switch (status) {
        case 'accepted':
          await _jobService.acceptJob(bookingId);
          break;
        case 'in_progress':
          await _jobService.startJob(bookingId);
          break;
        case 'completed':
          await _jobService.completeJob(bookingId);
          break;
      }
      await loadJobs(status: _currentStatus);
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  void refresh() => loadJobs(status: _currentStatus);
}
