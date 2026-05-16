import 'package:swe_project/models/route_model.dart';

class Schedule {
  final String id;
  final String routeId;
  final DateTime departureTime;
  final String? tripNumber;
  final DateTime arrivalTime;
  final int totalSeats;
  final int availableSeats;
  final TrainRoute? route;

  Schedule({
    required this.id,
    required this.routeId,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalSeats,      // تصحيح: إزالة الـ underscore
    required this.availableSeats,  // تصحيح: إزالة الـ underscore
    this.route, this.tripNumber,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      routeId: map['route_id'],
      departureTime: DateTime.parse(map['departure_time']),
      arrivalTime: DateTime.parse(map['arrival_time']),
      totalSeats: map['total_seats'],     // هنا نستخدم اسم المفتاح كما هو في قاعدة البيانات
      availableSeats: map['available_seats'], // وهنا كذلك
      tripNumber: map['trip_number'],
      route: map['train_routes'] != null
          ? TrainRoute.fromMap(map['train_routes'])
          : null,
    );
  }
}