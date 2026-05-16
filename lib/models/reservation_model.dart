import 'package:swe_project/models/schedule_model.dart';

class Reservation {
  final String id;
  final String userId;
  final String scheduleId;
  final String seatNumber;
  final String status;
  final double pricePaid;
  final DateTime createdAt;
  final Schedule? schedule; // لعرض تفاصيل الرحلة داخل التذكرة

  Reservation({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.seatNumber,
    required this.status,
    required this.pricePaid,
    required this.createdAt,
    this.schedule,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      userId: map['user_id'],
      scheduleId: map['schedule_id'],
      seatNumber: map['seat_number'],
      status: map['status'],
      pricePaid: (map['price_paid'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      schedule: map['schedules'] != null ? Schedule.fromMap(map['schedules']) : null,
    );
  }
}