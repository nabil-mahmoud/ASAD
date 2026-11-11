import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/asad_emblem.dart';
import '../controllers/app_state.dart';
import 'screen_1_dashboard.dart';

class Screen0Onboarding extends StatefulWidget {
  final bool isEditing;

  const Screen0Onboarding({
    super.key,
    this.isEditing = false,
  });

  @override
  State<Screen0Onboarding> createState() => _Screen0OnboardingState();
}

class _Screen0OnboardingState extends State<Screen0Onboarding> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = AppState().doctorProfile;
    if (profile?.doctorName != null) {
      _nameController.text = profile!.doctorName;
    }
    if (profile?.facultyName != null) {
      _facultyController.text = profile!.facultyName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await AppState().saveDoctorProfile(
      name: _nameController.text.trim(),
      facultyName: _facultyController.text.trim(),
    );

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات الأكاديمية بنجاح'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Screen1Dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Official DMU Emblem
                    const Hero(
                      tag: 'asad_emblem',
                      child: AsadEmblem(size: 130),
                    ),
                    const SizedBox(height: 28),

                    // Title & Description
                    Text(
                      widget.isEditing ? 'تعديل البيانات الأكاديمية' : 'مرحباً بك في منظومة DMU',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'نظام تسجيل الحضور الذكي بجامعة دمنهور\nتُدرج الترويسة الأكاديمية المعتمدة تلقائياً في كافة الكشوفات والتقارير.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceCardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D47A1).withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بيانات عضو هيئة التدريس والكلية',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'تظهر هذه البيانات رسمياً في ترويسة ملفات الإكسيل والـ PDF الصادرة.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Doctor Name
                          const Text(
                            'اسم الدكتور / القائم بالتدريس:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'مثال: أ.د. أحمد الشناوي',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primaryBlue),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'يرجى إدخال اسم الدكتور أو القائم بالتدريس';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // College / Faculty Name
                          const Text(
                            'الكلية التابع لها بجامعة دمنهور:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _facultyController,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'مثال: كلية العلوم / كلية الزراعة / كلية التربية',
                              prefixIcon: Icon(Icons.school_outlined, color: AppColors.primaryBlue),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'يرجى إدخال اسم الكلية';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          widget.isEditing ? 'حفظ التعديلات' : 'بدء الاستخدام والدخول للمنظومة',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
