import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OfflineIndicatorPill extends StatelessWidget {
  final bool compact;

  const OfflineIndicatorPill({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.mintAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            compact ? 'OFFLINE' : 'OFFLINE | يعمل بدون إنترنت 100%',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mintAccent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
