import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double? letterSpacing;
  final VoidCallback? onPressed; // جعلناها اختيارية بنقطة الاستفهام

  const AppText({
    super.key,
    required this.text,
    this.fontSize = 16.0,
    this.color = Colors.white,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.letterSpacing,
    this.onPressed, // أزلنا كلمة required
  });

  @override
  Widget build(BuildContext context) {
    // إذا كان هناك onPressed، نغلف النص بـ GestureDetector ليصبح قابلاً للضغط
    Widget textWidget = Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
    );

    if (onPressed != null) {
      return GestureDetector(
        onTap: onPressed,
        child: textWidget,
      );
    }

    return textWidget;
  }
}