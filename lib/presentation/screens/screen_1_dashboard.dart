import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';
import '../controllers/app_state.dart';
import '../widgets/offline_indicator_pill.dart';
import 'screen_2_courses.dart';
import 'screen_3_importer.dart';
import 'screen_4_launcher.dart';
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
    final coursesCount = _appState.courses.length;
    final studentsCount = _appState.totalStudents;
    final sessionsCount = _appState.sessions.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AsadEmblem(size: 32, showLabel: false),
            SizedBox(width: 8),
            Text(
              'منظومة ASAD',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: OfflineIndicatorPill(compact: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
          color: AppColors.emerald,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Card: Doctor Greeting + App Branding
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.shieldGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.emerald.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalDark.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const OfflineIndicatorPill(),
                                const SizedBox(height: 12),
                                Text(
                                  'أهلاً بك، $doctorName 👋',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'النظام جاهز ومستقر محلياً في المدرج بدون الحاجة لأي اتصال بالإنترنت.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const AsadEmblem(size: 72, showLabel: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

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
                        onPressed: () {
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
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const Screen4Launcher()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 28),
                        label: const Text(
                          'بدء جلسة غياب جديدة بالقاعة',
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
                      title: 'الإعدادات وسوفت وير التطبيق',
                      subtitle: 'الملف الأكاديمي، إحصائيات النظام، وإعادة ضبط المصنع الشامل',
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
}
