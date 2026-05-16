import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swe_project/pages/passenger_records_page.dart';
import 'package:swe_project/pages/reports_page.dart';
import 'package:swe_project/pages/route_management_page.dart';
import 'package:swe_project/pages/schedule_manager_page.dart';

import 'logIn.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _supabase = Supabase.instance.client;

  Future<void> _logout() async {
    try {
      // 1. تسجيل الخروج من Supabase
      await _supabase.auth.signOut();

      if (mounted) {
        // 2. الانتقال لصفحة تسجيل الدخول وحذف كل الصفحات السابقة من الذاكرة
        // افترضت أن اسم الكلاس لصفحة الدخول هو LoginPage
        // إذا كنت تستخدم الـ Routes المسمية، استبدلها بـ Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const logIn()), // تأكد من استيراد ملف صفحة الدخول
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14181B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutConfirm(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم البروفايل الخاص بالأدمن
            _buildAdminProfile(user),

            const SizedBox(height: 30),
            const Text(
              "Management Console",
              style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // خيارات الإدارة
            _buildManagementList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfile(User? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF262D34)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF10B981),
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // جلب الاسم من جدول profiles بناءً على السكيما المرفقة
                FutureBuilder<Map<String, dynamic>?>(
                  future: _supabase
                      .from('profiles')
                      .select('full_name')
                      .eq('id', user?.id ?? '')
                      .maybeSingle(),
                  builder: (context, snapshot) {
                    // 1. إذا وجدنا الاسم في الجدول نعرصه
                    // 2. إذا لم يوجد (قيد التحميل أو غير مسجل) نستخدم الجزء الأول من الإيميل كاحتياط
                    String displayName = snapshot.data?['full_name'] ??
                        user?.email?.split('@')[0] ??
                        "Admin";

                    return Text(
                      displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    );
                  },
                ),
                Text(
                  user?.email ?? "admin@system.com",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementList() {
    return Column(
      children: [
        _buildAdminAction("Route Management", "Create & Update Routes", Icons.map, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RouteManagementPage()));
        }),
        _buildAdminAction("Schedule Manager", "Define times & dates", Icons.event, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleManagerPage()));
        }),
        _buildAdminAction("Passenger Records", "View & Update User Data", Icons.supervised_user_circle, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PassengerRecordsPage()));
        }),
        _buildAdminAction("Reports & Analytics", "Financial & System Reports", Icons.analytics, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsPage()));
        }),
      ],
    );
  }

  Widget _buildAdminAction(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1D2428),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF10B981)),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to sign out?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: _logout,
            child: const Text("Sign Out", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}