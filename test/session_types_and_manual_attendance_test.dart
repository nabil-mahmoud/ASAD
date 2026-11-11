import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asad_app/domain/models/session.dart';
import 'package:asad_app/domain/models/course.dart';
import 'package:asad_app/domain/models/attendance_record.dart';

void main() {
  testWidgets('Session model provides correct Arabic labels for all session types', (tester) async {
    const lectureSession = Session(
      sessionId: 1,
      courseId: 10,
      sessionType: 'lecture',
      createdAt: '2026-11-11T10:00:00Z',
    );
    expect(lectureSession.sessionTypeArabic, 'محاضرة');

    const labTheorySession = Session(
      sessionId: 2,
      courseId: 10,
      sessionType: 'lab_theory',
      createdAt: '2026-11-11T10:00:00Z',
    );
    expect(labTheorySession.sessionTypeArabic, 'سكشن نظري');

    const labPracticalSession = Session(
      sessionId: 3,
      courseId: 10,
      sessionType: 'lab_practical',
      createdAt: '2026-11-11T10:00:00Z',
    );
    expect(labPracticalSession.sessionTypeArabic, 'سكشن عملي');
  });

  testWidgets('AttendanceRecord model correctly handles status and scores', (tester) async {
    const presentRecord = AttendanceRecord(
      recordId: 1,
      sessionId: 1,
      academicId: '2026001',
      status: 'present',
      score: 1,
      studentName: 'أحمد محمود',
    );
    expect(presentRecord.statusArabic, 'حاضر');
    expect(presentRecord.isPresent, true);
    expect(presentRecord.score, 1);

    const excusedRecord = AttendanceRecord(
      recordId: 2,
      sessionId: 1,
      academicId: '2026002',
      status: 'excused',
      score: 1,
      studentName: 'محمد علي',
      notes: 'عذر مرضي معتمد',
    );
    expect(excusedRecord.statusArabic, 'حاضر (عذر)');
    expect(excusedRecord.isExcused, true);
    expect(excusedRecord.score, 1);
    expect(excusedRecord.notes, 'عذر مرضي معتمد');

    const absentRecord = AttendanceRecord(
      recordId: 3,
      sessionId: 1,
      academicId: '2026003',
      status: 'absent',
      score: 0,
      studentName: 'محمود حسن',
    );
    expect(absentRecord.statusArabic, 'غائب');
    expect(absentRecord.isAbsent, true);
    expect(absentRecord.score, 0);
  });
}
