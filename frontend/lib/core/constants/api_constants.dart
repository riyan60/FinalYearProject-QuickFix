class ApiConstants {
  static const String productionBaseUrl =
      'https://quickfix-backend-f6tz.onrender.com';
  static const String defaultWebBaseUrl = productionBaseUrl;
  static const String defaultAndroidEmulatorBaseUrl = 'https://quickfix-backend-f6tz.onrender.com';
  static const String defaultAndroidPhysicalDeviceBaseUrl = productionBaseUrl;
  static const String defaultDesktopBaseUrl = productionBaseUrl;
  static const String loginEndpoint = '/api/auth/login';
  static const String signupEndpoint = '/api/auth/register';
  static const String servicesEndpoint = '/api/services';
  static const String bookingsEndpoint = '/api/bookings';
  static const String usersEndpoint = '/api/auth';
  static const String createOrderEndpoint = '/api/payments/create-order';
  static const String verifyPaymentEndpoint = '/api/payments/verify-payment';
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyATCzXAcqtm5IFqfKmZGnUGjpdbGJ4840U',
  );
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_SSc35Br3QPENtd',
  );
}
