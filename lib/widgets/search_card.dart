import 'package:flutter/material.dart';

class SearchCard extends StatelessWidget {
  final String fromLabel;
  final String toLabel;
  final String dateLabel;

  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController dateController;

  final VoidCallback onSearch;
  final VoidCallback onPickDate;

  const SearchCard({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    required this.dateLabel,
    required this.fromController,
    required this.toController,
    required this.dateController,
    required this.onSearch,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputField(
              label: fromLabel,
              controller: fromController,
              icon: Icons.train_outlined,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: toLabel,
              controller: toController,
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onPickDate,
              child: AbsorbPointer(
                child: _buildInputField(
                  label: dateLabel,
                  controller: dateController,
                  icon: Icons.date_range_outlined,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Search Trains',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}