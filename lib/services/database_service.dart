import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_model.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // 1. جلب كل الرحلات المتاحة (تم التأكد من جلب trip_number)
  Future<List<Schedule>> getAvailableSchedules() async {
    try {
      final String now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('schedules')
          .select('*, train_routes(*)') // النجمة هنا تجلب trip_number وكل أعمدة الجدول
          .gte('departure_time', now)
          .order('departure_time', ascending: true);

      final List data = response as List;
      return data.map((json) => Schedule.fromMap(json)).toList();
    } catch (e) {
      debugPrint("Error fetching schedules: $e");
      return [];
    }
  }

  // 2. البحث عن الرحلات (تم التأكد من جلب trip_number)
  Future<List<Schedule>> searchSchedules(String origin, String destination) async {
    try {
      final String now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('schedules')
          .select('*, train_routes!inner(*)')
          .ilike('train_routes.origin', '%$origin%')
          .ilike('train_routes.destination', '%$destination%')
          .gte('departure_time', now);

      final List data = response as List;
      return data.map((json) => Schedule.fromMap(json)).toList();
    } catch (e) {
      debugPrint("Error searching schedules: $e");
      return [];
    }
  }

  // 3. دالة الحجز وخصم المقاعد
  Future<bool> bookTicket(String scheduleId, double pricePaid) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final scheduleData = await _supabase
          .from('schedules')
          .select('available_seats')
          .eq('id', scheduleId)
          .single();

      int currentSeats = scheduleData['available_seats'] ?? 0;

      if (currentSeats <= 0) return false;

      await _supabase.from('reservations').insert({
        'user_id': userId,
        'schedule_id': scheduleId,
        'seat_number': 'TBD',
        'price_paid': pricePaid,
      });

      await _supabase.from('schedules').update({
        'available_seats': currentSeats - 1
      }).eq('id', scheduleId);

      return true;
    } catch (e) {
      debugPrint("Booking error: $e");
      return false;
    }
  }

  // 4. تحديث رصيد المحفظة
  Future<bool> updateWalletBalance(double amountToSubtract) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final userData = await _supabase
          .from('profiles')
          .select('wallet_balance')
          .eq('id', userId)
          .single();

      double currentBalance = (userData['wallet_balance'] ?? 0).toDouble();

      await _supabase.from('profiles').update({
        'wallet_balance': currentBalance - amountToSubtract
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint("Wallet update error: $e");
      return false;
    }
  }

  // 5. إضافة مسار جديد (Admin)
  Future<bool> createRoute(String origin, String destination, double distance) async {
    try {
      await _supabase.from('train_routes').insert({
        'origin': origin,
        'destination': destination,
        'distance_km': distance,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 6. إضافة جدول رحلة جديد (Admin)
  Future<bool> createSchedule({
    required String routeId,
    required DateTime departure,
    required DateTime arrival,
    required int seats,
  }) async {
    try {
      await _supabase.from('schedules').insert({
        'route_id': routeId,
        'departure_time': departure.toIso8601String(),
        'arrival_time': arrival.toIso8601String(),
        'total_seats': seats,
        'available_seats': seats,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 7. جلب التذاكر القادمة للمستخدم
  Future<List<Map<String, dynamic>>> getUpcomingTickets() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final String now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('reservations')
          .select('*, schedules!inner(*, train_routes(*))')
          .eq('user_id', userId!)
          .gte('schedules.departure_time', now)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // 8. جلب تاريخ السفر (تمت إضافة trip_number هنا بشكل صريح)
  Future<List<Map<String, dynamic>>> getTravelHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final String now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('reservations')
          .select('''
            *,
            schedules!inner (
              trip_number,
              departure_time,
              arrival_time, 
              train_routes (
                origin,
                destination
              )
            )
          ''')
          .eq('user_id', userId)
          .lt('schedules.departure_time', now)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching travel history: $e");
      return [];
    }
  }

  // 9. إلغاء الحجز واسترداد المبلغ
  Future<String> cancelTicket(Map<String, dynamic> ticket) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return "User not found";

      final schedule = ticket['schedules'];
      final departureTime = DateTime.parse(schedule['departure_time']);

      if (DateTime.now().isAfter(departureTime)) {
        return "Cannot cancel a trip that has already started or passed.";
      }

      final double refundAmount = (ticket['price_paid'] ?? 0).toDouble();
      final userData = await _supabase.from('profiles').select('wallet_balance').eq('id', userId).single();
      double currentBalance = (userData['wallet_balance'] ?? 0).toDouble();

      await _supabase.from('profiles').update({
        'wallet_balance': currentBalance + refundAmount
      }).eq('id', userId);

      final String scheduleId = ticket['schedule_id'];
      final scheduleData = await _supabase.from('schedules').select('available_seats').eq('id', scheduleId).single();
      int currentSeats = scheduleData['available_seats'] ?? 0;

      await _supabase.from('schedules').update({
        'available_seats': currentSeats + 1
      }).eq('id', scheduleId);

      await _supabase.from('reservations').delete().eq('id', ticket['id']);

      return "success";
    } catch (e) {
      return "Error: $e";
    }
  }

  // 10. تحديث بيانات الملف الشخصي
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String city,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('profiles').update({
        'full_name': fullName,
        'phone_number': phone,
        'city': city,
      }).eq('id', userId!);
      return true;
    } catch (e) {
      return false;
    }
  }
}