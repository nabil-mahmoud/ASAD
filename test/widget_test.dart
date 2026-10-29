import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asad_app/core/theme/asad_emblem.dart';
import 'package:asad_app/domain/models/course.dart';
import 'package:asad_app/domain/models/student.dart';
import 'package:asad_app/domain/models/session.dart';
import 'package:asad_app/domain/models/attendance_record.dart';

void main() {
  test('ASAD Core Domain Models Verification', () {
    // 1. Course test
    const course = Course(
      courseId: 1,
      courseName: 'شبكات الحاسب',
      gradeYear: 'الفرقة الثانية',
      department: 'حاسبات',
      teachingType: 'theory_and_practical',
    );
    expect(course.isTheoryOnly, false);
    expect(course.hasPractical, true);
    expect(course.teachingTypeArabic, 'نظري + عملي');

    // 2. Student test
    const student = Student(
      academicId: '20261001',
      fullName: 'أحمد محمد إبراهيم',
      gradeYear: 'الفرقة الثانية',
      department: 'حاسبات',
      location: 'مدرج 1',
    );
    expect(student.academicId, '20261001');
    expect(student.location, 'مدرج 1');

    // 3. Session test
    const session = Session(
      sessionId: 10,
      courseId: 1,
      sessionType: 'lab_practical',
      location: 'معمل برمجة أ',
      createdAt: '2026-10-26T10:00:00',
      totalStudentsCount: 4,
      presentCount: 3,
    );
    expect(session.isLabPractical, true);
    expect(session.sessionTypeArabic, 'درس عملي - تطبيقي');
    expect(session.attendancePercentage, 75.0);

    // 4. Attendance Record test
    const record = AttendanceRecord(
      recordId: 100,
      sessionId: 10,
      academicId: '20261001',
      status: 'present',
      score: 1,
      studentName: 'أحمد محمد إبراهيم',
    );
    expect(record.isPresent, true);
    expect(record.score, 1);
    expect(record.statusArabic, 'حاضر');
  });

  testWidgets('ASAD Emblem renders correctly with official branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AsadEmblem(size: 150),
          ),
        ),
      ),
    );

    expect(find.byType(AsadEmblem), findsOneWidget);
    expect(find.text('ASAD'), findsOneWidget);
    expect(find.text('منظومة الحضور الأكاديمي الذكي'), findsOneWidget);
  });
}
