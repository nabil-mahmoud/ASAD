import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';

class AppUserGuideModal extends StatelessWidget {
  const AppUserGuideModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppUserGuideModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const AsadEmblem(size: 38, showLabel: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'دليل استخدام منظومة DMU',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        'دليلك الشامل لإدارة الحضور الذكي بجامعة دمنهور',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceCardBorder, height: 1),

          // Content List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // University Welcome Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightBlueBorder),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.school_rounded, color: AppColors.primaryBlue, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'نظام تسجيل الحضور الذكي المعتمد لجامعة دمنهور، مصمم لتسهيل رصد حضور الطلاب في المحاضرات والمعامل واستخراج الكشوف الرسمية المعتمدة بنقرة واحدة.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textLight,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 1: Courses
                _buildGuideCard(
                  stepNumber: '1',
                  stepBadge: 'الخطوة الأولى',
                  title: 'إعداد المقررات الدراسية',
                  icon: Icons.menu_book_rounded,
                  iconColor: AppColors.mintAccent,
                  summary: 'تسجيل وتخصيص المواد الدراسية والقاعات وتوزيع الشعب:',
                  points: [
                    'من الشاشة الرئيسية، ادخل على "المقررات الدراسية".',
                    'اضغط زر "إضافة مقرر جديد" وسجل اسم المادة، والفرقة، والقسم أو الشعبة.',
                    'حدد نوع التدريس: "نظري فقط" (للمدرجات) أو "نظري وعملي" (للمدرجات والمعامل/السكاشن).',
                    'يمكنك تعديل أي مقرر أو حذفه بسهولة في أي وقت.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 2: Excel Import
                _buildGuideCard(
                  stepNumber: '2',
                  stepBadge: 'الخطوة الثانية',
                  title: 'استيراد كشوف قيد الطلاب (Excel)',
                  icon: Icons.upload_file_rounded,
                  iconColor: const Color(0xFF60A5FA),
                  summary: 'استيراد بيانات وقوائم الطلاب من شيتات الإكسيل الرسمية:',
                  points: [
                    'ادخل على "استيراد كشوف الطلاب" واختر ملف الإكسيل (.xlsx).',
                    'يقوم النظام تلقائياً بالتعرف على الأعمدة وتعيينها (الرقم الأكاديمي، الاسم، الفرقة، القسم، والمكان أو المعمل).',
                    'حفظ كشوف الطلاب بدقة ومنع تكرار الأرقام الأكاديمية.',
                    'إمكانية فحص الكشوفات والبحث اللحظي عن أي طالب بالاسم أو الكود.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 3: Launching Session
                _buildGuideCard(
                  stepNumber: '3',
                  stepBadge: 'الخطوة الثالثة',
                  title: 'بدء جلسة غياب جديدة',
                  icon: Icons.play_circle_outline_rounded,
                  iconColor: AppColors.warningYellow,
                  summary: 'تحديد جلسة المحاضرة أو المعمل قبل فتح الكاميرا:',
                  points: [
                    'اضغط على زر "بدء جلسة غياب جديدة" من الشاشة الرئيسية.',
                    'اختر المقرر المطلوب من قائمتك المسجلة.',
                    'حدد نوع الجلسة: "محاضرة نظرية" لكامل الفرقة، أو "معمل / سكشن عملي".',
                    'في الجلسات العملية: حدد المعمل أو القاعة لتصفية الطلاب الحاضرين تلقائياً لتلك المجموعة فقط.',
                    'اضغط "بدء الجلسة وفحص الكاميرا" لفتح شاشة المسح فوراً.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 4: Optical Scanning & Anti-Duplicate
                _buildGuideCard(
                  stepNumber: '4',
                  stepBadge: 'الخطوة الرابعة',
                  title: 'المسح الضوئي الذكي وحماية التكرار',
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: AppColors.emerald,
                  summary: 'مسح فائق السرعة لكروت الطلاب مع الحماية من التلاعب:',
                  points: [
                    'وجّه كاميرا الهاتف نحو باركود أو QR كود كارنيه الطالب.',
                    'يتم التحضير في أجزاء من الثانية مع اهتزاز (Haptic) وصوت تأكيد وظهور اسم الطالب بالأخضر.',
                    'حماية ذكية من التكرار (Anti-Duplicate): لو مسح الطالب كوده مرة ثانية ينبهك النظام فوراً ببروز برتقالي "مسجل مسبقاً" مع توقيت تسجيله الأول.',
                    'مؤشر أعلى الشاشة يعرض مباشرة: إجمالي الحاضرين، ونسبة الحضور الحالية.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 5: Manual Attendance & Excuses
                _buildGuideCard(
                  stepNumber: '5',
                  stepBadge: 'الخطوة الخامسة',
                  title: 'التحضير اليدوي وتوثيق الأعذار',
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  summary: 'حل فوري في حال نسيان الطالب للكارنيه أو تلف الباركود:',
                  points: [
                    'من داخل شاشة الكاميرا، اضغط "الكشف اليدوي والبحث".',
                    'ابحث عن الطالب بالاسم أو الرقم الأكاديمي واضغط "حاضر" لتسجيله يدوياً.',
                    'يمكنك اختيار "عذر رسمي" وكتابة سبب العذر (مثل عذر طبي أو تقرير معتمد) ليتم احتساب درجاته وتوثيق العذر في التقارير.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 6: Finalizing & Exporting
                _buildGuideCard(
                  stepNumber: '6',
                  stepBadge: 'الخطوة السادسة',
                  title: 'إنهاء الجلسة وتصدير الإكسيل والـ PDF',
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: const Color(0xFF34D399),
                  summary: 'اعتماد الحضور وتوليد الكشوفات الرسمية لشؤون الطلاب:',
                  points: [
                    'اضغط على "إنهاء الجلسة واعتماد الحضور" عند انتهاء وقت المحاضرة.',
                    'يقوم النظام تلقائياً بتسجيل كل من لم يحضر كـ "غائب" برصيد صفر.',
                    'تصدير كشف Excel رسمي: 8 أعمدة كاملة بالترويسة المعتمدة ومزود بمعادلة SUM لحساب المجموع آلياً.',
                    'تصدير وطباعة PDF: جاهز للطباعة المباشرة والتوقيع.',
                    'مشاركة سريعة: إرسال الكشف فوراً عبر WhatsApp أو الإيميل بنقرة واحدة.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 7: Archive & Single Session Deletion
                _buildGuideCard(
                  stepNumber: '7',
                  stepBadge: 'الخطوة السابعة',
                  title: 'الأرشيف وحذف محاضرة بذاتها',
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFA78BFA),
                  summary: 'إدارة المحاضرات السابقة وحذف جلسة محددة بشكل مستقل:',
                  points: [
                    'قسم "سجل الأرشيف" يحتوي على جميع جلسات الغياب والمحاضرات السابقة بالتاريخ والوقت والنسب.',
                    'يمكنك إعادة استعراض أو تصدير أي محاضرة سابقة، أو حتى استئناف التحضير فيها.',
                    'حذف محاضرة واحدة بذاتها: يمكنك الضغط على أيقونة الحذف بجانب أي محاضرة في الأرشيف (أو داخل شاشة تفاصيلها) لحذفها فقط دون التأثير على بقية الأرشيف أو الطلاب أو المقررات.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 8: Cumulative Reports
                _buildGuideCard(
                  stepNumber: '8',
                  stepBadge: 'الخطوة الثامنة',
                  title: 'التقارير التراكمية وإنذارات الحرمان',
                  icon: Icons.analytics_outlined,
                  iconColor: const Color(0xFF38BDF8),
                  summary: 'متابعة غياب الطلاب طوال الفصل الدراسي وأعمال السنة:',
                  points: [
                    'ادخل على "التقارير التراكمية" واختر أي مقرر لعرض إحصائيات الترم كاملاً.',
                    'تجميع تلقائي لعدد المحاضرات التي حضرها أو غابها كل طالب والدرجة التراكمية الإجمالية.',
                    'توليد كشوف إنذارات الحرمان الأكاديمي للطلاب الذين تجاوزوا نسب الغياب القانونية.',
                  ],
                ),
                const SizedBox(height: 14),

                // Step 9: Settings & Selective Reset
                _buildGuideCard(
                  stepNumber: '9',
                  stepBadge: 'الخطوة التاسعة',
                  title: 'الإعدادات وخيارات إعادة الضبط المخصصة',
                  icon: Icons.tune_rounded,
                  iconColor: AppColors.dangerRed,
                  summary: 'تعديل الملف الأكاديمي وخيارات الريسيت المرنة:',
                  points: [
                    'تحديث اسم عضو هيئة التدريس ليظهر معتمداً في ترويسة التقارير.',
                    'خيارات إعادة الضبط المخصصة (Reset):',
                    '• مسح أرشيف جلسات الغياب فقط: يفرغ سجلات المحاضرات السابقة مع الحفاظ على المقررات والطلاب.',
                    '• مسح كشوف قيد الطلاب فقط: يحذف بيانات وقوائم الطلاب لتحديثها مع الحفاظ على المقررات.',
                    '• مسح المقررات والأرشيف: يحذف المواد الدراسية وجلساتها مع الحفاظ على الطلاب.',
                    '• مسح شامل وإعادة ضبط المصنع: يمسح كل شيء بالكامل ويعود بالتطبيق جديداً كأول تشغيل.',
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Close Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.surfaceCardBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'فهمت، إغلاق الدليل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildGuideCard({
    required String stepNumber,
    required String stepBadge,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String summary,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stepBadge,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: iconColor),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 8),
          ...points.map(
            (pt) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      pt,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.45),
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
