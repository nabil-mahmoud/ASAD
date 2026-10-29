import 'package:flutter_test/flutter_test.dart';
import 'package:asad_app/core/sound/sound_service.dart';
import 'package:asad_app/core/utils/excel_pdf_exporter.dart';
import 'package:asad_app/domain/models/student.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SoundService initializes and synthesizes offline WAV tones', () async {
    final sound = SoundService();
    await sound.init();
    // Verify playing triggers without uncaught exception
    expect(() => sound.playSuccessBeep(), returnsNormally);
    expect(() => sound.playDuplicateAlert(), returnsNormally);
    expect(() => sound.playWrongLocationBuzz(), returnsNormally);
    expect(() => sound.playManualConfirmClick(), returnsNormally);
  });

  test('Excel Template generation and Approved Demo Students test', () async {
    final demoStudents = ExcelPdfExporter.getApprovedDemoStudents();
    expect(demoStudents.length, greaterThanOrEqualTo(8));
    expect(demoStudents.any((s) => s.fullName.contains('أحمد محمد إبراهيم')), isTrue);
    expect(demoStudents.any((s) => s.location == 'معمل برمجة أ'), isTrue);
    expect(demoStudents.any((s) => s.location == 'معمل شبكات ب'), isTrue);
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
}
