import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swe_project/pages/travel_history_page.dart';
import '../widgets/custom_text.dart';
import 'edit_profile_page.dart';
import 'logIn.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // جلب بيانات المستخدم من جدول profiles
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            userData = data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUpperSection(),
            const SizedBox(height: 20),
            _buildWalletCard(),
            const SizedBox(height: 20),
            _buildMenuOption(Icons.person_outline, "Edit Profile", () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(userData: userData!),
                ),
              );
              // التعديل هنا: إلغاء الشرط (if result == true) لنجبر الصفحة دائماً على تحديث البيانات فور الإغلاق
              if (mounted) {
                _fetchUserData();
              }
            }),
            _buildMenuOption(Icons.history, "Travel History", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TravelHistoryPage()),
              );
            }),
            // تم حذف خيار الإعدادات من هنا
            const Divider(color: Color(0xFF262D34), height: 40, indent: 20, endIndent: 20),
            _buildMenuOption(Icons.logout, "Logout", _handleLogout, isLogout: true),
          ],
        ),
      ),
    );
  }

// ... الكود السابق كما هو ...

  Widget _buildUpperSection() {
    // الحصول على الـ ID الخاص بالمستخدم
    final String userId = _supabase.auth.currentUser?.id ?? "N/A";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1D2428),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF10B981),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 15),
          AppText(
            text: userData?['full_name'] ?? "User Name",
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            onPressed: () {},
          ),
          AppText(
            text: _supabase.auth.currentUser?.email ?? "email@example.com",
            fontSize: 14,
            color: Colors.grey,
            onPressed: () {},
          ),
          const SizedBox(height: 8),
          // --- الإضافة هنا: عرض الـ ID الخاص بالمستخدم ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint, size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 5),
                Text(
                  "ID: ${userId.substring(0, 8)}...", // عرض أول 8 أرقام فقط للجمالية
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 5),
                InkWell(
                  onTap: () {
                    // ميزة اختيارية: نسخ الـ ID عند الضغط عليه
                    Clipboard.setData(ClipboardData(text: userId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ID copied to clipboard!")),
                    );
                  },
                  child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ... باقي الكود (WalletCard, MenuOptions, إلخ) كما هو ...

  Widget _buildWalletCard() {
    // جلب الرصيد وعرضه برقمين بعد الفاصلة
    double balance = (userData?['wallet_balance'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 5),
              Text(
                "${balance.toStringAsFixed(2)} SAR",
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add_card, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isLogout ? Colors.redAccent : const Color(0xFF10B981)),
      title: Text(
        title,
        style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const logIn()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }
}