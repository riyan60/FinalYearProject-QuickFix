class Booking {
  final String id;
  final String userId;
  final String repairmanId;
  final String serviceId;
  final DateTime bookingDate;
  final String scheduledTime;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final bool paidFromWallet;
  final Map<String, dynamic> extraData;
  final double? userLatitude;
  final double? userLongitude;

  Booking({
    required this.id,
    required this.userId,
    required this.repairmanId,
    required this.serviceId,
    required this.bookingDate,
    required this.scheduledTime,
    required this.status,
    required this.totalAmount,
    this.paymentMethod = '',
    this.paidFromWallet = false,
    this.extraData = const {},
    this.userLatitude,
    this.userLongitude,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    final userMap = userData is Map ? userData : const {};

    return Booking(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      repairmanId: json['repairman_id'] ?? json['repairmanId'] ?? '',
      serviceId: json['service_id'] ?? json['serviceId'] ?? '',
      bookingDate: _parseBookingDate(json['booking_date']),
      scheduledTime: json['scheduled_time'] ?? '',
      status: json['status'] ?? '',
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse('${json['total_amount'] ?? ''}') ?? 0,
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? '')
          .toString(),
      paidFromWallet:
          json['paid_from_wallet'] == true || json['paidFromWallet'] == true,
      extraData: Map<String, dynamic>.from(json),
      userLatitude:
          double.tryParse(json['user_latitude']?.toString() ?? '') ??
          double.tryParse(json['userLatitude']?.toString() ?? '') ??
          double.tryParse(json['latitude']?.toString() ?? '') ??
          double.tryParse(userMap['latitude']?.toString() ?? '') ??
          double.tryParse(userMap['lat']?.toString() ?? ''),
      userLongitude:
          double.tryParse(json['user_longitude']?.toString() ?? '') ??
          double.tryParse(json['userLongitude']?.toString() ?? '') ??
          double.tryParse(json['longitude']?.toString() ?? '') ??
          double.tryParse(userMap['longitude']?.toString() ?? '') ??
          double.tryParse(userMap['lng']?.toString() ?? ''),
    );
  }

  static DateTime _parseBookingDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is Map && value['_seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as num).toInt() * 1000,
      );
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      ...extraData,
      'id': id,
      'userId': userId,
      'user_id': userId,
      'repairmanId': repairmanId,
      'repairman_id': repairmanId,
      'serviceId': serviceId,
      'service_id': serviceId,
      'booking_date': bookingDate.toIso8601String(),
      'scheduled_time': scheduledTime,
      'status': status,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'paymentMethod': paymentMethod,
      'paid_from_wallet': paidFromWallet,
      'paidFromWallet': paidFromWallet,
      if (userLatitude != null) 'user_latitude': userLatitude,
      if (userLatitude != null) 'userLatitude': userLatitude,
      if (userLongitude != null) 'user_longitude': userLongitude,
      if (userLongitude != null) 'userLongitude': userLongitude,
    };
  }

  String get bookingType =>
      (extraData['booking_type'] ?? extraData['bookingType'] ?? '')
          .toString();

  String get bookingMode =>
      (extraData['booking_mode'] ?? extraData['bookingMode'] ?? '').toString();

  String get specialty =>
      (extraData['specialty'] ?? extraData['service_name'] ?? '').toString();

  String get repairmanName =>
      (extraData['repairman_name'] ?? extraData['repairmanName'] ?? '')
          .toString();

  String get serviceName =>
      (extraData['service_name'] ?? extraData['serviceName'] ?? '').toString();

  String get userName =>
      (extraData['user_name'] ?? extraData['userName'] ?? '').toString();

  bool? get arrivalConfirmedByUser {
    final value =
        extraData['arrival_confirmed_by_user'] ??
        extraData['arrivalConfirmedByUser'];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  bool get userCompletionConfirmed =>
      extraData['user_completion_confirmed'] == true ||
      extraData['userCompletionConfirmed'] == true;

  bool get repairmanCompletionConfirmed =>
      extraData['repairman_completion_confirmed'] == true ||
      extraData['repairmanCompletionConfirmed'] == true;

  bool get reviewSubmitted =>
      extraData['review_submitted'] == true ||
      extraData['reviewSubmitted'] == true;

  bool get isDirectRepairmanBooking => bookingType == 'direct_repairman';
}
