class Booking {
  final String id;
  final String userId;
  final String repairmanId;
  final String serviceId;
  final DateTime bookingDate;
  final String scheduledTime;
  final String status;
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
    this.userLatitude,
    this.userLongitude,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      repairmanId: json['repairman_id'] ?? json['repairmanId'] ?? '',
      serviceId: json['service_id'] ?? json['serviceId'] ?? '',
      bookingDate: json['booking_date'] != null
          ? (json['booking_date'] is String
                ? DateTime.parse(json['booking_date'])
                : (json['booking_date'] as DateTime))
          : DateTime.now(),
      scheduledTime: json['scheduled_time'] ?? '',
      status: json['status'] ?? '',
      userLatitude:
          double.tryParse(json['user_latitude']?.toString() ?? '') ??
          double.tryParse(json['userLatitude']?.toString() ?? ''),
      userLongitude:
          double.tryParse(json['user_longitude']?.toString() ?? '') ??
          double.tryParse(json['userLongitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      if (userLatitude != null) 'user_latitude': userLatitude,
      if (userLatitude != null) 'userLatitude': userLatitude,
      if (userLongitude != null) 'user_longitude': userLongitude,
      if (userLongitude != null) 'userLongitude': userLongitude,
    };
  }
}
