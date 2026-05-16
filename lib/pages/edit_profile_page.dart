import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _dbService = DatabaseService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // المتغير الذي سيحمل القيمة المختارة للمدينة
  String? _selectedCity;
  bool _isSaving = false;

  // قائمة المدن المطلوبة
  final List<String> _cities = [
    'Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam',
    'Taif', 'Tabuk', 'Buraydah', 'Abha', 'Khobar',
    'Jazan', 'Hail', 'Najran', 'Al-Ahsa', 'Al-Baha'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['full_name']);
    _phoneController = TextEditingController(text: widget.userData['phone_number'] ?? "");

    // التأكد من أن مدينة المستخدم موجودة في القائمة، وإلا نتركها فارغة
    String? initialCity = widget.userData['city'];
    if (_cities.contains(initialCity)) {
      _selectedCity = initialCity;
    }
  }

  bool _isValidSaudiPhone(String phone) {
    final RegExp phoneRegExp = RegExp(r'^05\d{8}$');
    return phoneRegExp.hasMatch(phone);
  }

  Future<void> _saveProfile() async {
    final phone = _phoneController.text.trim();

    if (phone.isNotEmpty && !_isValidSaudiPhone(phone)) {
      _showSnackBar("Invalid phone number. Must start with 05 and be 10 digits.", isError: true);
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Name cannot be empty", isError: true);
      return;
    }

    if (_selectedCity == null) {
      _showSnackBar("Please select a city", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    bool success = await _dbService.updateProfile(
      fullName: _nameController.text.trim(),
      phone: phone,
      city: _selectedCity!,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _showSnackBar("Profile updated successfully!");
        Navigator.pop(context, true);
      } else {
        _showSnackBar("Update failed. Please try again.", isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF14181B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Full Name"),
            _buildTextField(_nameController),
            const SizedBox(height: 15),
            _buildLabel("Phone Number"),
            _buildTextField(_phoneController, isPhone: true),
            const SizedBox(height: 15),
            _buildLabel("City"),
            _buildCityDropdown(), // القائمة المنسدلة الجديدة
            const Spacer(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      inputFormatters: isPhone ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ] : [],
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1D2428),
        hintText: isPhone ? "05xxxxxxxx" : null,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          dropdownColor: const Color(0xFF1D2428),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: InputBorder.none),
          hint: const Text("Select your city", style: TextStyle(color: Colors.grey, fontSize: 14)),
          items: _cities.map((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCity = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isSaving ? null : _saveProfile,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}