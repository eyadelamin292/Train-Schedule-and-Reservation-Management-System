import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppFooterText extends StatelessWidget {
  final String questionText;
  final String actionText;
  final VoidCallback onActionTap;

  const AppFooterText({
    super.key,
    required this.questionText,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          text: questionText,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          children: [
            TextSpan(
              text: ' $actionText',
              style: const TextStyle(
                color: Color(0xFF10B981), // اللون الأخضر من التصميم
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline, // اختيار لتمييزه كـ رابط
              ),
              recognizer: TapGestureRecognizer()..onTap = onActionTap,
            ),
          ],
        ),
      ),
    );
  }
}