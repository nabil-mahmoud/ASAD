import 'package:flutter/material.dart';

class AppColors {
  // Official DMU Identity Colors (Damanhour University - White & Blue)
  static const Color primaryBlue = Color(0xFF0D47A1);      // أزرق ملكي جامعة دمنهور
  static const Color royalDark = Color(0xFF1E3A8A);        // كحلي ترويسة
  static const Color navyDark = Color(0xFF0A2540);         // كحلي داكن
  static const Color accentBlue = Color(0xFF2563EB);       // أزرق تفاعلي زاهي
  static const Color lightBlue = Color(0xFFEFF6FF);        // خلفية زرقاء فاتحة للكروت والشارات
  static const Color lightBlueBorder = Color(0xFFBFDBFE);  // حدود زرقاء ناعمة
  static const Color skyBlue = Color(0xFF38BDF8);          // أزرق سماوي

  // Preserved alias for compatibility across all screens
  static const Color emerald = Color(0xFF0D47A1);          // Map emerald to DMU primary blue!
  static const Color mintAccent = Color(0xFF2563EB);       // Map mintAccent to vibrant DMU blue!
  static const Color deepGreen = Color(0xFF0A2540);        // Map deepGreen to royalDark!

  // UI Status Colors
  static const Color successGreen = Color(0xFF10B981);     // حضور ناجح (أخضر زاهي)
  static const Color warningYellow = Color(0xFFF59E0B);    // تنبيه تكرار (أصفر كهرماني)
  static const Color dangerRed = Color(0xFFEF4444);        // غياب / حذف (أحمر)
  static const Color manualBlue = Color(0xFF2563EB);       // تحضير يدوي / عذر (أزرق)

  // White & Blue Theme Surfaces
  static const Color bgLight = Color(0xFFF8FAFC);          // خلفية الشاشات الأساسية (أبيض ثلجي مريح)
  static const Color surfaceWhite = Color(0xFFFFFFFF);     // أسطح الكروت والقوائم (أبيض ناصع)
  static const Color surfaceCardBorder = Color(0xFFE2E8F0);// حدود ناعمة للكروت
  static const Color surfaceCardHover = Color(0xFFF1F5F9); // عند اللمس

  // Aliases for smooth transition in existing screens
  static const Color bgDark = Color(0xFFF8FAFC);           // Clean White/Slate background!
  static const Color surfaceDark = Color(0xFFFFFFFF);      // Clean White surface!
  static const Color surfaceCard = Color(0xFFFFFFFF);      // Clean White card!

  // High-Contrast Academic Text Colors
  static const Color textLight = Color(0xFF0F172A);        // كحلي داكن شديد الوضوح (نص رئيسي)
  static const Color textMuted = Color(0xFF475569);        // رمادي كحلي مقروء
  static const Color textDim = Color(0xFF94A3B8);          // رمادي خفيف للتوقيتات

  // Academic White & Blue Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1E40AF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shieldGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1E3A8A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
