import 'package:flutter_test/flutter_test.dart';
import 'package:asad_app/domain/models/student.dart';
import 'package:asad_app/domain/models/session.dart';
import 'package:asad_app/domain/models/course.dart';
import 'package:asad_app/domain/models/cumulative_student_report.dart';
import 'package:asad_app/core/utils/excel_pdf_exporter.dart';

void main() {
  group('Cumulative Student Report Logic Tests', () {
    final sampleStudent = Student(
      academicId: '2026101',
      fullName: 'أحمد محمود إبراهيم',
      location: 'مدرج 1',
      gradeYear: 'الفرقة الثالثة',
      department: 'نظم معلومات',
    );

    test('Computes attendance percentage and regular status correctly', () {
      final report = CumulativeStudentReport.fromAggregation(
        student: sampleStudent,
        totalCourseSessions: 10,
        records: [
          for (int i = 1; i <= 9; i++) {'session_id': i, 'status': 'present', 'score': 1},
          {'session_id': 10, 'status': 'absent', 'score': 0},
        ],
      );

      expect(report.attendancePercentage, equals(90.0));
      expect(report.attendedSessions, equals(9));
      expect(report.absentSessions, equals(1));
      expect(report.isAtRisk, isFalse);
      expect(report.isDeprived, isFalse);
      expect(report.statusTag, equals('ممتاز'));
    });

    test('Flags warning status when attendance falls below 75%', () {
      final report = CumulativeStudentReport.fromAggregation(
        student: sampleStudent,
        totalCourseSessions: 10,
        records: [
          for (int i = 1; i <= 7; i++) {'session_id': i, 'status': 'present', 'score': 1},
          for (int i = 8; i <= 10; i++) {'session_id': i, 'status': 'absent', 'score': 0},
        ],
      );

      expect(report.attendancePercentage, equals(70.0));
      expect(report.attendedSessions, equals(7));
      expect(report.absentSessions, equals(3));
      expect(report.isAtRisk, isTrue);
      expect(report.isDeprived, isFalse);
      expect(report.statusTag, equals('منذر بالحرمان'));
    });

    test('Flags deprived status when attendance falls below 50%', () {
      final report = CumulativeStudentReport.fromAggregation(
        student: sampleStudent,
        totalCourseSessions: 10,
        records: [
          for (int i = 1; i <= 4; i++) {'session_id': i, 'status': 'present', 'score': 1},
          for (int i = 5; i <= 10; i++) {'session_id': i, 'status': 'absent', 'score': 0},
        ],
      );

      expect(report.attendancePercentage, equals(40.0));
      expect(report.isAtRisk, isTrue);
      expect(report.isDeprived, isTrue);
      expect(report.statusTag, equals('محروم'));
    });
  });

  group('Cumulative Excel Workbook Generation Tests', () {
    test('Builds Excel with dynamic session columns and SUM formulas', () {
      final course = Course(
        courseId: 1,
        courseName: 'هياكل البيانات',
        gradeYear: 'الفرقة الثالثة',
        department: 'نظم معلومات',
        teachingType: 'theory_only',
      );

      final List<Session> sessions = [
        Session(
          sessionId: 101,
          courseId: 1,
          sessionType: 'lecture',
          location: 'مدرج 1',
          createdAt: DateTime.now().toIso8601String(),
        ),
        Session(
          sessionId: 102,
          courseId: 1,
          sessionType: 'lecture',
          location: 'مدرج 1',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      final student = Student(
        academicId: '2026101',
        fullName: 'نبيل الشاعر',
        location: 'مدرج 1',
        gradeYear: 'الفرقة الثالثة',
        department: 'نظم معلومات',
      );

      final report = CumulativeStudentReport(
        academicId: student.academicId,
        fullName: student.fullName,
        location: student.location,
        gradeYear: student.gradeYear,
        department: student.department,
        totalCourseSessions: 2,
        attendedSessions: 2,
        absentSessions: 0,
        excusedSessions: 0,
        totalScore: 2,
        attendancePercentage: 100.0,
        sessionScores: {101: 1, 102: 1},
        sessionStatuses: {101: 'present', 102: 'present'},
      );

      final excel = ExcelPdfExporter.buildCumulativeExcel(
        course: course,
        sessions: sessions,
        reports: [report],
        doctorName: 'أ.د. نبيل محمود',
      );

      expect(excel.sheets.isNotEmpty, isTrue);
      final sheet = excel.sheets['سجل الرصد التراكمي'];
      expect(sheet, isNotNull);
      expect(sheet!.isRTL, isTrue);
    });
  });
}
