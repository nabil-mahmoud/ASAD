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

class ExcelPdfExporter {
  /// Generate and export Excel sheet (.xlsx) exactly matching ASAD specifications (Page 3)
  static Future<File> exportSessionExcel({
    required Session session,
    required Course? course,
    required String doctorName,
    required List<AttendanceRecord> records,
  }) async {
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

    // Row 1: University Banner
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('جامعة القاهرة - كلية الحاسبات والمعلومات | العام الجامعي: 2026/2027 (منظومة ASAD الذكية)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0),
    );

    // Row 2: Course & Session Details
    final courseName = course?.courseName ?? session.courseName ?? 'المقرر';
    final gradeYear = course?.gradeYear ?? 'الفرقة الدراسية';
    final dept = course?.department ?? 'عام';
    final sessionType = session.sessionTypeArabic;
    final loc = session.location ?? 'الكل';

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('المقرر: $courseName | الفرقة: $gradeYear ($dept) | نوع الجلسة: $sessionType | المكان: $loc');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = metaStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1),
    );

    // Row 3: Date, Doctor, Attendance Count
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('التاريخ: $dateStr ($timeStr) | القائم بالتدريس: $doctorName | الحضور: $presentCount من $totalStudents (%$percent)');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).cellStyle = metaStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2),
    );

    // Empty separator row
    // Row 4 (index 3): Table Headers
    final headers = ['م', 'الكود الجامعي', 'اسم الطالب', 'المكان', 'الحالة', 'الدرجة', 'وقت الرصد'];
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

      // Col 4: الحالة
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
        ..value = TextCellValue(rec.statusArabic)
        ..cellStyle = style;

      // Col 5: الدرجة (1 or 0)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
        ..value = IntCellValue(rec.score)
        ..cellStyle = style;

      // Col 6: وقت الرصد
      String scanTimeDisplay = '-- : --';
      if (rec.scanTimestamp != null && rec.scanTimestamp!.isNotEmpty) {
        try {
          final dt = DateTime.parse(rec.scanTimestamp!);
          scanTimeDisplay = intl.DateFormat('hh:mm a').format(dt);
        } catch (_) {
          scanTimeDisplay = rec.scanTimestamp!;
        }
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
        ..value = TextCellValue(scanTimeDisplay)
        ..cellStyle = style;

      currentRow++;
    }

    // Row N+1: SUM Formula Row (الصف الإجمالي بمعادلة SUM التلقائية)
    final startExcelRow = 5; // 1-indexed in Excel (Row 5 is first student)
    final endExcelRow = currentRow; // last student row

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

    final sumValueCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
    sumValueCell.value = TextCellValue('[$presentCount]');
    sumValueCell.cellStyle = sumRowStyle;

    // Set Column Widths for clean viewing
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 30);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 16);

    // Save File
    final cleanCourse = (course?.courseName ?? 'مقرر').replaceAll(' ', '_');
    final cleanLoc = (session.location ?? 'قاعة').replaceAll(' ', '_');
    final fileName = 'غياب_${cleanCourse}_${cleanLoc}_$dateStr.xlsx';

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
                  color: PdfColor.fromHex('064E3B'),
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
                          'جامعة القاهرة - كلية الحاسبات والمعلومات',
                          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.white),
                        ),
                        pw.Text(
                          'العام الجامعي: 2026/2027',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('A7F3D0')),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'منظومة ASAD',
                          style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.white),
                        ),
                        pw.Text(
                          'نظام تسجيل الحضور والغياب الذكي',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('A7F3D0')),
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
                0: const pw.FixedColumnWidth(24),  // م
                1: const pw.FixedColumnWidth(60),  // الكود الجامعي
                2: const pw.FlexColumnWidth(2.5),  // اسم الطالب
                3: const pw.FlexColumnWidth(1.4),  // المكان
                4: const pw.FixedColumnWidth(60),  // الحالة
                5: const pw.FixedColumnWidth(35),  // الدرجة
                6: const pw.FixedColumnWidth(50),  // وقت الرصد
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
                    _pdfCell('وقت الرصد', fontBold, isHeader: true),
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
                      _pdfCell('${records[i].score}', fontBold),
                      _pdfCell(
                        _formatScanTime(records[i].scanTimestamp),
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
    final fileName = 'تقرير_غياب_${cleanCourse}_${cleanLoc}_$dateStr.pdf';

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
      text: 'مرفق كشف تسجيل الحضور والغياب الصادر من منظومة ASAD الذكية.',
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
      backgroundColorHex: ExcelColor.fromHexString('#059669'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['الكود الجامعي', 'اسم الطالب بالكامل', 'الفرقة', 'القسم العلمي', 'المكان المخصص'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Add sample rows from the official specification (Page 3)
    final sampleRows = [
      ['20261001', 'أحمد محمد إبراهيم', 'الفرقة الثانية', 'حاسبات', 'مدرج 1'],
      ['20261002', 'محمود حسن السيد', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
      ['20261003', 'سارة علي المنشاوي', 'الفرقة الثانية', 'نظم معلومات', 'معمل شبكات ب'],
      ['20261004', 'كريم عادل فهمي', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
      ['20261005', 'يوسف محمود رجب', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
      ['20261006', 'نورهان خالد العطار', 'الفرقة الثانية', 'نظم معلومات', 'معمل شبكات ب'],
      ['20261007', 'عمر طارق الشافعي', 'الفرقة الثانية', 'حاسبات', 'مدرج 1'],
      ['20261008', 'منى عبد الرحمن حسن', 'الفرقة الثانية', 'حاسبات', 'معمل برمجة أ'],
    ];

    for (int r = 0; r < sampleRows.length; r++) {
      for (int c = 0; c < sampleRows[r].length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1)).value =
            TextCellValue(sampleRows[r][c]);
      }
    }

    sheet.setColumnWidth(0, 16);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 20);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/قالب_استيراد_طلاب_الدفعة_ASAD.xlsx');
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
        for (int c = 0; c < rowTexts.length; c++) {
          final t = rowTexts[c].toLowerCase();
          if (t.contains('كود') || t.contains('academic') || t.contains('id')) {
            academicIdCol = c;
            headerFound = true;
          } else if (t.contains('اسم') || t.contains('name') || t.contains('طالب')) {
            fullNameCol = c;
          } else if (t.contains('فرقة') || t.contains('grade') || t.contains('year')) {
            gradeYearCol = c;
          } else if (t.contains('قسم') || t.contains('dept') || t.contains('department')) {
            departmentCol = c;
          } else if (t.contains('مكان') || t.contains('معمل') || t.contains('قاعة') || t.contains('location')) {
            locationCol = c;
          }
        }
        if (headerFound) continue;
      }

      // Parse data row
      final id = _getColValue(rowTexts, academicIdCol);
      final name = _getColValue(rowTexts, fullNameCol);
      final grade = _getColValue(rowTexts, gradeYearCol);
      final dept = _getColValue(rowTexts, departmentCol);
      final loc = _getColValue(rowTexts, locationCol);

      if (id.isNotEmpty && name.isNotEmpty) {
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
