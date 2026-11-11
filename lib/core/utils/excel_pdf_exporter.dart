import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models/attendance_record.dart';
import '../../domain/models/course.dart';
import '../../domain/models/session.dart';
import '../../domain/models/student.dart';
import '../../domain/models/cumulative_student_report.dart';

class ExcelPdfExporter {
  /// Builds in-memory Excel object conforming strictly to official ASAD specifications
  static Excel buildSessionExcel({
    required Session session,
    required Course? course,
    required String doctorName,
    required List<AttendanceRecord> records,
  }) {
    final excel = Excel.createExcel();
    final String sheetName = 'كشف الحضور والغياب';
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    final Sheet sheet = excel[sheetName];

    // RTL orientation for Arabic university sheet
    sheet.isRTL = true;

    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final timeStr = intl.DateFormat('hh:mm a').format(now);

    final totalStudents = records.length;
    final presentCount = records.where((r) => r.score > 0).length;
    final absentCount = totalStudents - presentCount;
    final percent = totalStudents > 0 ? ((presentCount / totalStudents) * 100).toStringAsFixed(1) : '0';

    // Cell Styles
    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: ExcelColor.fromHexString('#064E3B'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle metaStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#E6F4EA'),
      fontColorHex: ExcelColor.fromHexString('#064E3B'),
      horizontalAlign: HorizontalAlign.Right,
    );

    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#059669'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle presentRowStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#F0FDF4'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final CellStyle absentRowStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FEF2F2'),
      fontColorHex: ExcelColor.fromHexString('#991B1B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final CellStyle sumRowStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#D1FAE5'),
      fontColorHex: ExcelColor.fromHexString('#064E3B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Row 1: Header Block - Title (كشف حضور وغياب الطلاب)
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('كشف حضور وغياب الطلاب - جامعة دمنهور (DMU)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
    );

    // Row 2: Course & Session Details
    final courseName = course?.courseName ?? session.courseName ?? 'المقرر';
    final gradeYear = course?.gradeYear ?? 'الفرقة الدراسية';
    final dept = course?.department ?? 'عام';
    final sessionType = session.sessionTypeArabic;
    final loc = session.location ?? 'الكل';

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('المقرر: $courseName | الفرقة: $gradeYear | القسم العلمي: $dept | نوع الجلسة: $sessionType | المكان: $loc');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = metaStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1),
    );

    // Row 3: Teacher, Date/Time & Attendance Statistics
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('التاريخ والوقت: $dateStr ($timeStr) | القائم بالتدريس: $doctorName | إحصائية: إجمالي المقيدين ($totalStudents) - الحاضرين ($presentCount) - الغائبين ($absentCount) | نسبة الحضور: %$percent');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = metaStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 2),
    );

    // Row 4 (index 3): Table Headers (Strictly 8 Columns)
    final headers = [
      'م',
      'الكود الجامعي',
      'اسم الطالب',
      'المكان',
      'الحالة (حاضر / غائب / عذر)',
      'الدرجة / الرصد',
      'وقت المسح',
      'ملاحظات',
    ];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Rows 5..N: Students Attendance Records
    int currentRow = 4;
    for (int i = 0; i < records.length; i++) {
      final rec = records[i];
      final isPresentOrExcused = rec.score > 0;
      final style = isPresentOrExcused ? presentRowStyle : absentRowStyle;

      // Col 0: م
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
        ..value = IntCellValue(i + 1)
        ..cellStyle = style;

      // Col 1: الكود الجامعي
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
        ..value = TextCellValue(rec.academicId)
        ..cellStyle = style;

      // Col 2: اسم الطالب
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
        ..value = TextCellValue(rec.studentName ?? 'طالب')
        ..cellStyle = style;

      // Col 3: المكان
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
        ..value = TextCellValue(rec.studentLocation ?? loc)
        ..cellStyle = style;

      // Col 4: الحالة (حاضر / غائب / عذر)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        ..value = TextCellValue(rec.statusArabic)
        ..cellStyle = style;

      // Col 5: الدرجة / الرصد (Strictly 1 for present/excused, 0 for absent)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        ..value = IntCellValue(rec.score > 0 ? 1 : 0)
        ..cellStyle = style;

      // Col 6: وقت المسح
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
        ..value = TextCellValue(_formatScanTime(rec.scanTimestamp))
        ..cellStyle = style;

      // Col 7: ملاحظات
      final note = rec.notes ?? (rec.score > 0 ? (rec.status == 'excused' ? 'عذر مقبول' : 'تم الرصد') : 'غائب');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow))
        ..value = TextCellValue(note)
        ..cellStyle = style;

      currentRow++;
    }

    // Row N+1: SUM Formula Row (الصف الإجمالي بمعادلة SUM التلقائية)
    final startExcelRow = 5; // 1-indexed in Excel (Row 5 is first student data row)
    final endExcelRow = currentRow > 4 ? currentRow : 5; // last student row

    final sumLabelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
    sumLabelCell.value = TextCellValue('إجمالي درجات الحضور للجلسة (معادلة SUM التلقائية):');
    sumLabelCell.cellStyle = sumRowStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
    );

    final sumFormulaCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow));
    sumFormulaCell.value = FormulaCellValue('SUM(F$startExcelRow:F$endExcelRow)');
    sumFormulaCell.cellStyle = sumRowStyle;

    final sumCountCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
    sumCountCell.value = TextCellValue('[$presentCount]');
    sumCountCell.cellStyle = sumRowStyle;

    final sumPctCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow));
    sumPctCell.value = TextCellValue('%$percent');
    sumPctCell.cellStyle = sumRowStyle;

    // Set Column Widths for clean viewing
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 30);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 22);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 18);
    sheet.setColumnWidth(7, 20);

    return excel;
  }

  /// Generate and export Excel sheet (.xlsx) exactly matching ASAD specifications
  static Future<File> exportSessionExcel({
    required Session session,
    required Course? course,
    required String doctorName,
    required List<AttendanceRecord> records,
  }) async {
    final excel = buildSessionExcel(
      session: session,
      course: course,
      doctorName: doctorName,
      records: records,
    );

    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final cleanCourse = (course?.courseName ?? 'مقرر').replaceAll(' ', '_');
    final cleanLoc = (session.location ?? 'قاعة').replaceAll(' ', '_');
    final fileName = 'كشف_حضور_${cleanCourse}_${cleanLoc}_$dateStr.xlsx';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file;
  }

  /// Generate and export Official PDF Report with Arabic typography and ASAD branding
  static Future<File> exportSessionPdf({
    required Session session,
    required Course? course,
    required String doctorName,
    required List<AttendanceRecord> records,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final timeStr = intl.DateFormat('hh:mm a').format(now);

    final totalStudents = records.length;
    final presentCount = records.where((r) => r.score > 0).length;
    final absentCount = totalStudents - presentCount;
    final percent = totalStudents > 0 ? ((presentCount / totalStudents) * 100).toStringAsFixed(1) : '0';

    final courseName = course?.courseName ?? session.courseName ?? 'المقرر';
    final gradeYear = course?.gradeYear ?? 'الفرقة الدراسية';
    final dept = course?.department ?? 'عام';
    final loc = session.location ?? 'الكل';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        margin: const pw.EdgeInsets.all(24),
        header: (context) {
          return pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('0D47A1'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'جمهورية مصر العربية - وزارة التعليم العالي',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white),
                        ),
                        pw.Text(
                          'جامعة دمنهور - Damanhour University',
                          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.white),
                        ),
                        pw.Text(
                          'العام الجامعي: 2026/2027',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('DBEAFE')),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'DMU',
                          style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.white),
                        ),
                        pw.Text(
                          'نظام تسجيل الحضور والغياب الذكي',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('DBEAFE')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              // Session Meta Information Box
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F0FDF4'),
                  border: pw.Border.all(color: PdfColor.fromHex('059669'), width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المقرر: $courseName ($gradeYear - $dept)', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    pw.Text('نوع الجلسة: ${session.sessionTypeArabic}', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text('المكان: $loc', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    pw.Text('التاريخ: $dateStr ($timeStr)', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('القائم بالتدريس: $doctorName', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('064E3B'))),
                  pw.Text('إحصائيات: حاضر ($presentCount) | غائب ($absentCount) | نسبة الحضور: %$percent', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('059669'))),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('توقيع القائم بالتدريس: ____________________', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('اعتماد شؤون الطلاب: ____________________', style: pw.TextStyle(font: font, fontSize: 9)),
              ],
            ),
          );
        },
        build: (context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('CBD5E1'), width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),  // م
                1: const pw.FixedColumnWidth(55),  // الكود الجامعي
                2: const pw.FlexColumnWidth(2.3),  // اسم الطالب
                3: const pw.FlexColumnWidth(1.2),  // المكان
                4: const pw.FixedColumnWidth(52),  // الحالة
                5: const pw.FixedColumnWidth(30),  // الدرجة
                6: const pw.FixedColumnWidth(48),  // وقت المسح
                7: const pw.FlexColumnWidth(1.1),  // ملاحظات
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('059669')),
                  children: [
                    _pdfCell('م', fontBold, isHeader: true),
                    _pdfCell('الكود الجامعي', fontBold, isHeader: true),
                    _pdfCell('اسم الطالب بالكامل', fontBold, isHeader: true),
                    _pdfCell('المكان', fontBold, isHeader: true),
                    _pdfCell('الحالة', fontBold, isHeader: true),
                    _pdfCell('الدرجة', fontBold, isHeader: true),
                    _pdfCell('وقت المسح', fontBold, isHeader: true),
                    _pdfCell('ملاحظات', fontBold, isHeader: true),
                  ],
                ),
                // Data Rows
                for (int i = 0; i < records.length; i++) ...[
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: records[i].score > 0
                          ? (i % 2 == 0 ? PdfColor.fromHex('F0FDF4') : PdfColors.white)
                          : PdfColor.fromHex('FEF2F2'),
                    ),
                    children: [
                      _pdfCell('${i + 1}', font),
                      _pdfCell(records[i].academicId, fontBold),
                      _pdfCell(records[i].studentName ?? 'طالب', font),
                      _pdfCell(records[i].studentLocation ?? loc, font),
                      _pdfCell(
                        records[i].statusArabic,
                        fontBold,
                        color: records[i].score > 0 ? PdfColor.fromHex('059669') : PdfColor.fromHex('DC2626'),
                      ),
                      _pdfCell('${records[i].score > 0 ? 1 : 0}', fontBold),
                      _pdfCell(
                        _formatScanTime(records[i].scanTimestamp),
                        font,
                      ),
                      _pdfCell(
                        records[i].notes ?? (records[i].score > 0 ? (records[i].status == 'excused' ? 'عذر' : 'تم الرصد') : 'غائب'),
                        font,
                      ),
                    ],
                  ),
                ],
                // SUM Total Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('D1FAE5')),
                  children: [
                    _pdfCell('-', fontBold),
                    _pdfCell('المجموع', fontBold),
                    _pdfCell('إجمالي درجات الحضور للجلسة (SUM)', fontBold),
                    _pdfCell('-', fontBold),
                    _pdfCell('$presentCount / $totalStudents', fontBold),
                    _pdfCell('[$presentCount]', fontBold, color: PdfColor.fromHex('064E3B')),
                    _pdfCell('%$percent', fontBold),
                    _pdfCell('نسبة الحضور', fontBold),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final cleanCourse = (course?.courseName ?? 'مقرر').replaceAll(' ', '_');
    final cleanLoc = (session.location ?? 'قاعة').replaceAll(' ', '_');
    final fileName = 'كشف_حضور_${cleanCourse}_${cleanLoc}_$dateStr.pdf';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  /// Builds in-memory cumulative attendance ledger Excel
  static Excel buildCumulativeExcel({
    required Course course,
    required String doctorName,
    required List<Session> sessions,
    required List<CumulativeStudentReport> reports,
  }) {
    final excel = Excel.createExcel();
    final String sheetName = 'سجل الرصد التراكمي';
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    final Sheet sheet = excel[sheetName];
    sheet.isRTL = true;

    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final totalStudents = reports.length;
    final totalSessions = sessions.length;
    final double avgPct = reports.isNotEmpty
        ? reports.map((r) => r.attendancePercentage).reduce((a, b) => a + b) / reports.length
        : 0.0;

    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      backgroundColorHex: ExcelColor.fromHexString('#064E3B'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final CellStyle metaStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#E6F4EA'),
      fontColorHex: ExcelColor.fromHexString('#064E3B'),
      horizontalAlign: HorizontalAlign.Right,
    );
    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#059669'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final CellStyle regularStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#F0FDF4'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final CellStyle atRiskStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
      fontColorHex: ExcelColor.fromHexString('#92400E'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final CellStyle deprivedStyle = CellStyle(
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FEF2F2'),
      fontColorHex: ExcelColor.fromHexString('#991B1B'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final CellStyle sumRowStyle = CellStyle(
      bold: true,
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D1FAE5'),
      fontColorHex: ExcelColor.fromHexString('#064E3B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final maxCol = 9 + sessions.length;

    // Row 1: Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('سجل رصد الحضور التراكمي الشامل - جامعة دمنهور (DMU)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: maxCol, rowIndex: 0),
    );

    // Row 2: Course info
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('المقرر: ${course.courseName} | الفرقة: ${course.gradeYear} | القسم: ${course.department} | نوع التدريس: ${course.teachingTypeArabic} | إجمالي الجلسات: $totalSessions');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = metaStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: maxCol, rowIndex: 1),
    );

    // Row 3: Doctor & Stats
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('القائم بالتدريس: $doctorName | التاريخ: $dateStr | إجمالي الطلاب المقيدين: $totalStudents | متوسط الحضور العام: %${avgPct.toStringAsFixed(1)}');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = metaStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: maxCol, rowIndex: 2),
    );

    // Row 4: Column Headers
    final baseHeaders = [
      'م',
      'الكود الجامعي',
      'اسم الطالب',
      'المكان / المجموعة',
      'مرات الحضور',
      'مرات الغياب',
      'الأعذار',
      'مجموع الدرجات',
      'نسبة الحضور %',
      'حالة الانتظام',
    ];

    int colIdx = 0;
    for (final h in baseHeaders) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIdx++, rowIndex: 3));
      cell.value = TextCellValue(h);
      cell.cellStyle = headerStyle;
    }

    for (int s = 0; s < sessions.length; s++) {
      final sess = sessions[s];
      final sessionHeader = 'ج ${s + 1} (${sess.sessionTypeArabic.split(" ").first})';
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIdx++, rowIndex: 3));
      cell.value = TextCellValue(sessionHeader);
      cell.cellStyle = headerStyle;
    }

    // Student Rows
    int currentRow = 4;
    for (int i = 0; i < reports.length; i++) {
      final rep = reports[i];
      CellStyle rowStyle = regularStyle;
      if (rep.isDeprived) {
        rowStyle = deprivedStyle;
      } else if (rep.isAtRisk) {
        rowStyle = atRiskStyle;
      }

      int c = 0;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = IntCellValue(i + 1)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = TextCellValue(rep.academicId)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = TextCellValue(rep.fullName)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = TextCellValue(rep.location ?? 'عام')
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = IntCellValue(rep.attendedSessions)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = IntCellValue(rep.absentSessions)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = IntCellValue(rep.excusedSessions)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = IntCellValue(rep.totalScore)
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = TextCellValue('%${rep.attendancePercentage.toStringAsFixed(1)}')
        ..cellStyle = rowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
        ..value = TextCellValue(rep.statusTag)
        ..cellStyle = rowStyle;

      for (final sess in sessions) {
        final score = rep.sessionScores[sess.sessionId!] ?? 0;
        final status = rep.sessionStatuses[sess.sessionId!];
        String textVal = score > 0 ? '1' : '0';
        if (status == 'excused') textVal = 'عذر (1)';

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: currentRow))
          ..value = TextCellValue(textVal)
          ..cellStyle = rowStyle;
      }

      currentRow++;
    }

    // Summary Row with SUM formula across Column H (column index 7)
    final startRow = 5;
    final endRow = currentRow > 4 ? currentRow : 5;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('الإجمالي العام والمتوسطات (معادلة SUM التلقائية):')
      ..cellStyle = sumRowStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow))
      ..value = FormulaCellValue('SUM(H$startRow:H$endRow)')
      ..cellStyle = sumRowStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: currentRow))
      ..value = TextCellValue('%${avgPct.toStringAsFixed(1)}')
      ..cellStyle = sumRowStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: currentRow))
      ..value = TextCellValue('متوسط الحضور')
      ..cellStyle = sumRowStyle;

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 16);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 14);
    sheet.setColumnWidth(9, 16);

    for (int s = 0; s < sessions.length; s++) {
      sheet.setColumnWidth(10 + s, 12);
    }

    return excel;
  }

  /// Exports Cumulative Excel File
  static Future<File> exportCumulativeExcel({
    required Course course,
    required String doctorName,
    required List<Session> sessions,
    required List<CumulativeStudentReport> reports,
  }) async {
    final excel = buildCumulativeExcel(
      course: course,
      doctorName: doctorName,
      sessions: sessions,
      reports: reports,
    );

    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final cleanCourse = course.courseName.replaceAll(' ', '_');
    final fileName = 'رصد_تراكمي_${cleanCourse}_$dateStr.xlsx';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file;
  }

  /// Exports Cumulative PDF File with official academic layout
  static Future<File> exportCumulativePdf({
    required Course course,
    required String doctorName,
    required List<Session> sessions,
    required List<CumulativeStudentReport> reports,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final now = DateTime.now();
    final dateStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final totalStudents = reports.length;
    final totalSessions = sessions.length;
    final double avgPct = reports.isNotEmpty
        ? reports.map((r) => r.attendancePercentage).reduce((a, b) => a + b) / reports.length
        : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('064E3B'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Center(
              child: pw.Text(
                'سجل رصد الحضور التراكمي الشامل - جامعة دمنهور (DMU)',
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.white),
              ),
            ),
          ),
          pw.SizedBox(height: 8),

          // Course Metadata Row
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('E6F4EA'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('المقرر: ${course.courseName}', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColor.fromHex('064E3B'))),
                pw.Text('الفرقة: ${course.gradeYear}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('064E3B'))),
                pw.Text('القسم: ${course.department}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('064E3B'))),
                pw.Text('نوع التدريس: ${course.teachingTypeArabic}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('064E3B'))),
                pw.Text('إجمالي الجلسات: $totalSessions', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColor.fromHex('064E3B'))),
              ],
            ),
          ),
          pw.SizedBox(height: 4),

          // Doctor & Stats Row
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F1F5F9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('القائم بالتدريس: $doctorName', style: pw.TextStyle(font: fontBold, fontSize: 9.5)),
                pw.Text('التاريخ: $dateStr', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('إجمالي الطلاب: $totalStudents', style: pw.TextStyle(font: font, fontSize: 9)),
                pw.Text('متوسط الحضور العام: %${avgPct.toStringAsFixed(1)}', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColor.fromHex('064E3B'))),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Cumulative Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('CBD5E1'), width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(22),  // م
              1: const pw.FixedColumnWidth(55),  // الكود
              2: const pw.FlexColumnWidth(2.6),  // اسم الطالب
              3: const pw.FlexColumnWidth(1.4),  // المكان
              4: const pw.FixedColumnWidth(34),  // حضور
              5: const pw.FixedColumnWidth(34),  // غياب
              6: const pw.FixedColumnWidth(34),  // أعذار
              7: const pw.FixedColumnWidth(40),  // مجموع الدرجات
              8: const pw.FixedColumnWidth(48),  // النسبة %
              9: const pw.FixedColumnWidth(55),  // الحالة
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('059669')),
                children: [
                  _pdfCell('م', fontBold, isHeader: true),
                  _pdfCell('الكود', fontBold, isHeader: true),
                  _pdfCell('اسم الطالب', fontBold, isHeader: true),
                  _pdfCell('المكان / السكشن', fontBold, isHeader: true),
                  _pdfCell('حضور', fontBold, isHeader: true),
                  _pdfCell('غياب', fontBold, isHeader: true),
                  _pdfCell('أعذار', fontBold, isHeader: true),
                  _pdfCell('الدرجات', fontBold, isHeader: true),
                  _pdfCell('النسبة %', fontBold, isHeader: true),
                  _pdfCell('الحالة', fontBold, isHeader: true),
                ],
              ),
              // Data Rows
              for (int i = 0; i < reports.length; i++)
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: reports[i].isDeprived
                        ? PdfColor.fromHex('FEF2F2')
                        : (reports[i].isAtRisk
                            ? PdfColor.fromHex('FEF3C7')
                            : (i % 2 == 0 ? PdfColor.fromHex('FAFAFA') : PdfColors.white)),
                  ),
                  children: [
                    _pdfCell('${i + 1}', font),
                    _pdfCell(reports[i].academicId, font),
                    _pdfCell(reports[i].fullName, fontBold),
                    _pdfCell(reports[i].location ?? 'عام', font),
                    _pdfCell('${reports[i].attendedSessions}', fontBold, color: PdfColor.fromHex('059669')),
                    _pdfCell('${reports[i].absentSessions}', font, color: reports[i].absentSessions > 0 ? PdfColor.fromHex('DC2626') : null),
                    _pdfCell('${reports[i].excusedSessions}', font),
                    _pdfCell('${reports[i].totalScore}', fontBold),
                    _pdfCell('%${reports[i].attendancePercentage.toStringAsFixed(1)}', fontBold),
                    _pdfCell(
                      reports[i].statusTag,
                      fontBold,
                      color: reports[i].isDeprived
                          ? PdfColor.fromHex('DC2626')
                          : (reports[i].isAtRisk ? PdfColor.fromHex('D97706') : PdfColor.fromHex('059669')),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    final cleanCourse = course.courseName.replaceAll(' ', '_');
    final fileName = 'رصد_تراكمي_${cleanCourse}_$dateStr.pdf';

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  static pw.Widget _pdfCell(String text, pw.Font font, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8.5,
          color: isHeader ? PdfColors.white : (color ?? PdfColors.black),
        ),
      ),
    );
  }

  static String _formatScanTime(String? ts) {
    if (ts == null || ts.isEmpty) return '-- : --';
    try {
      final dt = DateTime.parse(ts);
      return intl.DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return ts;
    }
  }

  /// Share file directly via WhatsApp / Telegram / Email (Direct Intent Sharing)
  static Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: 'مرفق كشف تسجيل الحضور والغياب الصادر من منظومة DMU - جامعة دمنهور.',
    );
  }

  /// Generates the standard Excel Import Template (شيت استيراد الطلاب الأولي)
  static Future<File> generateImportTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
    sheet.isRTL = true;

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#0D47A1'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['م', 'الكود الجامعي', 'اسم الطالب بالكامل', 'الفرقة', 'القسم العلمي', 'المكان المخصص'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Add sample rows with serial column (م)
    final sampleRows = [
      ['1', '20261001', 'أحمد محمد إبراهيم', 'الفرقة الثانية', 'حاسبات', 'مدرج 1'],
      ['2', '20261002', 'محمود حسن السيد', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
      ['3', '20261003', 'سارة علي المنشاوي', 'الفرقة الثانية', 'نظم معلومات', 'معمل شبكات ب'],
      ['4', '20261004', 'كريم عادل فهمي', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
      ['5', '20261005', 'يوسف محمود رجب', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
      ['6', '20261006', 'نورهان خالد العطار', 'الفرقة الثانية', 'نظم معلومات', 'معمل شبكات ب'],
      ['7', '20261007', 'عمر طارق الشافعي', 'الفرقة الثانية', 'حاسبات', 'مدرج 1'],
      ['8', '20261008', 'منى عبد الرحمن حسن', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
    ];

    for (int r = 0; r < sampleRows.length; r++) {
      for (int c = 0; c < sampleRows[r].length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1)).value =
            c == 0 ? IntCellValue(r + 1) : TextCellValue(sampleRows[r][c]);
      }
    }

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 20);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/قالب_استيراد_طلاب_الدفعة_DMU.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file;
  }

  /// Parse uploaded Excel or CSV file into Student models
  static Future<List<Student>> parseStudentExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final List<Student> students = [];

    final sheet = excel.tables.values.firstOrNull;
    if (sheet == null) return [];

    int academicIdCol = 0;
    int fullNameCol = 1;
    int gradeYearCol = 2;
    int departmentCol = 3;
    int locationCol = 4;

    bool headerFound = false;

    for (int r = 0; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      final rowTexts = row.map((c) => c?.value?.toString().trim() ?? '').toList();

      // Detect header row dynamically
      if (!headerFound) {
        bool containsHeaderKeywords = false;
        for (int c = 0; c < rowTexts.length; c++) {
          final t = rowTexts[c].toLowerCase();
          // Serial number column
          if (t == 'م' || t.contains('مسلسل') || t == '#' || t == 'no' || t == 'seq') {
            containsHeaderKeywords = true;
            continue;
          }
          if (t.contains('كود') || t.contains('academic') || t.contains('جامعي') || t == 'id') {
            academicIdCol = c;
            containsHeaderKeywords = true;
          } else if (t.contains('اسم') || t.contains('name') || t.contains('طالب')) {
            fullNameCol = c;
            containsHeaderKeywords = true;
          } else if (t.contains('فرقة') || t.contains('grade') || t.contains('year')) {
            gradeYearCol = c;
            containsHeaderKeywords = true;
          } else if (t.contains('قسم') || t.contains('dept') || t.contains('department')) {
            departmentCol = c;
            containsHeaderKeywords = true;
          } else if (t.contains('مكان') || t.contains('معمل') || t.contains('قاعة') || t.contains('location') || t.contains('مدرج')) {
            locationCol = c;
            containsHeaderKeywords = true;
          }
        }
        if (containsHeaderKeywords) {
          headerFound = true;
          continue;
        }
      }

      // If no explicit header was found and this is a raw data row, check if col 0 is serial index
      if (!headerFound && rowTexts.length >= 2) {
        final col0IsSerial = RegExp(r'^\d{1,4}$').hasMatch(rowTexts[0]);
        final col1IsId = RegExp(r'^\d{5,}$').hasMatch(rowTexts[1]);
        if (col0IsSerial && col1IsId) {
          academicIdCol = 1;
          fullNameCol = 2;
          gradeYearCol = 3;
          departmentCol = 4;
          locationCol = 5;
        }
      }

      // Parse data row
      final id = _getColValue(rowTexts, academicIdCol);
      final name = _getColValue(rowTexts, fullNameCol);
      final grade = _getColValue(rowTexts, gradeYearCol);
      final dept = _getColValue(rowTexts, departmentCol);
      final loc = _getColValue(rowTexts, locationCol);

      // Validate that id is not header text
      if (id.isNotEmpty && name.isNotEmpty && id != 'م' && !id.contains('كود') && !name.contains('اسم')) {
        students.add(Student(
          academicId: id,
          fullName: name,
          gradeYear: grade.isNotEmpty ? grade : 'الفرقة الأولى',
          department: dept.isNotEmpty ? dept : 'عام',
          location: loc.isNotEmpty ? loc : 'مدرج 1',
        ));
      }
    }

    return students;
  }

  static String _getColValue(List<String> row, int index) {
    if (index >= 0 && index < row.length) {
      return row[index];
    }
    return '';
  }
}
