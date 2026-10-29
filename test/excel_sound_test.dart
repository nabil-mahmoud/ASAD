import 'package:flutter_test/flutter_test.dart';
import 'package:asad_app/core/sound/sound_service.dart';
import 'package:asad_app/domain/models/student.dart';
import 'package:asad_app/domain/models/course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SoundService initializes and synthesizes offline WAV tones', () async {
    final sound = SoundService();
    await sound.init();
    expect(() => sound.playSuccessBeep(), returnsNormally);
    expect(() => sound.playDuplicateAlert(), returnsNormally);
    expect(() => sound.playWrongLocationBuzz(), returnsNormally);
    expect(() => sound.playManualConfirmClick(), returnsNormally);
  });

  test('Student model serialization and location index compliance', () {
    const student = Student(
      academicId: '20261004',
      fullName: 'كريم عادل فهمي',
      gradeYear: 'الفرقة الثانية',
      department: 'حاسبات',
      location: 'معمل برمجة أ',
    );

    final map = student.toMap();
    expect(map['academic_id'], '20261004');
    expect(map['location'], 'معمل برمجة أ');

    final revived = Student.fromMap(map);
    expect(revived.academicId, student.academicId);
    expect(revived.fullName, student.fullName);
    expect(revived.location, student.location);
  });

  test('Course model dynamic properties compliance', () {
    const course = Course(
      courseId: 5,
      courseName: 'نظم تشغيل',
      gradeYear: 'الفرقة الثالثة',
      department: 'علوم حاسب',
      teachingType: 'theory_only',
    );

    expect(course.isTheoryOnly, isTrue);
    expect(course.hasPractical, isFalse);
    expect(course.teachingTypeArabic, 'نظري فقط');
  });
}
