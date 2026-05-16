import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool isLoading; // ميزة لإظهار التحميل عند ضغط الزر

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // يأخذ عرض الشاشة بالكامل
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed, // تعطيل الزر أثناء التحميل
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF10B981), // اللون الأخضر من الصورة
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // حواف دائرية احترافية
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}