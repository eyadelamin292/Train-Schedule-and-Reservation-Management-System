import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // City Configuration
  String? _selectedCity;
  final List<String> _cities = [
    'Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam',
    'Taif', 'Tabuk', 'Buraydah', 'Abha', 'Khobar',
    'Jazan', 'Hail', 'Najran', 'Al-Ahsa', 'Al-Baha'
  ];

  bool _isLoading = false;

  // --- Logic: Sign Up Process ---
  Future<void> _handleSignUp() async {
    // 1. التحقق من صحة المدخلات في الفورم
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCity == null) {
      _showError("Please select your city");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. محاولة إنشاء الحساب في Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = res.user;

      if (user != null) {
        // 3. إذا نجح الإنشاء، نقوم بإضافة البيانات الإضافية في جدول profiles
        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': _fullNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'city': _selectedCity,
          'role': 'user',
          'wallet_balance': 0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created! You can login now."),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          Navigator.pop(context); // العودة لصفحة تسجيل الدخول
        }
      }
    } on AuthException catch (error) {
      // 4. معالجة الأخطاء (مثل الإيميل المكرر)
      String errorMessage = error.message;
      if (errorMessage.contains("already registered")) {
        errorMessage = "This email is already in use. Please use a different one.";
      }
      _showError(errorMessage);
    } catch (error) {
      _showError("An unexpected error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: const Text("Registration Error", style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14181B),
      appBar: AppBar(
        title: const Text("Create New Account"),
        backgroundColor: const Color(0xFF14181B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person_add_rounded, size: 80, color: Color(0xFF10B981)),
              const SizedBox(height: 20),
              const Text(
                "Sign Up to SIMS",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Full Name ---
              _buildTextField(
                controller: _fullNameController,
                label: "Full Name",
                icon: Icons.person_outline,
                validator: (val) => val!.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 15),

              // --- Email (Flexible Validation) ---
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter email";
                  if (!val.contains("@") || !val.trim().endsWith(".com")) {
                    return "Email must have @ and end with .com";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // --- Password ---
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (val) => val!.length < 6 ? "At least 6 characters" : null,
              ),
              const SizedBox(height: 15),

              // --- Phone Number (KSA Format 05xxxxxxxx) ---
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter phone number";
                  if (!val.startsWith("05")) return "Must start with 05";
                  if (val.length != 10) return "Must be 10 digits";
                  return null;
                },
                decoration: _inputDecoration("Phone (05xxxxxxxx)", Icons.phone_android),
              ),
              const SizedBox(height: 15),

              // --- City Selection (Dropdown) ---
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1D2428),
                initialValue: _selectedCity,
                style: const TextStyle(color: Colors.white),
                items: _cities.map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCity = val),
                validator: (val) => val == null ? "Please select a city" : null,
                decoration: _inputDecoration("Select Your City", Icons.location_city),
              ),
              const SizedBox(height: 35),

              // --- Submit Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
      filled: true,
      fillColor: const Color(0xFF1D2428),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }
}