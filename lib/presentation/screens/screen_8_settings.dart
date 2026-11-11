import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';
import '../controllers/app_state.dart';
import '../widgets/app_user_guide_modal.dart';
import 'screen_0_onboarding.dart';

class Screen8Settings extends StatefulWidget {
  const Screen8Settings({super.key});

  @override
  State<Screen8Settings> createState() => _Screen8SettingsState();
}

class _Screen8SettingsState extends State<Screen8Settings> {
  final AppState _appState = AppState();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _appState.doctorProfile?.doctorName ?? '';
    _facultyController.text = _appState.doctorProfile?.facultyName ?? '';
    _appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyController.dispose();
    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _saveDoctorProfile() async {
    final name = _nameController.text.trim();
    final faculty = _facultyController.text.trim();
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
    await _appState.saveDoctorProfile(name: name, facultyName: faculty);
    setState(() => _isSavingName = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ البيانات الأكاديمية بنجاح'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  // ---------------- Selective Reset Dialogs & Sheet ----------------

  void _showResetOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: const [
                Icon(Icons.tune_rounded, color: AppColors.warningYellow, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'خيارات إعادة الضبط ومسح البيانات',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'حدد بدقة البيانات التي ترغب في مسحها من الذاكرة المحلية:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Option 1: مسح أرشيف جلسات الغياب فقط
            _buildResetOptionTile(
              title: 'مسح أرشيف جلسات الغياب والمحاضرات فقط',
              subtitle: 'حذف جميع سجلات الحضور السابقة مع الاحتفاظ بالطلاب والمقررات',
              icon: Icons.history_toggle_off_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _confirmClearSessionsArchive();
              },
            ),
            const SizedBox(height: 10),

            // Option 2: مسح كشوف قيد الطلاب فقط
            _buildResetOptionTile(
              title: 'مسح كشوف قيد الطلاب فقط',
              subtitle: 'حذف بيانات وقوائم الطلاب المستوردة مع الإبقاء على المقررات وجلساتها',
              icon: Icons.group_remove_rounded,
              color: const Color(0xFFF97316),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _confirmClearStudents();
              },
            ),
            const SizedBox(height: 10),

            // Option 3: مسح المقررات الدراسية وأرشيفها
            _buildResetOptionTile(
              title: 'مسح المقررات الدراسية وأرشيفها',
              subtitle: 'حذف المواد والمقررات وجلسات حضورها مع الاحتفاظ بكشوف الطلاب',
              icon: Icons.menu_book_rounded,
              color: const Color(0xFFE11D48),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _confirmClearCoursesAndArchive();
              },
            ),
            const SizedBox(height: 10),

            // Option 4: مسح شامل وإعادة ضبط المصنع
            _buildResetOptionTile(
              title: 'مسح شامل وإعادة ضبط المصنع (المقررات + الطلاب + الأرشيف)',
              subtitle: 'حذف كل شيء والبدء من الصفر تماماً كأول تشغيل',
              icon: Icons.delete_forever_rounded,
              color: AppColors.dangerRed,
              isDestructive: true,
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _showFactoryResetConfirmation();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmClearSessionsArchive() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'مسح أرشيف جلسات الغياب',
                style: TextStyle(color: Color(0xFFF59E0B), fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'سيتم مسح سجلات كافة جلسات الغياب والمحاضرات السابقة (${_appState.sessions.length} جلسة) نهائياً.\n\nسيتم الإبقاء على المقررات الدراسية وكشوف الطلاب دون أي تعديل.\n\nهل ترغب بالاستمرار؟',
          style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: const Text('تأكيد مسح الأرشيف', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _appState.clearSessionsArchive();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم مسح أرشيف جلسات الغياب بالكامل بنجاح'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearStudents() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF97316), width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316), size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'مسح كشوف قيد الطلاب',
                style: TextStyle(color: Color(0xFFF97316), fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'سيتم مسح بيانات كافة الطلاب المسجلين (${_appState.totalStudents} طالب) نهائياً من قاعدة البيانات.\n\nسيتم الإبقاء على المقررات الدراسية وجلسات الغياب.\n\nهل ترغب بالاستمرار؟',
          style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.group_remove_rounded, size: 18),
            label: const Text('تأكيد مسح الطلاب'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _appState.clearAllStudents();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم مسح كشوف قيد الطلاب بنجاح'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearCoursesAndArchive() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'مسح المقررات والأرشيف',
                style: TextStyle(color: Color(0xFFE11D48), fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'سيتم مسح كافة المقررات الدراسية (${_appState.courses.length} مقرر) وجميع جلسات الغياب المرتبطة بها نهائياً.\n\nسيتم الإبقاء على كشوف قيد الطلاب.\n\nهل ترغب بالاستمرار؟',
          style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_sweep_rounded, size: 18),
            label: const Text('تأكيد المسح'),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _appState.clearCoursesAndSessions();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم مسح المقررات الدراسية وأرشيفها بنجاح'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
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
                'مسح شامل وإعادة ضبط المصنع',
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
                color: AppColors.textLight,
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
                  style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.mintAccent),
            tooltip: 'دليل استخدام المنظومة',
            onPressed: () => AppUserGuideModal.show(context),
          ),
          const SizedBox(width: 8),
        ],
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
                        SizedBox(height: 10),
                        Text(
                          'نظام DMU لتسجيل الحضور الذكي',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'جامعة دمنهور - Damanhour University',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Comprehensive Guide Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lightBlueBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.help_outline_rounded, color: AppColors.primaryBlue, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'دليل كيفية استخدام التطبيق بالكامل',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'شرح مفصل لكافة خطوات إعداد المقررات، استيراد شيتات الإكسيل، المسح الضوئي الذكي، التحضير اليدوي والأعذار، والتصدير وحذف المحاضرات.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => AppUserGuideModal.show(context),
                            icon: const Icon(Icons.menu_book_rounded, size: 19),
                            label: const Text(
                              'عرض الدليل الإرشادي الشامل',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Doctor Profile & College
                  _buildSectionCard(
                    title: 'الملف الأكاديمي والكلية التابع لها',
                    icon: Icons.person_outline_rounded,
                    accentColor: AppColors.primaryBlue,
                    children: [
                      const Text(
                        'تظهر هذه البيانات رسمياً في ترويسة كافة كشوفات الغياب الصادرة (Excel و PDF):',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'اسم عضو هيئة التدريس / القائم بالتدريس:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textLight),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue),
                          hintText: 'أدخل الاسم الأكاديمي (مثال: أ.د. نبيل محمود)',
                          hintStyle: const TextStyle(color: AppColors.textDim),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'الكلية التابع لها بجامعة دمنهور:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _facultyController,
                        style: const TextStyle(color: AppColors.textLight),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primaryBlue),
                          hintText: 'أدخل اسم الكلية (مثال: كلية العلوم / كلية الزراعة / كلية الهندسة)',
                          hintStyle: const TextStyle(color: AppColors.textDim),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSavingName ? null : _saveDoctorProfile,
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

                  // Section 2: University & Academic Stats
                  _buildSectionCard(
                    title: 'بيانات الجامعة وإحصائيات النظام',
                    icon: Icons.domain_rounded,
                    accentColor: AppColors.primaryBlue,
                    children: [
                      _buildInfoRow('الجامعة:', 'جامعة دمنهور (DMU)', AppColors.primaryBlue),
                      const Divider(color: AppColors.surfaceCardBorder, height: 18),
                      _buildInfoRow(
                        'الكلية:',
                        _appState.doctorProfile?.facultyName?.isNotEmpty == true
                            ? _appState.doctorProfile!.facultyName!
                            : 'يرجى تحديد الكلية أعلاه',
                        AppColors.primaryBlue,
                      ),
                      const Divider(color: AppColors.surfaceCardBorder, height: 18),
                      _buildInfoRow('عدد المقررات المسجلة:', '${_appState.courses.length} مقرر', AppColors.textLight),
                      const SizedBox(height: 8),
                      _buildInfoRow('إجمالي الطلاب بالكشوفات:', '${_appState.totalStudents} طالب', AppColors.textLight),
                      const SizedBox(height: 8),
                      _buildInfoRow('عدد الجلسات والمحاضرات:', '${_appState.sessions.length} جلسة', AppColors.textLight),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Selective Reset & Data Management
                  _buildSectionCard(
                    title: 'خيارات إعادة الضبط والمسح (Reset)',
                    icon: Icons.restore_rounded,
                    accentColor: AppColors.dangerRed,
                    children: [
                      const Text(
                        'يمكنك مسح وتفريغ أجزاء محددة من بيانات التطبيق بأمان تام، أو إجراء مسح شامل لبدء عام دراسي جديد:',
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
                          onPressed: _showResetOptionsSheet,
                          icon: const Icon(Icons.tune_rounded, size: 22),
                          label: const Text(
                            'خيارات إعادة الضبط والمسح (مخصص / شامل)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildQuickResetRow(
                        title: 'مسح أرشيف جلسات الغياب فقط',
                        subtitle: '${_appState.sessions.length} جلسة بالأرشيف',
                        icon: Icons.history_toggle_off_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: _confirmClearSessionsArchive,
                      ),
                      const Divider(color: AppColors.surfaceCardBorder, height: 16),
                      _buildQuickResetRow(
                        title: 'مسح كشوف قيد الطلاب فقط',
                        subtitle: '${_appState.totalStudents} طالب مسجل',
                        icon: Icons.group_remove_rounded,
                        color: const Color(0xFFF97316),
                        onTap: _confirmClearStudents,
                      ),
                      const Divider(color: AppColors.surfaceCardBorder, height: 16),
                      _buildQuickResetRow(
                        title: 'مسح المقررات والأرشيف',
                        subtitle: '${_appState.courses.length} مقرر دراسي',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFFE11D48),
                        onTap: _confirmClearCoursesAndArchive,
                      ),
                      const Divider(color: AppColors.surfaceCardBorder, height: 16),
                      _buildQuickResetRow(
                        title: 'مسح شامل وإعادة ضبط المصنع',
                        subtitle: 'حذف المقررات والطلاب والأرشيف والبدء من الصفر',
                        icon: Icons.delete_forever_rounded,
                        color: AppColors.dangerRed,
                        onTap: _showFactoryResetConfirmation,
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

  Widget _buildResetOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive ? color.withOpacity(0.6) : AppColors.surfaceCardBorder,
            width: isDestructive ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDestructive ? AppColors.dangerRed : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickResetRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textLight),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                'مسح',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
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
                    color: AppColors.textLight,
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
