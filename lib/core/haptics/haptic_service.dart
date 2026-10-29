import 'package:flutter/services.dart';

/// Haptic Feedback Service according to ASAD Technical Specifications (Page 4)
class HapticService {
  /// 1. مسح ناجح ومقيد: نبضة خفيفة (Light)
  static Future<void> lightFeedback() async {
    await HapticFeedback.lightImpact();
  }

  /// 2. تكرار المسح: نبضتان متوسطتان
  static Future<void> doubleMediumFeedback() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// 3. طالب غير مسجل بالمكان: اهتزاز تحذيري قوي
  static Future<void> strongWarningFeedback() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.vibrate();
  }

  /// 4. تحضير يدوي / عذر: نبضة لطيفة
  static Future<void> gentlePulseFeedback() async {
    await HapticFeedback.selectionClick();
  }
}
