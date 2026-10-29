import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';
import '../controllers/app_state.dart';
import '../widgets/offline_indicator_pill.dart';
import '../widgets/stat_card.dart';
import 'screen_0_onboarding.dart';
import 'screen_2_courses.dart';
import 'screen_3_importer.dart';
import 'screen_4_launcher.dart';
import 'screen_6_archive.dart';

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
          children: [
            const AsadEmblem(size: 32, showLabel: false),
            const SizedBox(width: 8),
            const Text(
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
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'تعديل اسم الدكتور',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Screen0Onboarding(isEditing: true),
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card: Greeting & Offline Assurance
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
                          const AsadEmblem(size: 75, showLabel: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Floating CTA: "بدء جلسة غياب جديدة"
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

                    // Section Title: Statistics
                    const Text(
                      'نظرة عامة على المقررات والطلاب',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3 Statistical Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'عدد المقررات',
                            value: '$coursesCount',
                            icon: Icons.menu_book_rounded,
                            accentColor: AppColors.mintAccent,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const Screen2Courses()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'إجمالي الطلاب',
                            value: '$studentsCount',
                            icon: Icons.groups_rounded,
                            accentColor: const Color(0xFF60A5FA),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const Screen3Importer()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'الجلسات المحفوظة',
                            value: '$sessionsCount',
                            icon: Icons.archive_rounded,
                            accentColor: const Color(0xFFFBBF24),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const Screen6Archive()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Navigation Quick Action Cards
                    const Text(
                      'الوصول السريع للأدوات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Courses Card
                        Expanded(
                          child: _actionCard(
                            title: 'إدارة المقررات',
                            subtitle: 'إعداد المواد (نظري / عملي)',
                            icon: Icons.library_books_rounded,
                            color: AppColors.mintAccent,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const Screen2Courses()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Excel Importer Card
                        Expanded(
                          child: _actionCard(
                            title: 'استيراد الدفعة',
                            subtitle: 'تغذية شيت شؤون الطلاب',
                            icon: Icons.file_upload_outlined,
                            color: const Color(0xFF34D399),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const Screen3Importer()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sessions Archive Card
                    _actionCard(
                      title: 'أرشيف الجلسات وتصدير الكشوفات',
                      subtitle: 'تصدير إكسيل بمعادلات SUM وتقارير PDF معتمدة ومشاركتها فوراً',
                      icon: Icons.history_edu_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Screen6Archive()),
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

  Widget _actionCard({
    required String title,
    required String subtitle,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceCardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
