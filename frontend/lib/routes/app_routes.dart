/// App routes for navigation
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String signupUser = '/signup-user';
  static const String signupRepairman = '/signup-repairman';
  static const String roleSelection = '/role-selection';

  // User routes
  static const String userHome = '/user-home';
  static const String userProfile = '/user-profile';
  static const String cartPage = '/cart';
  static const String bookingSummary = '/booking-summary';
  static const String paymentPage = '/payment';
  static const String bookingSuccess = '/booking-success';
  static const String bookingHistory = '/booking-history';

  // Service routes
  static const String acRepair = '/ac-repair';
  static const String electrician = '/electrician';
  static const String plumber = '/plumber';
  static const String carpenter = '/carpenter';
  static const String mechanic = '/mechanic';
  static const String cleaning = '/cleaning';

  // Repairman routes
  static const String repairmanHome = '/repairman-home';
  static const String repairmanProfile = '/repairman-profile';
  static const String jobRequests = '/job-requests';
  static const String jobDetails = '/job-details';
  static const String activeJobs = '/active-jobs';
  static const String completedJobs = '/completed-jobs';
  static const String earnings = '/earnings';
  static const String reviews = '/reviews';

  // Splash route
  static const String splash = '/splash';
}
