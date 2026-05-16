import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/custom_text.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  // دالة جلب البيانات مع دعم التحديث
  Future<void> _loadTickets() async {
    final tickets = await _dbService.getUpcomingTickets();
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1D2428),
      child: _tickets.isEmpty
          ? SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: AppText(
            text: "You don't have any tickets yet.",
            color: Colors.grey,
            fontSize: 16,
            onPressed: () {},
          ),
        ),
      )
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];

          // استخراج البيانات
          var rawSchedule = ticket['schedules'];
          Map<String, dynamic>? schedule = (rawSchedule is List && rawSchedule.isNotEmpty)
              ? rawSchedule.first
              : (rawSchedule is Map ? rawSchedule as Map<String, dynamic> : null);

          var rawRoute = schedule?['train_routes'];
          Map<String, dynamic>? route = (rawRoute is List && rawRoute.isNotEmpty)
              ? rawRoute.first
              : (rawRoute is Map ? rawRoute as Map<String, dynamic> : null);

          if (schedule == null || route == null) return const SizedBox();

          return InkWell(
            onTap: () => _showTicketDetails(context, ticket),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2428),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF262D34)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- إضافة معرف التذكرة في أعلى الكارت ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: AppText(
                          text: "TICKET ID: #${ticket['id'].toString().substring(0, 8)}",
                          fontSize: 10,
                          color: const Color(0xFF10B981),
                          onPressed: () {},
                        ),
                      ),
                      const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(text: route['origin'] ?? "N/A", fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, onPressed: () {}),
                      const Icon(Icons.train, color: Color(0xFF10B981)),
                      AppText(text: route['destination'] ?? "N/A", fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, onPressed: () {}),
                    ],
                  ),
                  const Divider(height: 30, color: Color(0xFF262D34)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn("Time", (schedule['departure_time']?.toString().length ?? 0) > 16
                          ? schedule['departure_time'].toString().substring(11, 16)
                          : "00:00"),
                      _buildInfoColumn("Seat", ticket['seat_number'] ?? "TBD"),
                      _buildInfoColumn("Paid", "${ticket['price_paid']} SAR", isPrice: true),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ويدجت مساعد لأعمدة المعلومات في الكارت
  Widget _buildInfoColumn(String label, String value, {bool isPrice = false}) {
    return Column(
      crossAxisAlignment: label == "Paid" ? CrossAxisAlignment.end : (label == "Seat" ? CrossAxisAlignment.center : CrossAxisAlignment.start),
      children: [
        AppText(text: label, fontSize: 12, color: Colors.grey, onPressed: () {}),
        AppText(
          text: value,
          color: isPrice ? const Color(0xFF10B981) : Colors.white,
          fontWeight: FontWeight.bold,
          onPressed: () {},
        ),
      ],
    );
  }

  void _showTicketDetails(BuildContext context, Map<String, dynamic> ticket) {
    var rawSchedule = ticket['schedules'];
    Map<String, dynamic>? schedule = (rawSchedule is List && rawSchedule.isNotEmpty)
        ? rawSchedule.first
        : (rawSchedule is Map ? rawSchedule as Map<String, dynamic> : null);

    var rawRoute = schedule?['train_routes'];
    Map<String, dynamic>? route = (rawRoute is List && rawRoute.isNotEmpty)
        ? rawRoute.first
        : (rawRoute is Map ? rawRoute as Map<String, dynamic> : null);

    if (schedule == null || route == null) return;

    String formatDateTime(dynamic dateTimeStr) {
      if (dateTimeStr == null) return "N/A";
      String str = dateTimeStr.toString();
      if (str.length >= 16) return str.replaceAll('T', ' ').substring(0, 16);
      return str;
    }

    final isCancelable = schedule['departure_time'] != null
        ? DateTime.now().isBefore(DateTime.parse(schedule['departure_time'].toString()))
        : false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D2428),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(text: "Ticket Details", fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, onPressed: () {}),
              const Divider(color: Color(0xFF262D34), height: 30),

              // عرض المعرف الكامل في التفاصيل
              _detailRow("Full Ticket ID", "#${ticket['id']}"),
              _detailRow("From", route['origin'] ?? "Unknown"),
              _detailRow("To", route['destination'] ?? "Unknown"),
              _detailRow("Departure", formatDateTime(schedule['departure_time'])),
              _detailRow("Arrival", formatDateTime(schedule['arrival_time'])),
              _detailRow("Seat", ticket['seat_number'] ?? "TBD"),
              _detailRow("Price", "${ticket['price_paid']} SAR"),

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCancelable ? Colors.redAccent : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isCancelable ? () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1D2428),
                        title: const Text("Confirm Cancellation", style: TextStyle(color: Colors.white)),
                        content: const Text("Refund the amount to your wallet?", style: TextStyle(color: Colors.grey)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No", style: TextStyle(color: Colors.grey))),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Cancel", style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    ) ?? false;

                    if (confirm) {
                      Navigator.pop(context);
                      final result = await _dbService.cancelTicket(ticket);
                      if (result == "success") {
                        _loadTickets();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ticket cancelled!"), backgroundColor: Color(0xFF10B981)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.redAccent));
                      }
                    }
                  } : null,
                  child: Text(isCancelable ? "Cancel & Refund" : "Cannot Cancel Now", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(text: label, color: Colors.grey, fontSize: 14, onPressed: () {}),
          Flexible(child: AppText(text: value, color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, onPressed: () {})),
        ],
      ),
    );
  }
}