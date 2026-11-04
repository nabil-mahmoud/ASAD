import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';
import '../controllers/app_state.dart';
import 'screen_0_onboarding.dart';

class Screen8Settings extends StatefulWidget {
  const Screen8Settings({super.key});

  @override
  State<Screen8Settings> createState() => _Screen8SettingsState();
}

class _Screen8SettingsState extends State<Screen8Settings> {
  final AppState _appState = AppState();
  final TextEditingController _nameController = TextEditingController();
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _appState.doctorProfile?.doctorName ?? '';
    _appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _saveDoctorName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم عضو هيئة التدريس'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isSavingName = true);
    await _appState.saveDoctorName(name);
    setState(() => _isSavingName = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ وتحديث الاسم بنجاح'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }
  }

  void _showFactoryResetConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.dangerRed, width: 1.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'إعادة ضبط المصنع (سوفت وير)',
                style: TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'تحذير شديد الأهمية:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'سيتم حذف كافة المقررات الدراسية، وكشوفات الطلاب، وسجلات الغياب نهائياً من الذاكرة المحلية ولن يمكن استرجاعها.\n\nسيعود التطبيق إلى حالته الأولى تماماً كما لو تم تثبيته للتو.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: const Text('تأكيد المسح الشامل'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _executeFactoryReset();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _executeFactoryReset() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          color: AppColors.surfaceDark,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.dangerRed),
                SizedBox(height: 16),
                Text(
                  'جاري تنظيف الذاكرة وإعادة الضبط...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await _appState.factoryReset();

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading dialog

    // Navigate to Onboarding screen clearing navigation stack completely
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const Screen0Onboarding(isEditing: false),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات وإدارة النظام'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: Column(
                      children: const [
                        AsadEmblem(size: 72),
                        SizedBox(height: 8),
                        Text(
                          'نظام ASAD لتسجيل الحضور الذكي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'الإصدار 1.0.1 (Offline Edition)',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Doctor Profile
                  _buildSectionCard(
                    title: 'الملف الأكاديمي لعضو هيئة التدريس',
                    icon: Icons.person_outline_rounded,
                    accentColor: AppColors.emerald,
                    children: [
                      const Text(
                        'اسم الدكتور / المدرس يظهر في الترويسة المعتمدة للكشوفات الصادرة (Excel و PDF):',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school_outlined, color: AppColors.emerald),
                          hintText: 'أدخل الاسم الأكاديمي (مثال: أ.د. نبيل محمود)',
                          hintStyle: const TextStyle(color: AppColors.textDim),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.emerald.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSavingName ? null : _saveDoctorName,
                          icon: _isSavingName
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded, size: 20),
                          label: const Text('حفظ التعديلات'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Storage & Database Health
                  _buildSectionCard(
                    title: 'إحصائيات وقاعدة البيانات المحلية',
                    icon: Icons.storage_rounded,
                    accentColor: const Color(0xFF60A5FA),
                    children: [
                      _buildInfoRow('حالة النظام:', 'يعمل أوفلاين محلياً 100% (SQLite)', AppColors.emerald),
                      const Divider(color: AppColors.surfaceCardBorder, height: 20),
                      _buildInfoRow('عدد المقررات المسجلة:', '${_appState.courses.length} مقرر', Colors.white),
                      const SizedBox(height: 8),
                      _buildInfoRow('إجمالي الطلاب بالكشوفات:', '${_appState.totalStudents} طالب', Colors.white),
                      const SizedBox(height: 8),
                      _buildInfoRow('عدد الجلسات والمحاضرات:', '${_appState.sessions.length} جلسة', Colors.white),
                      const SizedBox(height: 8),
                      _buildInfoRow('حالة تشفير وسلامة البيانات:', 'سليمة ومخزنة محلياً', AppColors.mintAccent),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Dangerous Factory Reset
                  _buildSectionCard(
                    title: 'منطقة الخطر: إعادة ضبط المصنع الشامل',
                    icon: Icons.restore_rounded,
                    accentColor: AppColors.dangerRed,
                    children: [
                      const Text(
                        'في حال رغبت في بدء عام دراسي جديد بالكامل أو إعادة تهيئة النظام ومسح كل المقررات وكشوف الطلاب والمحاضرات دفعة واحدة كأن التطبيق جديد تماماً:',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dangerRed.withOpacity(0.15),
                            foregroundColor: AppColors.dangerRed,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.dangerRed, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _showFactoryResetConfirmation,
                          icon: const Icon(Icons.delete_forever_rounded, size: 22),
                          label: const Text(
                            'سوفت وير للتطبيق (إعادة ضبط المصنع)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
