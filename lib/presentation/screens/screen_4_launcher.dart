import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/course.dart';
import '../controllers/app_state.dart';
import 'screen_5_scanner.dart';

class Screen4Launcher extends StatefulWidget {
  const Screen4Launcher({super.key});

  @override
  State<Screen4Launcher> createState() => _Screen4LauncherState();
}

class _Screen4LauncherState extends State<Screen4Launcher> {
  final AppState _appState = AppState();

  Course? _selectedCourse;
  String _selectedSessionType = 'lecture'; // 'lecture' | 'lab_practical' | 'lab_theory'
  String? _selectedLocation;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    if (_appState.courses.isNotEmpty) {
      _selectedCourse = _appState.courses.first;
      _adjustForCourseTeachingType();
    }
  }

  void _adjustForCourseTeachingType() {
    if (_selectedCourse == null) return;
    if (_selectedCourse!.isTheoryOnly) {
      // Force lecture type only
      _selectedSessionType = 'lecture';
      _selectedLocation = null;
    } else {
      // Practical default location
      if (_selectedLocation == null && _appState.uniqueLocations.isNotEmpty) {
        _selectedLocation = _appState.uniqueLocations.first;
      }
    }
  }

  Future<void> _launchSession() async {
    if (_selectedCourse == null) return;

    if ((_selectedSessionType == 'lab_practical' || _selectedSessionType == 'lab_theory') &&
        (_selectedLocation == null || _selectedLocation!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد المكان المخصص (المعمل أو القاعة) للدرس العملي'),
          backgroundColor: AppColors.warningYellow,
        ),
      );
      return;
    }

    setState(() => _isLaunching = true);

    try {
      await _appState.launchNewSession(
        course: _selectedCourse!,
        sessionType: _selectedSessionType,
        location: _selectedLocation,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Screen5Scanner()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء تهيئة الجلسة: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = _appState.courses;
    final locations = _appState.uniqueLocations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تهيئة جلسة الحضور بالقاعة'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step 1: Course Selection
                  _stepContainer(
                    stepNumber: 1,
                    title: 'اختيار المقرر الدراسي',
                    subtitle: 'حدد المادة التي ستعقد جلستها الآن',
                    child: DropdownButtonFormField<Course>(
                      value: _selectedCourse,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.book_rounded, color: AppColors.emerald),
                      ),
                      items: courses.map((c) {
                        return DropdownMenuItem<Course>(
                          value: c,
                          child: Text(
                            '${c.courseName} - ${c.gradeYear} (${c.teachingTypeArabic})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (course) {
                        setState(() {
                          _selectedCourse = course;
                          _adjustForCourseTeachingType();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 2: Session Type
                  _stepContainer(
                    stepNumber: 2,
                    title: 'تحديد نوع الجلسة',
                    subtitle: _selectedCourse?.isTheoryOnly == true
                        ? 'مقرر نظري فقط: تم حجب خيارات المعامل تلقائياً منعاً للأخطاء'
                        : 'اختر بين محاضرة عامة أو درس عملي/سكشن مقيد بالمكان',
                    child: Column(
                      children: [
                        _typeTile(
                          id: 'lecture',
                          title: 'محاضرة نظري عامة',
                          subtitle: 'مدرج عام لكامل الفرقة الدراسية',
                          icon: Icons.record_voice_over_rounded,
                        ),
                        if (_selectedCourse?.hasPractical ?? true) ...[
                          const SizedBox(height: 10),
                          _typeTile(
                            id: 'lab_practical',
                            title: 'درس عملي - تطبيقي (معمل)',
                            subtitle: 'مقيد بالمكان المخصص للمعمل وفلترة الطلاب',
                            icon: Icons.computer_rounded,
                          ),
                          const SizedBox(height: 10),
                          _typeTile(
                            id: 'lab_theory',
                            title: 'سكشن نظري / تمارين',
                            subtitle: 'سكشن لمجموعة في قاعة مخصصة',
                            icon: Icons.assignment_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 3 (For practical / lab sessions): Location Selection
                  if (_selectedSessionType == 'lab_practical' || _selectedSessionType == 'lab_theory') ...[
                    _stepContainer(
                      stepNumber: 3,
                      title: 'تحديد المكان المخصص (المعمل / القاعة)',
                      subtitle: 'سيقيد النظام قبول المسح بطلاب هذا المكان فقط لمنع التسلل والخلط',
                      child: locations.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warningYellow.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warningYellow.withOpacity(0.4)),
                              ),
                              child: const Text(
                                'تنبيه: لا توجد أماكن معرفة في كشف الطلاب حالياً. يمكنك كتابة المكان أدناه.',
                                style: TextStyle(fontSize: 12, color: AppColors.warningYellow),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedLocation ?? (locations.isNotEmpty ? locations.first : null),
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.meeting_room_rounded, color: AppColors.emerald),
                                  ),
                                  items: locations.map((loc) {
                                    return DropdownMenuItem<String>(
                                      value: loc,
                                      child: Text(
                                        loc,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (loc) {
                                    setState(() => _selectedLocation = loc);
                                  },
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'أمثلة: معمل برمجة أ، معمل شبكات ب، قاعة 3',
                                  style: TextStyle(fontSize: 11, color: AppColors.textDim),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Big Launch Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emerald.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLaunching ? null : _launchSession,
                      icon: _isLaunching
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 26),
                      label: const Text(
                        'فتح الكاميرا وبدء المسح السريع',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContainer({
    required int stepNumber,
    required String title,
    required String subtitle,
    required Widget child,
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
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _typeTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedSessionType == id;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSessionType = id;
          if (id == 'lecture') {
            _selectedLocation = null;
          } else if (_selectedLocation == null && _appState.uniqueLocations.isNotEmpty) {
            _selectedLocation = _appState.uniqueLocations.first;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald.withOpacity(0.18) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.surfaceCardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.mintAccent : AppColors.textMuted, size: 24),
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
                      color: isSelected ? Colors.white : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.mintAccent, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
