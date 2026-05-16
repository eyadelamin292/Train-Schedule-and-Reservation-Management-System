import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerRecordsPage extends StatefulWidget {
  const PassengerRecordsPage({super.key});

  @override
  State createState() => _PassengerRecordsPageState();
}

class _PassengerRecordsPageState extends State {
  final _supabase = Supabase.instance.client;
  String _searchQuery = "";

  Future _updateUserData(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('profiles').update(updates).eq('id', userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error updating user: $e");
    }
  }

  Future _refundAndCancel(Map<String, dynamic> reservation, Map<String, dynamic> user) async {
    try {
      final double refundAmount = (reservation['price_paid'] as num).toDouble();
      final double currentBalance = (user['wallet_balance'] as num).toDouble();

      await _supabase.from('reservations').update({'status': 'cancelled'}).eq('id', reservation['id']);
      await _supabase.from('profiles').update({'wallet_balance': currentBalance + refundAmount}).eq('id', user['id']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reservation cancelled and funds refunded to wallet.")),
        );
      }
    } catch (e) {
      debugPrint("Error during refund: $e");
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    final balanceController = TextEditingController(text: user['wallet_balance'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: Text("Manage: ${user['full_name']}", style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Full Name", labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Wallet Balance (SAR)", labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 20),
              const Text("User Reservations", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              const Divider(color: Colors.grey),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabase.from('reservations').select('*, schedules(trip_number)').eq('user_id', user['id']).neq('status', 'cancelled'),
                builder: (context, resSnap) {
                  if (!resSnap.hasData) return const CircularProgressIndicator();
                  if (resSnap.data!.isEmpty) return const Text("No active bookings", style: TextStyle(color: Colors.grey, fontSize: 12));

                  return Column(
                    children: resSnap.data!.map((res) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Trip: ${res['schedules']['trip_number']}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text("Paid: ${res['price_paid']} SAR", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      trailing: TextButton(
                        onPressed: () => _refundAndCancel(res, user),
                        child: const Text("Refund", style: TextStyle(color: Colors.redAccent)),
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => _updateUserData(user['id'], {
              'full_name': nameController.text,
              'wallet_balance': double.tryParse(balanceController.text) ?? 0,
            }),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("Passenger Records"),
        backgroundColor: const Color(0xFF14181B),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search passengers...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                filled: true,
                fillColor: const Color(0xFF1D2428),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('profiles').stream(primaryKey: ['id']).order('full_name'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.where((u) {
            final isUser = u['role'] == 'user';
            final matchesSearch = u['full_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
            return isUser && matchesSearch;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                color: const Color(0xFF1D2428),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(user['full_name'] ?? "Unknown", style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Balance: ${user['wallet_balance']} SAR", style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.manage_accounts, color: Color(0xFF10B981)),
                  onTap: () => _showEditUserDialog(user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}