import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouteManagementPage extends StatefulWidget {
  const RouteManagementPage({super.key});

  @override
  State<RouteManagementPage> createState() => _RouteManagementPageState();
}

class _RouteManagementPageState extends State<RouteManagementPage> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = "";
  String _searchType = "Origin";

  final List<String> _saudiCities = [
    'Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam',
    'Taif', 'Tabuk', 'Buraydah', 'Abha', 'Khobar',
    'Jazan', 'Hail', 'Najran', 'Al-Ahsa', 'Al-Baha'
  ];

  // المنطق المحدث: التحقق من وجود رحلات قبل الحذف
  Future<void> _deleteRoute(String routeId, String routeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete the route: $routeName?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // الخطوة 1: التحقق من جدول المواعيد (schedules)
      final linkedSchedules = await _supabase
          .from('schedules')
          .select('id')
          .eq('route_id', routeId)
          .limit(1);

      // الخطوة 2: إذا وجدت رحلة واحدة على الأقل، نمنع الحذف
      if (linkedSchedules.isNotEmpty) {
        if (mounted) {
          _showErrorDialog(
              "Deletion Forbidden",
              "This route cannot be deleted because there are active schedules/trips assigned to it. Delete the trips first."
          );
        }
        return;
      }

      // الخطوة 3: إذا كان المسار فارغاً من الرحلات، يتم الحذف
      await _supabase.from('train_routes').delete().eq('id', routeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Route '$routeName' deleted successfully.")),
        );
      }
    } catch (e) {
      if (mounted) _showErrorDialog("Error", "An unexpected error occurred: $e");
    }
  }

  void _showAddRouteDialog() {
    String? selectedOrigin;
    String? selectedDest;
    final distController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1D2428),
          title: const Text("Add New Route", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1D2428),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Origin", labelStyle: TextStyle(color: Colors.grey)),
                  items: _saudiCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedOrigin = val),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1D2428),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Destination", labelStyle: TextStyle(color: Colors.grey)),
                  items: _saudiCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                  onChanged: (val) => setStateDialog(() => selectedDest = val),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: distController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Distance (KM)",
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.map, color: Color(0xFF10B981)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () async {
                double distance = double.tryParse(distController.text) ?? 0;
                if (selectedOrigin == null || selectedDest == null) {
                  _showErrorDialog("Missing Data", "Please select both Origin and Destination.");
                  return;
                }
                if (selectedOrigin == selectedDest) {
                  _showErrorDialog("Logic Error", "Origin and Destination cannot be the same.");
                  return;
                }
                if (distance <= 0 || distance > 3000) {
                  _showErrorDialog("Invalid Distance", "Please enter a realistic distance (1 - 3000 KM).");
                  return;
                }
                await _supabase.from('train_routes').insert({
                  'origin': selectedOrigin,
                  'destination': selectedDest,
                  'distance_km': distance,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Route"),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1D2428),
          title: Text(title, style: const TextStyle(color: Colors.redAccent)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("Route Management", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF14181B),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by $_searchType...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                    filled: true,
                    fillColor: const Color(0xFF1D2428),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ["Origin", "Destination"].map((type) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: _searchType == type,
                    onSelected: (val) => setState(() => _searchType = type),
                    selectedColor: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFF1D2428),
                    labelStyle: TextStyle(color: _searchType == type ? Colors.white : Colors.grey),
                  ),
                )).toList(),
              )
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('train_routes').stream(primaryKey: ['id']).order('origin'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));

          final filteredRoutes = snapshot.data!.where((r) {
            final query = _searchQuery.toLowerCase();
            return _searchType == "Origin"
                ? r['origin'].toString().toLowerCase().contains(query)
                : r['destination'].toString().toLowerCase().contains(query);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: filteredRoutes.length,
            itemBuilder: (context, index) {
              final route = filteredRoutes[index];
              return Card(
                color: const Color(0xFF1D2428),
                child: ListTile(
                  leading: const Icon(Icons.alt_route, color: Color(0xFF10B981)),
                  title: Text("${route['origin']} ➔ ${route['destination']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("${route['distance_km']} KM | ${route['base_price']} SAR", style: const TextStyle(color: Colors.grey)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _deleteRoute(route['id'].toString(), "${route['origin']} to ${route['destination']}"),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _showAddRouteDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}