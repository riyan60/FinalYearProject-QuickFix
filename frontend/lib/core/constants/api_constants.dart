class ApiConstants {
  static const String productionBaseUrl =
      'http://10.0.2.2:5000';
  static const String defaultWebBaseUrl = productionBaseUrl;
  static const String defaultAndroidEmulatorBaseUrl = productionBaseUrl;
  static const String defaultAndroidPhysicalDeviceBaseUrl = productionBaseUrl;
  static const String defaultDesktopBaseUrl = productionBaseUrl;
  static const String loginEndpoint = '/api/auth/login';
  static const String signupEndpoint = '/api/auth/register';
  static const String servicesEndpoint = '/api/services';
  static const String bookingsEndpoint = '/api/bookings';
  static const String usersEndpoint = '/api/auth';
  static const String createOrderEndpoint = '/api/payments/create-order';
  static const String verifyPaymentEndpoint = '/api/payments/verify-payment';
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_SSc35Br3QPENtd',
  );
}
