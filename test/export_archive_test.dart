import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asad_app/core/utils/excel_pdf_exporter.dart';
import 'package:asad_app/domain/models/attendance_record.dart';
import 'package:asad_app/domain/models/course.dart';
import 'package:asad_app/domain/models/session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session Finalization, Archive, and Excel/PDF Export Tests', () {
    final sampleCourse = const Course(
      courseId: 101,
      courseName: 'هندسة البرمجيات',
      gradeYear: 'الفرقة الثالثة',
      department: 'حاسبات ومعلومات',
      teachingType: 'theory_and_practical',
    );

    final sampleSession = Session(
      sessionId: 42,
      courseId: 101,
      courseName: 'هندسة البرمجيات',
      sessionType: 'theory',
      location: 'مدرج د. أسامة خليل',
      createdAt: '2026-10-31T09:00:00.000',
      totalStudentsCount: 4,
      presentCount: 2,
    );

    final sampleRecords = [
      const AttendanceRecord(
        recordId: 1,
        sessionId: 42,
        academicId: '20260001',
        studentName: 'أحمد محمد علي',
        studentLocation: 'مدرج د. أسامة خليل',
        status: 'present',
        score: 1,
        scanTimestamp: '2026-10-31T09:05:12.000',
        notes: null,
      ),
      const AttendanceRecord(
        recordId: 2,
        sessionId: 42,
        academicId: '20260002',
        studentName: 'سارة إبراهيم حسن',
        studentLocation: 'مدرج د. أسامة خليل',
        status: 'absent',
        score: 0,
        scanTimestamp: null,
        notes: null,
      ),
      const AttendanceRecord(
        recordId: 3,
        sessionId: 42,
        academicId: '20260003',
        studentName: 'محمود خالد عبد الله',
        studentLocation: 'مدرج د. أسامة خليل',
        status: 'excused',
        score: 1,
        scanTimestamp: '2026-10-31T09:12:00.000',
        notes: 'عذر مرضي معتمد',
      ),
      const AttendanceRecord(
        recordId: 4,
        sessionId: 42,
        academicId: '20260004',
        studentName: 'ياسين طارق الشريف',
        studentLocation: 'مدرج د. أسامة خليل',
        status: 'absent',
        score: 0,
        scanTimestamp: null,
        notes: null,
      ),
    ];

    test('1. Excel Sheet is created with Arabic RTL orientation and correct title', () {
      final excel = ExcelPdfExporter.buildSessionExcel(
        session: sampleSession,
        course: sampleCourse,
        doctorName: 'أ.د. نبيل محمود',
        records: sampleRecords,
      );

      final sheet = excel['كشف الحضور والغياب'];
      expect(sheet, isNotNull);
      expect(sheet.isRTL, isTrue);

      // Row 1 (Index 0): Title Banner
      final titleCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
      expect(titleCell.value?.toString(), contains('كشف حضور وغياب الطلاب'));
    });

    test('2. Excel Header Block contains all official university fields', () {
      final excel = ExcelPdfExporter.buildSessionExcel(
        session: sampleSession,
        course: sampleCourse,
        doctorName: 'أ.د. نبيل محمود',
        records: sampleRecords,
      );

      final sheet = excel['كشف الحضور والغياب'];

      // Row 2 (Index 1): Course Metadata
      final courseMetaCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
      final courseMetaText = courseMetaCell.value?.toString() ?? '';
      expect(courseMetaText, contains('هندسة البرمجيات'));
      expect(courseMetaText, contains('الفرقة الثالثة'));
      expect(courseMetaText, contains('حاسبات ومعلومات'));
      expect(courseMetaText, contains('محاضرة نظري'));
      expect(courseMetaText, contains('مدرج د. أسامة خليل'));

      // Row 3 (Index 2): Doctor and Attendance Statistics
      final doctorStatsCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2));
      final doctorStatsText = doctorStatsCell.value?.toString() ?? '';
      expect(doctorStatsText, contains('أ.د. نبيل محمود'));
      expect(doctorStatsText, contains('إجمالي المقيدين (4)'));
      expect(doctorStatsText, contains('الحاضرين (2)'));
      expect(doctorStatsText, contains('الغائبين (2)'));
      expect(doctorStatsText, contains('%50.0'));
    });

    test('3. Excel Data Table contains strictly 8 columns matching specifications', () {
      final excel = ExcelPdfExporter.buildSessionExcel(
        session: sampleSession,
        course: sampleCourse,
        doctorName: 'أ.د. نبيل محمود',
        records: sampleRecords,
      );

      final sheet = excel['كشف الحضور والغياب'];

      // Row 4 (Index 3): Table Column Headers
      final expectedHeaders = [
        'م',
        'الكود الجامعي',
        'اسم الطالب',
        'المكان',
        'الحالة (حاضر / غائب / عذر)',
        'الدرجة / الرصد',
        'وقت المسح',
        'ملاحظات',
      ];

      for (int c = 0; c < expectedHeaders.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
        expect(cell.value?.toString(), expectedHeaders[c]);
      }
    });

    test('4. Score column is strictly 1 for present/excused and 0 for absent', () {
      final excel = ExcelPdfExporter.buildSessionExcel(
        session: sampleSession,
        course: sampleCourse,
        doctorName: 'أ.د. نبيل محمود',
        records: sampleRecords,
      );

      final sheet = excel['كشف الحضور والغياب'];

      // Row 5 (index 4): Student 1 (present -> score 1)
      final s1Score = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 4));
      expect(s1Score.value, const IntCellValue(1));

      // Row 6 (index 5): Student 2 (absent -> score 0)
      final s2Score = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 5));
      expect(s2Score.value, const IntCellValue(0));

      // Row 7 (index 6): Student 3 (excused -> score 1)
      final s3Score = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 6));
      expect(s3Score.value, const IntCellValue(1));

      // Row 8 (index 7): Student 4 (absent -> score 0)
      final s4Score = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 7));
      expect(s4Score.value, const IntCellValue(0));
    });

    test('5. Summary Row contains automated =SUM(...) formula spanning the score column', () {
      final excel = ExcelPdfExporter.buildSessionExcel(
        session: sampleSession,
        course: sampleCourse,
        doctorName: 'أ.د. نبيل محمود',
        records: sampleRecords,
      );

      final sheet = excel['كشف الحضور والغياب'];

      // Summary row is at index 4 + 4 = 8 (Row 9 in 1-based indexing)
      final summaryRowIdx = 8;
      final sumLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRowIdx));
      expect(sumLabel.value?.toString(), contains('إجمالي درجات الحضور للجلسة (معادلة SUM التلقائية):'));

      // Formula cell in Column F (columnIndex 5)
      final formulaCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryRowIdx));
      expect(formulaCell.value, isA<FormulaCellValue>());
      // First student is on Excel row 5, last student on Excel row 8
      expect((formulaCell.value as FormulaCellValue).formula, 'SUM(F5:F8)');

      // Count and percentage summary cells
      final countCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: summaryRowIdx));
      expect(countCell.value?.toString(), '[2]');

      final pctCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: summaryRowIdx));
      expect(pctCell.value?.toString(), '%50.0');
    });

    test('6. Session finalization marks unrecorded students as absent with score = 0', () {
      // Simulate finalization logic
      final pendingRecords = [
        {'id': '101', 'status': 'present', 'score': 1},
        {'id': '102', 'status': 'absent', 'score': 0},
        {'id': '103', 'status': '', 'score': 0},       // Unrecorded
        {'id': '104', 'status': null, 'score': 0},     // Unrecorded
      ];

      // Finalization step
      final finalized = pendingRecords.map((r) {
        final status = r['status'];
        if (status != 'present' && status != 'excused') {
          return {'id': r['id'], 'status': 'absent', 'score': 0};
        }
        return r;
      }).toList();

      for (final rec in finalized) {
        if (rec['id'] == '101') {
          expect(rec['status'], 'present');
          expect(rec['score'], 1);
        } else {
          expect(rec['status'], 'absent');
          expect(rec['score'], 0);
        }
      }
    });

    test('7. Archive Session Model computations and formatting are consistent', () {
      final s = Session(
        sessionId: 99,
        courseId: 2,
        courseName: 'قواعد البيانات',
        sessionType: 'practical',
        location: 'معمل د',
        createdAt: '2026-10-31T11:00:00',
        totalStudentsCount: 50,
        presentCount: 45,
      );

      expect(s.sessionTypeArabic, 'درس عملي');
      expect(s.totalStudentsCount, 50);
      expect(s.presentCount, 45);
      expect(s.toMap()['session_type'], 'practical');
      expect(s.toMap()['location'], 'معمل د');
    });
  });
}
