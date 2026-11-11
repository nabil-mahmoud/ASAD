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
  final TextEditingController _customLocationController = TextEditingController();

  Course? _selectedCourse;
  String _selectedSessionType = 'lecture'; // 'lecture' | 'lab_theory' | 'lab_practical'
  String? _selectedLocation;
  List<String> _courseLocations = [];
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    if (_appState.courses.isNotEmpty) {
      _selectedCourse = _appState.courses.first;
      _adjustForCourseTeachingType();
      _updateLocationsForSelectedCourse();
    }
  }

  @override
  void dispose() {
    _customLocationController.dispose();
    super.dispose();
  }

  Future<void> _updateLocationsForSelectedCourse() async {
    if (_selectedCourse == null) {
      setState(() => _courseLocations = []);
      return;
    }
    final locs = await _appState.getLocationsForCourse(
      gradeYear: _selectedCourse!.gradeYear,
      department: _selectedCourse!.department,
    );
    if (!mounted) return;
    setState(() {
      _courseLocations = locs;
      if (_selectedLocation == null || !locs.contains(_selectedLocation)) {
        _selectedLocation = locs.isNotEmpty ? locs.first : null;
      }
    });
  }

  void _adjustForCourseTeachingType() {
    if (_selectedCourse == null) return;
    if (_selectedCourse!.isTheoryOnly) {
      // Force lecture or theory type only (hide practical lab)
      if (_selectedSessionType == 'lab_practical') {
        _selectedSessionType = 'lecture';
      }
    }
  }

  Future<void> _launchSession() async {
    if (_selectedCourse == null) return;

    String chosenLocation;
    if (_selectedSessionType == 'lab_practical') {
      if (_courseLocations.isNotEmpty && (_selectedLocation == null || _selectedLocation!.isEmpty)) {
        _selectedLocation = _courseLocations.first;
      }
      if (_selectedLocation == null || _selectedLocation!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى اختيار المعمل المخصص للسكشن العملي من المعامل المأخوذة من الشيت'),
            backgroundColor: AppColors.warningYellow,
          ),
        );
        return;
      }
      chosenLocation = _selectedLocation!;
    } else {
      // lecture or lab_theory: manual text field
      final customLoc = _customLocationController.text.trim();
      chosenLocation = customLoc.isNotEmpty
          ? customLoc
          : (_selectedSessionType == 'lecture' ? 'مدرج عام' : 'قاعة دراسية');
    }

    setState(() => _isLaunching = true);

    try {
      await _appState.launchNewSession(
        course: _selectedCourse!,
        sessionType: _selectedSessionType,
        location: chosenLocation,
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
                        prefixIcon: Icon(Icons.book_rounded, color: AppColors.primaryBlue),
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
                        _updateLocationsForSelectedCourse();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 2: Session Type
                  _stepContainer(
                    stepNumber: 2,
                    title: 'تحديد نوع الجلسة',
                    subtitle: _selectedCourse?.isTheoryOnly == true
                        ? 'مقرر نظري فقط: تم حجب خيار المعامل الميدانية تلقائياً'
                        : 'اختر بين محاضرة عامة أو سكشن نظري أو سكشن عملي',
                    child: Column(
                      children: [
                        _typeTile(
                          id: 'lecture',
                          title: 'محاضرة',
                          subtitle: 'مدرج عام / قاعة لكامل الفرقة الدراسية',
                          icon: Icons.record_voice_over_rounded,
                        ),
                        const SizedBox(height: 10),
                        _typeTile(
                          id: 'lab_theory',
                          title: 'سكشن نظري',
                          subtitle: 'سكشن نظري / تمارين لمجموعة بالقاعة',
                          icon: Icons.assignment_rounded,
                        ),
                        if (_selectedCourse?.hasPractical ?? true) ...[
                          const SizedBox(height: 10),
                          _typeTile(
                            id: 'lab_practical',
                            title: 'سكشن عملي',
                            subtitle: 'مقيد بالمعمل المخصص وفلترة طلاب المعمل من الشيت',
                            icon: Icons.computer_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: Location Selection / Input
                  if (_selectedSessionType == 'lab_practical') ...[
                    // For practical lab: select from sheet labs
                    _stepContainer(
                      stepNumber: 3,
                      title: 'تحديد المعمل المخصص (سكشن عملي)',
                      subtitle: 'سيقيد النظام قبول المسح بطلاب هذا المعمل فقط المأخوذين من الشيت',
                      child: _courseLocations.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warningYellow.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warningYellow.withOpacity(0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppColors.warningYellow, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'تنبيه: لا توجد معامل مسجلة لطلاب هذا القسم/الفرقة في شيت الطلاب المستورد.',
                                      style: TextStyle(fontSize: 12, color: AppColors.warningYellow, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _courseLocations.contains(_selectedLocation)
                                  ? _selectedLocation
                                  : (_courseLocations.isNotEmpty ? _courseLocations.first : null),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.computer_rounded, color: AppColors.primaryBlue),
                                labelText: 'المعمل المعتمد من الشيت',
                              ),
                              hint: const Text('اختر المعمل من القائمة', style: TextStyle(fontSize: 13)),
                              items: _courseLocations.map((loc) {
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
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // For lecture or theory section: doctor types the location manually
                    _stepContainer(
                      stepNumber: 3,
                      title: _selectedSessionType == 'lecture' ? 'تحديد مكان المحاضرة (المدرج / القاعة)' : 'تحديد مكان السكشن النظري (القاعة)',
                      subtitle: 'اكتب اسم المدرج أو القاعة يدوياً لتثبيتها في تقرير الحضور',
                      child: TextFormField(
                        controller: _customLocationController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.meeting_room_rounded, color: AppColors.primaryBlue),
                          hintText: _selectedSessionType == 'lecture' ? 'اكتب اسم المدرج (مثال: مدرج 1 / مدرج الفردوس)' : 'اكتب اسم أو رقم القاعة (مثال: قاعة 204)',
                          labelText: 'مكان الانعقاد',
                        ),
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
                          color: AppColors.primaryBlue.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
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
        color: AppColors.surfaceWhite,
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
                  color: AppColors.primaryBlue,
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
          if (id == 'lab_practical') {
            if ((_selectedLocation == null || !_courseLocations.contains(_selectedLocation)) && _courseLocations.isNotEmpty) {
              _selectedLocation = _courseLocations.first;
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightBlue : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.surfaceCardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryBlue : AppColors.textMuted, size: 24),
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
                      color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
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
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
