import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/course.dart';
import '../controllers/app_state.dart';

class Screen2Courses extends StatefulWidget {
  const Screen2Courses({super.key});

  @override
  State<Screen2Courses> createState() => _Screen2CoursesState();
}

class _Screen2CoursesState extends State<Screen2Courses> {
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

  void _showAddEditCourseModal({Course? existingCourse}) {
    final nameCtrl = TextEditingController(text: existingCourse?.courseName ?? '');
    String selectedGrade = existingCourse?.gradeYear ?? 'الفرقة الثانية';
    String selectedDept = existingCourse?.department ?? 'حاسبات';
    String selectedType = existingCourse?.teachingType ?? 'theory_and_practical';

    final grades = ['الفرقة الأولى', 'الفرقة الثانية', 'الفرقة الثالثة', 'الفرقة الرابعة', 'دراسات عليا'];
    final depts = ['حاسبات', 'نظم معلومات', 'علوم حاسب', 'تكنولوجيا المعلومات', 'عام'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingCourse == null ? 'إضافة مقرر دراسي جديد' : 'تعديل بيانات المقرر',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // اسم المقرر
                    const Text('اسم المقرر الدراسي', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.mintAccent)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: 'مثال: شبكات الحاسب، ذكاء اصطناعي، قواعد بيانات',
                        prefixIcon: Icon(Icons.book_outlined, color: AppColors.emerald),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // الفرقة والقسم
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الفرقة الدراسية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.mintAccent)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedGrade,
                                isExpanded: true,
                                decoration: const InputDecoration(),
                                items: grades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setModalState(() => selectedGrade = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('القسم العلمي', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.mintAccent)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedDept,
                                isExpanded: true,
                                decoration: const InputDecoration(),
                                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setModalState(() => selectedDept = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // طبيعة التدريس (نظري فقط / نظري + عملي)
                    const Text('طبيعة التدريس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.mintAccent)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceCardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _typeOption(
                              title: 'نظري + عملي',
                              subtitle: 'محاضرات وسكاشن ومعامل',
                              isSelected: selectedType == 'theory_and_practical',
                              onTap: () => setModalState(() => selectedType = 'theory_and_practical'),
                            ),
                          ),
                          Expanded(
                            child: _typeOption(
                              title: 'نظري فقط',
                              subtitle: 'محاضرات فقط بدون معامل',
                              isSelected: selectedType == 'theory_only',
                              onTap: () => setModalState(() => selectedType = 'theory_only'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedType == 'theory_only')
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningYellow.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warningYellow.withOpacity(0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColors.warningYellow),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'القاعدة الذكية: سيتم حجب خيارات المعامل والسكاشن تلقائياً عند فتح الجلسة منعاً للأخطاء.',
                                style: TextStyle(fontSize: 11, color: AppColors.warningYellow),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;

                        if (existingCourse == null) {
                          await _appState.addCourse(Course(
                            courseName: name,
                            gradeYear: selectedGrade,
                            department: selectedDept,
                            teachingType: selectedType,
                          ));
                        } else {
                          await _appState.updateCourse(existingCourse.copyWith(
                            courseName: name,
                            gradeYear: selectedGrade,
                            department: selectedDept,
                            teachingType: selectedType,
                          ));
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(existingCourse == null ? 'حفظ وإضافة المقرر' : 'تحديث المقرر'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _typeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : AppColors.textDim,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _appState.courses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المقررات الدراسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.mintAccent),
            tooltip: 'إضافة مقرر',
            onPressed: () => _showAddEditCourseModal(),
          ),
        ],
      ),
      body: courses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.library_books_outlined, size: 64, color: AppColors.textDim),
                    const SizedBox(height: 16),
                    const Text(
                      'لم يتم إضافة أي مقررات بعد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أضف مقرراتك الدراسية يدوياً لتبدأ تسجيل الحضور والغياب للطلاب فوراً.',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditCourseModal(),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة مقرر جديد الآن'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Populate quick demo courses
                        await _appState.addCourse(const Course(
                          courseName: 'شبكات الحاسب',
                          gradeYear: 'الفرقة الثانية',
                          department: 'حاسبات',
                          teachingType: 'theory_and_practical',
                        ));
                        await _appState.addCourse(const Course(
                          courseName: 'هندسة البرمجيات',
                          gradeYear: 'الفرقة الثانية',
                          department: 'حاسبات',
                          teachingType: 'theory_and_practical',
                        ));
                        await _appState.addCourse(const Course(
                          courseName: 'أخلاقيات المهنة',
                          gradeYear: 'الفرقة الثانية',
                          department: 'عام',
                          teachingType: 'theory_only',
                        ));
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('إضافة مقررات نموذجية للتجربة'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = courses[index];
                return Container(
                  padding: const EdgeInsets.all(16),
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
                          color: AppColors.emerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          course.isTheoryOnly ? Icons.menu_book_rounded : Icons.science_rounded,
                          color: AppColors.mintAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${course.gradeYear} • قسم ${course.department}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: course.isTheoryOnly ? AppColors.royalDark : AppColors.emerald.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                course.teachingTypeArabic,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mintAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textMuted),
                        onPressed: () => _showAddEditCourseModal(existingCourse: course),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.dangerRed),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: AppColors.surfaceDark,
                              title: const Text('حذف المقرر'),
                              content: Text('هل أنت متأكد من حذف مقرر "${course.courseName}" وكافة جلساته؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _appState.deleteCourse(course.courseId!);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: courses.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.emerald,
              onPressed: () => _showAddEditCourseModal(),
              icon: const Icon(Icons.add),
              label: const Text('إضافة مقرر جديد'),
            )
          : null,
    );
  }
}
