import 'package:flutter/foundation.dart';

class JobProvider extends ChangeNotifier {
  List<dynamic> _jobs = [];
  bool _isLoading = false;

  List<dynamic> get jobs => _jobs;
  bool get isLoading => _isLoading;

  void setJobs(List<dynamic> jobs) {
    _jobs = jobs;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
