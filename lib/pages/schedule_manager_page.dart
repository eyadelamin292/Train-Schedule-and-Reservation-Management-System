import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ScheduleManagerPage extends StatefulWidget {
  const ScheduleManagerPage({super.key});

  @override
  State<ScheduleManagerPage> createState() => _ScheduleManagerPageState();
}

class _ScheduleManagerPageState extends State<ScheduleManagerPage> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = "";
  String _searchType = "Trip #";

  // --- 1. ADD NEW TRIP DIALOG ---
  void _showAddScheduleDialog() async {
    final routesRes = await _supabase.from('train_routes').select();
    final List routes = routesRes as List;

    String? selectedRouteId;
    final seatsController = TextEditingController(text: "50");
    DateTime departureTime = DateTime.now().add(const Duration(hours: 1));
    bool isSaving = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1D2428),
          title: const Text("Schedule New Trip", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1D2428),
                  style: const TextStyle(color: Colors.white),
                  items: routes.map((r) => DropdownMenuItem(
                    value: r['id'].toString(),
                    child: Text("${r['origin']} ➔ ${r['destination']}"),
                  )).toList(),
                  onChanged: (val) => selectedRouteId = val,
                  decoration: const InputDecoration(labelText: "Select Route", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),

                ListTile(
                  tileColor: const Color(0xFF14181B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: const Icon(Icons.calendar_month, color: Color(0xFF10B981)),
                  title: const Text("Departure Time", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(departureTime), style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: departureTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(departureTime));
                      if (time != null) {
                        setStateDialog(() => departureTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                      }
                    }
                  },
                ),

                const SizedBox(height: 15),
                TextField(
                  controller: seatsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Total Seats (Max 70)",
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.airline_seat_recline_normal, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                int seats = int.tryParse(seatsController.text) ?? 0;
                if (selectedRouteId == null || seats == 0) return;

                // --- القيد الجديد: منع جدولة رحلة في وقت مضى ---
                if (departureTime.isBefore(DateTime.now())) {
                  _showSimpleDialog("Invalid Time", "You cannot schedule a trip in the past.", Colors.redAccent);
                  return;
                }

                if (seats > 70) {
                  _showSimpleDialog("Error", "Capacity cannot exceed 70 seats.", Colors.redAccent);
                  return;
                }

                setStateDialog(() => isSaving = true);
                try {
                  await _supabase.from('schedules').insert({
                    'route_id': selectedRouteId,
                    'departure_time': departureTime.toIso8601String(),
                    'total_seats': seats,
                    'available_seats': seats,
                  });
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setStateDialog(() => isSaving = false);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. MANAGE TRIP (EDIT/DELETE) BOTTOM SHEET ---
  void _showTripDetails(Map<String, dynamic> sch) {
    final seatsController = TextEditingController(text: sch['total_seats'].toString());
    DateTime editDeparture = DateTime.parse(sch['departure_time']);

    // حساب عدد الحجوزات الحالية (المقاعد الإجمالية - المقاعد المتاحة)
    int currentBookings = sch['total_seats'] - sch['available_seats'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D2428),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text("Manage Trip: ${sch['trip_number']}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

              // تنبيه للأدمن بعدد الحجوزات الحالية
              if (currentBookings > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Current Bookings: $currentBookings (Min Capacity Required)",
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),

              const Divider(color: Colors.white10, height: 30),

              ListTile(
                tileColor: const Color(0xFF14181B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.access_time, color: Color(0xFF10B981)),
                title: const Text("Departure Time", style: TextStyle(color: Colors.grey, fontSize: 12)),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(editDeparture), style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  final date = await showDatePicker(context: ctx, initialDate: editDeparture, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) {
                    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(editDeparture));
                    if (time != null) {
                      setModalState(() => editDeparture = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
                  }
                },
              ),
              const SizedBox(height: 15),

              TextField(
                controller: seatsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Capacity (Current Bookings: $currentBookings)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.chair_alt, color: Color(0xFF10B981)),
                  helperText: "Must be at least $currentBookings seats",
                  helperStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteTrip(sch);
                      },
                      child: const Text("Delete Trip", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: () async {
                        int newTotal = int.tryParse(seatsController.text) ?? 0;

                        // --- القيد الجديد: منع تعديل الوقت ليكون في الماضي ---
                        if (editDeparture.isBefore(DateTime.now())) {
                          _showSimpleDialog(
                              "Invalid Time",
                              "Departure time cannot be set in the past.",
                              Colors.redAccent
                          );
                          return;
                        }

                        // القيد المطلوب: منع تقليل السعة عن عدد الحجوزات
                        if (newTotal < currentBookings) {
                          _showSimpleDialog(
                              "Invalid Capacity",
                              "You cannot set total seats to $newTotal because $currentBookings passengers have already booked this trip.",
                              Colors.redAccent
                          );
                          return;
                        }

                        if (newTotal > 70) {
                          _showSimpleDialog("Error", "Max capacity is 70.", Colors.redAccent);
                          return;
                        }

                        await _supabase.from('schedules').update({
                          'departure_time': editDeparture.toIso8601String(),
                          'total_seats': newTotal,
                          'available_seats': newTotal - currentBookings,
                        }).eq('id', sch['id']);

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. HELPER LOGIC ---
  Future<void> _deleteTrip(Map<String, dynamic> sch) async {
    int bookings = sch['total_seats'] - sch['available_seats'];
    if (bookings > 0) {
      _showSimpleDialog("Action Denied", "This trip has $bookings active bookings. You cannot delete a trip that has passengers.", Colors.orange);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: const Text("Confirm Delete?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _supabase.from('schedules').delete().eq('id', sch['id']);
    }
  }

  void _showSimpleDialog(String title, String msg, Color color) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1D2428), title: Text(title, style: TextStyle(color: color)), content: Text(msg, style: const TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("Schedule Manager"),
        backgroundColor: const Color(0xFF14181B),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: "Search by $_searchType...", prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)), filled: true, fillColor: const Color(0xFF1D2428), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Row(children: ["Trip #", "Origin", "Destination"].map((type) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(type), selected: _searchType == type, onSelected: (val) => setState(() => _searchType = type), selectedColor: const Color(0xFF10B981), backgroundColor: const Color(0xFF1D2428), labelStyle: TextStyle(color: _searchType == type ? Colors.white : Colors.grey)))).toList()),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('schedules').stream(primaryKey: ['id']).order('departure_time'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _supabase.from('schedules').select('*, train_routes(*)').order('departure_time'),
            builder: (context, futureSnapshot) {
              if (!futureSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              final filtered = futureSnapshot.data!.where((sch) {
                final query = _searchQuery.toLowerCase();
                if (_searchType == "Trip #") return sch['trip_number'].toString().toLowerCase().contains(query);
                if (_searchType == "Origin") return sch['train_routes']['origin'].toString().toLowerCase().contains(query);
                if (_searchType == "Destination") return sch['train_routes']['destination'].toString().toLowerCase().contains(query);
                return true;
              }).toList();
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final sch = filtered[index];
                  int res = sch['total_seats'] - sch['available_seats'];
                  return Card(
                    color: const Color(0xFF1D2428),
                    child: ListTile(
                      onTap: () => _showTripDetails(sch),
                      leading: const Icon(Icons.train, color: Color(0xFF10B981)),
                      title: Text(sch['trip_number'] ?? "N/A", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${sch['train_routes']['origin']} ➔ ${sch['train_routes']['destination']}"),
                      trailing: Text("$res Booked", style: TextStyle(color: res > 0 ? Colors.orange : Colors.grey, fontSize: 12)),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}