// Validation utilities
class Validators {
  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
  );
  static final RegExp _indianPhoneRegex = RegExp(r'^(?:\+91|91|0)?[6-9]\d{9}$');

  static String? validateEmail(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Email is required';
    }
    if (normalized.length > 254 ||
        normalized.contains('..') ||
        !_emailRegex.hasMatch(normalized)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return 'Phone number is required';
    }

    final digitsOnly = normalized.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!_indianPhoneRegex.hasMatch(digitsOnly)) {
      return 'Enter a valid Indian phone number';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
