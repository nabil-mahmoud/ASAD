import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The Official DMU Emblem (شعار جامعة دمنهور المعتمد)
/// Placed neatly on a clean white rounded square with subtle shadow and border.
class AsadEmblem extends StatelessWidget {
  final double size;
  final bool showLabel;
  final bool compact;

  const AsadEmblem({
    super.key,
    this.size = 120,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.08),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1).withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/dmu_logo_square.png',
            fit: BoxFit.contain,
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: compact ? 6 : 12),
          const Text(
            'DMU',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: const Text(
              'جامعة دمنهور - Damanhour University',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

typedef DmuEmblem = AsadEmblem;
