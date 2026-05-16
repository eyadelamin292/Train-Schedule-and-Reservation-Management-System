import 'package:flutter/material.dart';
import 'custom_text.dart'; // استخدام الـ Widget اللي عندك

class CustomFooter2 extends StatelessWidget {
  final String footerText;
  final VoidCallback onTapContact;

  const CustomFooter2({
    super.key,
    required this.footerText,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      decoration: BoxDecoration(
        color: Color(0xFF14181B),
        border: Border(top: BorderSide(color: Color(0xFF10B981))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ليأخذ مساحة المحتوى فقط
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // نص الحقوق باستخدام الـ Widget الخاص بك
              Expanded(
                child: AppText(
                  text: footerText,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              // // زر التواصل
              // TextButton.icon(
              //   onPressed: onTapContact,
              //   icon: const Icon(Icons.support_agent, size: 18, color: Color(0xFF10B981)),
              //   label: const Text(
              //     "Support",
              //     style: TextStyle(color: Color(0xFF10B981), fontSize: 12),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 10),
          // خط زينة بسيط يعطي لمسة جمالية
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}