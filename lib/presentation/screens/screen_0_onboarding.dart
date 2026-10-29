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
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final current = AppState().doctorProfile?.doctorName;
    if (current != null) {
      _nameController.text = current;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await AppState().saveDoctorName(_nameController.text.trim());

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات القائم بالتدريس بنجاح'),
          backgroundColor: AppColors.emerald,
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
                    // Official ASAD Emblem
                    const Hero(
                      tag: 'asad_emblem',
                      child: AsadEmblem(size: 150),
                    ),
                    const SizedBox(height: 32),

                    // Title & Description
                    Text(
                      widget.isEditing ? 'تعديل بيانات القائم بالتدريس' : 'مرحباً بك في منظومة ASAD',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نظام تسجيل الحضور والغياب الذكي بدون إنترنت (100% Offline)\nتُحفظ البيانات محلياً وتُدرج الترويسة الأكاديمية تلقائياً في كافة الكشوفات.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceCardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ما اسم حضرتك الكريم؟',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mintAccent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'يُطلب لمرة واحدة فقط ويظهر في ترويسة ملفات الإكسيل والـ PDF المعتمدة.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'مثال: د. أحمد الشناوي',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.emerald),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'يرجى إدخال اسم الدكتور أو القائم بالتدريس';
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
