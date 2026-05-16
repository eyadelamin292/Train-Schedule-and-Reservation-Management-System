import 'package:flutter/material.dart';
import 'UserHomePage.dart';
import 'my_tickets_page.dart';
import 'profile_page.dart'; // 1. استيراد صفحة البروفايل الجديدة

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // 2. القائمة المحدثة بالصفحات الفعلية كاملة
  final List<Widget> _pages = [
    const UserHomePage(),
    const MyTicketsPage(),
    const ProfilePage(), // تم استبدال الـ Center بصفحة البروفايل
  ];

  final List<String> _titles = [
    "Train Reservation",
    "My Tickets",
    "My Profile"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14181B),
        elevation: 0,
        centerTitle: true,
        // إضافة أيقونة بسيطة بجانب العنوان لتمييز الصفحة
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIconForIndex(_selectedIndex), color: const Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: IndexedStack( // نصيحة: استخدم IndexedStack للحفاظ على حالة الصفحات عند التنقل
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1D2428),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // دالة مساعدة لتغيير الأيقونة في الـ AppBar حسب الصفحة
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.train;
      case 1: return Icons.airplane_ticket;
      case 2: return Icons.account_circle;
      default: return Icons.train;
    }
  }
}