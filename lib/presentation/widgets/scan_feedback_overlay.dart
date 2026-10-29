import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/app_state.dart';

class ScanFeedbackOverlay extends StatelessWidget {
  final ScanResult? result;

  const ScanFeedbackOverlay({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    Color borderColor;
    Color bannerColor;
    IconData icon;
    String title;
    String subtitle;

    switch (result!.type) {
      case ScanFeedbackType.success:
        borderColor = AppColors.successGreen;
        bannerColor = AppColors.successGreen;
        icon = Icons.check_circle_rounded;
        title = result!.student?.fullName ?? 'حاضر';
        subtitle = 'تم رصد الحضور بنجاح | الكود: ${result!.academicId}';
        break;

      case ScanFeedbackType.duplicate:
        borderColor = AppColors.warningYellow;
        bannerColor = AppColors.warningYellow;
        icon = Icons.warning_amber_rounded;
        title = 'مسجل مسبقاً بالجلسة';
        subtitle = '${result!.student?.fullName ?? result!.academicId} مسجل بالفعل';
        break;

      case ScanFeedbackType.wrongLocation:
        borderColor = AppColors.dangerRed;
        bannerColor = AppColors.dangerRed;
        icon = Icons.cancel_rounded;
        title = 'طالب غير مسجل بالمكان';
        subtitle = result!.actualLocation != null
            ? 'المكان الفعلي للطالب: ${result!.actualLocation}'
            : result!.message;
        break;

      case ScanFeedbackType.manualSuccess:
        borderColor = AppColors.manualBlue;
        bannerColor = AppColors.manualBlue;
        icon = Icons.how_to_reg_rounded;
        title = result!.message;
        subtitle = result!.student != null
            ? '${result!.student!.fullName} (${result!.academicId})'
            : result!.academicId;
        break;
    }

    return IgnorePointer(
      child: Stack(
        children: [
          // Flashing Border around the view
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 6),
            ),
          ),
          // Top / Center Floating Banner
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bannerColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: bannerColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
