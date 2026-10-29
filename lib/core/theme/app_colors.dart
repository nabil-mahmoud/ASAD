import 'package:flutter/material.dart';

class AppColors {
  // Official ASAD Brand Colors from Specification
  static const Color emerald = Color(0xFF059669);       // الأخضر الزمردي
  static const Color royalDark = Color(0xFF064E3B);      // الأخضر الداكن الملكي
  static const Color deepGreen = Color(0xFF022C22);      // خلفية درع الأسد
  static const Color mintAccent = Color(0xFF10B981);     // أخضر إشراق وتوهج

  // UI Status Colors (Visual Feedback UX)
  static const Color successGreen = Color(0xFF10B981);   // مسح ناجح ومقيد
  static const Color warningYellow = Color(0xFFF59E0B);  // تكرار المسح (أصفر)
  static const Color dangerRed = Color(0xFFEF4444);      // غير مسجل بالمكان (أحمر)
  static const Color manualBlue = Color(0xFF3B82F6);     // تحضير يدوي / عذر (أزرق)

  // Dark Theme Backgrounds & Surfaces (Glassmorphic)
  static const Color bgDark = Color(0xFF0B1311);
  static const Color surfaceDark = Color(0xFF13221E);
  static const Color surfaceCard = Color(0xFF1A2F2A);
  static const Color surfaceCardBorder = Color(0xFF23443C);
  static const Color surfaceCardHover = Color(0xFF285248);

  // Text Colors
  static const Color textLight = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDim = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [emerald, royalDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shieldGradient = LinearGradient(
    colors: [Color(0xFF0D5E48), Color(0xFF042F24)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF162B25), Color(0xFF10201C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
