import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swe_project/pages/reservation_page.dart';
import '../models/schedule_model.dart';
import '../services/database_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/custom_text.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final DatabaseService _dbService = DatabaseService();
  List<Schedule> availableTrips = [];
  String userName = "Guest";
  String? userCity; // لتخزين مدينة المستخدم

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // إعداد التحديث التلقائي عند الكتابة
    _originController.addListener(_searchTrips);
    _destinationController.addListener(_searchTrips);

    _loadInitialData();
  }

  @override
  void dispose() {
    // تنظيف الذاكرة
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // دالة لجلب بيانات المستخدم والرحلات لأول مرة
  Future<void> _loadInitialData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('profiles')
            .select('full_name, city') // جلب الاسم والمدينة
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null && mounted) {
          setState(() {
            userName = userData['full_name'] ?? "User";
            userCity = userData['city'];
            // تعيين مدينة المستخدم في حقل الانطلاق تلقائياً
            if (userCity != null) {
              _originController.text = userCity!;
            }
          });
        }
      }
      // تحميل الرحلات بناءً على مدينة المستخدم (أو كل الرحلات إذا لم تحدد مدينة)
      _searchTrips();
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    }
  }

  // دالة البحث (تعمل تلقائياً عند تغيير النص)
  Future<void> _searchTrips() async {
    try {
      final trips = await _dbService.searchSchedules(
        _originController.text.trim(),
        _destinationController.text.trim(),
      );

      if (mounted) {
        setState(() {
          availableTrips = trips;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      body: RefreshIndicator(
        // التعديل هنا: استخدام _loadInitialData لكي يتم تحديث بيانات (الاسم والمدينة) بالإضافة للرحلات عند السحب للتحديث
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchCard(),
              _buildTripsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(text: "Welcome back,", fontSize: 16, color: const Color(0xFF10B981), onPressed: () {}),
          AppText(text: userName, fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, onPressed: () {}),
          if (userCity != null)
            AppText(text: "Your City: $userCity", fontSize: 13, color: Colors.grey, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2428),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF262D34)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
        ),
        child: Column(
          children: [
            AppTextField(
                controller: _originController,
                hint: "Search Origin...",
                icon: Icons.location_on,
                label: 'From'),
            const SizedBox(height: 10),
            AppTextField(
                controller: _destinationController,
                hint: "Search Destination...",
                icon: Icons.train,
                label: 'To'),
            const SizedBox(height: 10),
            const Text(
              "Results update automatically as you type",
              style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          AppText(text: "Available Trains", fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, onPressed: () {}),
          const SizedBox(height: 15),
          availableTrips.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("No trips found for this route", style: TextStyle(color: Colors.grey)),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableTrips.length,
            itemBuilder: (context, index) {
              final trip = availableTrips[index];
              // حماية إضافية للوقت
              if (trip.departureTime.isBefore(DateTime.now())) return const SizedBox.shrink();
              return _buildTripCard(trip);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Schedule trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF262D34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trip.tripNumber ?? "TRN-00000",
                  style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                "${trip.availableSeats} seats left",
                style: TextStyle(color: trip.availableSeats < 10 ? Colors.red : Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(text: trip.route?.origin ?? "N/A", fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, onPressed: () {}),
              const Icon(Icons.trending_flat, color: Color(0xFF10B981)),
              AppText(text: trip.route?.destination ?? "N/A", fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, onPressed: () {}),
            ],
          ),
          const Divider(height: 30, color: Color(0xFF262D34)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripInfo("Departure", "${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}"),
              _buildTripInfo("Price", "${trip.route?.basePrice} SAR", isBold: true),
            ],
          ),
          const SizedBox(height: 15),
          AppButton(
            text: "Book Now",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReservationPage(trip: trip)),
              );
              _searchTrips();
            },
          )
        ],
      ),
    );
  }

  Widget _buildTripInfo(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(text: label, fontSize: 12, color: Colors.grey, onPressed: () {}),
        AppText(
          text: value,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: isBold ? const Color(0xFF10B981) : Colors.white,
          onPressed: () {},
        ),
      ],
    );
  }
}