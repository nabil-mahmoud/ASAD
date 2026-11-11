import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';
import '../controllers/app_state.dart';
import '../widgets/app_user_guide_modal.dart';
import 'screen_2_courses.dart';
import 'screen_3_importer.dart';
import 'screen_4_launcher.dart';
import 'screen_5_scanner.dart';
import 'screen_6_archive.dart';
import 'screen_7_cumulative_reports.dart';
import 'screen_8_settings.dart';

class Screen1Dashboard extends StatefulWidget {
  const Screen1Dashboard({super.key});

  @override
  State<Screen1Dashboard> createState() => _Screen1DashboardState();
}

class _Screen1DashboardState extends State<Screen1Dashboard> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = _appState.doctorProfile?.doctorName ?? 'دكتور';
    final facultyName = _appState.doctorProfile?.facultyName;
    final coursesCount = _appState.courses.length;
    final studentsCount = _appState.totalStudents;
    final sessionsCount = _appState.sessions.length;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AsadEmblem(size: 32, showLabel: false),
            SizedBox(width: 8),
            Text(
              'DMU',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.primaryBlue),
            tooltip: 'كيفية استخدام التطبيق (دليل كامل)',
            onPressed: () => AppUserGuideModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
            tooltip: 'الإعدادات وإدارة النظام',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Screen8Settings()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _appState.refreshAll(),
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Card: Doctor Greeting + University Branding
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.lightBlueBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1).withOpacity(0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    facultyName != null && facultyName.isNotEmpty ? facultyName : 'جامعة دمنهور',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'أهلاً بك، $doctorName 👋',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'نظام تسجيل الحضور والغياب الذكي المعتمد لجامعة دمنهور.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const AsadEmblem(size: 68, showLabel: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pending / Ongoing Active Session Banner
                    if (_appState.hasPendingSession)
                      _buildPendingSessionBanner(context),

                    // 2. Quick Action: Prominent Start Session CTA
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          if (_appState.courses.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('يرجى إضافة مقرر دراسي أولاً لبدء جلسة الغياب'),
                                backgroundColor: AppColors.warningYellow,
                              ),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const Screen2Courses()),
                            );
                            return;
                          }

                          if (_appState.hasPendingSession) {
                            final choice = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surfaceDark,
                                title: const Text('تنبيه: توجد جلسة جارية'),
                                content: Text(
                                  'توجد حالياً جلسة معلقة لمقرر (${_appState.activeCourse?.courseName ?? "المقرر"}).\nهل تريد استئنافها أم إنهاؤها وبدء جلسة جديدة؟',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, 'cancel'),
                                    child: const Text('تراجع'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, 'new'),
                                    child: const Text('بدء جلسة جديدة'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
                                    onPressed: () => Navigator.pop(ctx, 'resume'),
                                    child: const Text('استئناف الجلسة الجارية'),
                                  ),
                                ],
                              ),
                            );
                            if (choice == 'resume') {
                              if (context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const Screen5Scanner()),
                                );
                              }
                              return;
                            } else if (choice != 'new') {
                              return;
                            }
                          }

                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const Screen4Launcher()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                        label: const Text(
                          'بدء جلسة غياب جديدة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title: Main Modules (Single destination for each)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'الوحدات والخدمات الأكاديمية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '5 وحدات متكاملة',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Module 1: المقررات الدراسية (Courses)
                    _moduleCard(
                      title: 'المقررات الدراسية',
                      subtitle: 'إعداد المواد (نظري / عملي)، الشعب، وتوزيع القاعات',
                      countBadge: '$coursesCount مقرر',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.mintAccent,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Screen2Courses()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Module 2: كشوف الطلاب (Students Roster)
                    _moduleCard(
                      title: 'كشوف وقوائم الطلاب',
                      subtitle: 'استيراد شيت شؤون الطلاب، إدارة الأسماء، والبحث في الدفعة',
                      countBadge: '$studentsCount طالب',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF60A5FA),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Screen3Importer()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Module 3: سجل المحاضرات (Session Archive)
                    _moduleCard(
                      title: 'سجل المحاضرات والأرشيف',
                      subtitle: 'مراجعة المحاضرات المنفردة، تعديل الحضور، وتصدير شيت كل جلسة',
                      countBadge: '$sessionsCount جلسة',
                      icon: Icons.archive_rounded,
                      color: const Color(0xFFFBBF24),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Screen6Archive()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Module 4: التقرير التراكمي للمواد (Cumulative Course Reports)
                    _moduleCard(
                      title: 'التقرير التراكمي للمواد (سجل الرصد)',
                      subtitle: 'تجميع كل المحاضرات، نسب الحضور والحرمان، وتصدير شيت الدرجات النهائي',
                      countBadge: 'تراكمي شامل',
                      badgeColor: const Color(0xFFA855F7),
                      icon: Icons.insights_rounded,
                      color: const Color(0xFFA855F7),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Screen7CumulativeReports()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Module 5: الإعدادات (Settings)
                    _moduleCard(
                      title: 'الإعدادات وإدارة النظام',
                      subtitle: 'الملف الأكاديمي، الكلية التابع لها، وإدارة البيانات',
                      countBadge: 'إدارة النظام',
                      badgeColor: AppColors.textDim,
                      icon: Icons.settings_rounded,
                      color: const Color(0xFF94A3B8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Screen8Settings()),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moduleCard({
    required String title,
    required String subtitle,
    required String countBadge,
    Color? badgeColor,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceCardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            countBadge,
                            style: TextStyle(
                              fontSize: 11,
                              color: badgeColor ?? color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDim),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingSessionBanner(BuildContext context) {
    final session = _appState.activeSession!;
    final course = _appState.activeCourse;
    final presentCount = _appState.activePresentCount;
    final totalCount = _appState.activeTotalTargetCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warningYellow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.warningYellow.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningYellow.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_circle_filled_rounded, color: AppColors.warningYellow, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'جلسة حضور جارية (معلقة)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warningYellow,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                ),
                child: Text(
                  '$presentCount / $totalCount حاضر',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${course?.courseName ?? "المقرر"} • ${session.sessionTypeArabic} • ${session.location ?? "الكل"}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          const Text(
            'تم تعليق هذه الجلسة تلقائياً لضمان عدم إغلاقها عن طريق الخطأ. يمكنك استئناف مسح الطلاب أو حفظها الآن.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Screen5Scanner()),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const Text(
                    'استئناف المسح بالقاعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: const BorderSide(color: AppColors.surfaceCardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await _appState.finalizeAndSaveSession();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إنهاء الجلسة وحفظها في الأرشيف بنجاح'),
                          backgroundColor: AppColors.emerald,
                        ),
                      );
                    }
                  },
                  child: const Text('إنهاء وحفظ', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed),
                tooltip: 'إلغاء وحذف الجلسة',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceDark,
                      title: const Text('إلغاء الجلسة المعلقة'),
                      content: const Text('هل أنت متأكد من حذف هذه الجلسة المعلقة بالكامل؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف الجلسة'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _appState.cancelActiveSession();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
