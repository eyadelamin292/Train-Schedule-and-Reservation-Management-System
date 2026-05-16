import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // أرقام بسيطة ومباشرة
  double totalRevenue = 0;
  int totalReservations = 0;
  double totalRefunds = 0;
  List<Map<String, dynamic>> routeStats = [];

  @override
  void initState() {
    super.initState();
    _fetchSimpleData();
  }

  Future<void> _fetchSimpleData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('reservations').select('price_paid, status, schedules(train_routes(origin, destination))');
      final List data = response as List;

      double revenue = 0;
      double refunds = 0;
      Map<String, double> routesMap = {};

      for (var item in data) {
        double price = (item['price_paid'] as num).toDouble();
        String route = "${item['schedules']['train_routes']['origin']} ➔ ${item['schedules']['train_routes']['destination']}";

        if (item['status'] == 'cancelled') {
          refunds += price;
        } else {
          revenue += price;
          routesMap[route] = (routesMap[route] ?? 0) + price;
        }
      }

      setState(() {
        totalRevenue = revenue;
        totalRefunds = refunds;
        totalReservations = data.where((i) => i['status'] != 'cancelled').length;
        routeStats = routesMap.entries.map((e) => {'name': e.key, 'value': e.value}).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("System Overview", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF14181B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
        onRefresh: _fetchSimpleData,
        color: const Color(0xFF10B981),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // كروت الإحصائيات السريعة
            Row(
              children: [
                _buildSimpleStat("Revenue", totalRevenue.toStringAsFixed(0), Colors.green),
                const SizedBox(width: 15),
                _buildSimpleStat("Tickets", "$totalReservations", Colors.blue),
              ],
            ),
            const SizedBox(height: 15),
            _buildSimpleStat("Refunds", "${totalRefunds.toStringAsFixed(0)} SAR", Colors.redAccent, isFullWidth: true),

            const SizedBox(height: 30),
            const Text("Revenue by Route", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10),

            // قائمة المسارات بشكل مبسط
            ...routeStats.map((route) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2428),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(route['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                  Text("${route['value'].toStringAsFixed(0)} SAR",
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color, {bool isFullWidth = false}) {
    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    return isFullWidth ? content : Expanded(child: content);
  }
}