class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime date;
  final String status;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.date,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['userId'],
      serviceId: json['serviceId'],
      date: DateTime.parse(json['date']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'serviceId': serviceId,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
