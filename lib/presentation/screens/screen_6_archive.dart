import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/excel_pdf_exporter.dart';
import '../../domain/models/attendance_record.dart';
import '../../domain/models/course.dart';
import '../../domain/models/session.dart';
import '../controllers/app_state.dart';

class Screen6Archive extends StatefulWidget {
  const Screen6Archive({super.key});

  @override
  State<Screen6Archive> createState() => _Screen6ArchiveState();
}

class _Screen6ArchiveState extends State<Screen6Archive> {
  final AppState _appState = AppState();
  final DatabaseHelper _db = DatabaseHelper();

  List<Session> _sessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final list = await _db.getSessions();
    setState(() {
      _sessions = list;
      _isLoading = false;
    });
  }

  Future<void> _openSessionDetails(Session session) async {
    final records = await _db.getSessionRecords(session.sessionId!);
    final course = _appState.courses.firstWhere(
      (c) => c.courseId == session.courseId,
      orElse: () => Course(
        courseId: session.courseId,
        courseName: session.courseName ?? 'المقرر',
        gradeYear: '',
        department: '',
        teachingType: 'theory_only',
      ),
    );

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SessionDetailsScreen(
          session: session,
          course: course,
          records: records,
          onRefreshNeeded: _loadSessions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الأرشيف والتصدير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث الأرشيف',
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
          : _sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.archive_outlined, size: 64, color: AppColors.textDim),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد جلسات غياب مؤرشفة حالياً',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'كافة الجلسات التي تنهيها في القاعة تُحفظ تلقائياً هنا في سجل دائم للتصدير في أي وقت.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = _sessions[index];
                    final present = s.presentCount ?? 0;
                    final total = s.totalStudentsCount ?? 0;
                    final pct = total > 0 ? ((present / total) * 100).toInt() : 0;

                    String formattedDate = s.createdAt;
                    try {
                      final dt = DateTime.parse(s.createdAt);
                      formattedDate = intl.DateFormat('yyyy/MM/dd - hh:mm a').format(dt);
                    } catch (_) {}

                    return InkWell(
                      onTap: () => _openSessionDetails(s),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceCardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.courseName ?? 'مقرر دراسي',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.emerald.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    '$present / $total (%$pct)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.mintAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    s.sessionTypeArabic,
                                    style: const TextStyle(fontSize: 11, color: AppColors.mintAccent),
                                  ),
                                ),
                                if (s.location != null && s.location!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'المكان: ${s.location}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      'عرض وتصدير',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mintAccent),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.mintAccent),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SessionDetailsScreen extends StatefulWidget {
  final Session session;
  final Course course;
  final List<AttendanceRecord> records;
  final VoidCallback onRefreshNeeded;

  const _SessionDetailsScreen({
    required this.session,
    required this.course,
    required this.records,
    required this.onRefreshNeeded,
  });

  @override
  State<_SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<_SessionDetailsScreen> {
  final AppState _appState = AppState();

  late List<AttendanceRecord> _records;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _records = widget.records;
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final doctorName = _appState.doctorProfile?.doctorName ?? 'القائم بالتدريس';
      final file = await ExcelPdfExporter.exportSessionExcel(
        session: widget.session,
        course: widget.course,
        doctorName: doctorName,
        records: _records,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء شيت الإكسيل بمعادلة SUM بنجاح: ${file.path.split('/').last}'),
          backgroundColor: AppColors.emerald,
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => ExcelPdfExporter.shareFile(file, 'كشف حضور - ${widget.course.courseName}'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء تصدير الإكسيل: $e'), backgroundColor: AppColors.dangerRed),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final doctorName = _appState.doctorProfile?.doctorName ?? 'القائم بالتدريس';
      final file = await ExcelPdfExporter.exportSessionPdf(
        session: widget.session,
        course: widget.course,
        doctorName: doctorName,
        records: _records,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء تقرير الـ PDF المعتمد بنجاح: ${file.path.split('/').last}'),
          backgroundColor: AppColors.emerald,
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => ExcelPdfExporter.shareFile(file, 'تقرير غياب - ${widget.course.courseName}'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء تصدير الـ PDF: $e'), backgroundColor: AppColors.dangerRed),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareDirectly() async {
    // Generate Excel and share via WhatsApp / Intent
    setState(() => _isExporting = true);
    try {
      final doctorName = _appState.doctorProfile?.doctorName ?? 'القائم بالتدريس';
      final file = await ExcelPdfExporter.exportSessionExcel(
        session: widget.session,
        course: widget.course,
        doctorName: doctorName,
        records: _records,
      );
      await ExcelPdfExporter.shareFile(file, 'كشف غياب ${widget.course.courseName} - شؤون الطلاب');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء المشاركة: $e'), backgroundColor: AppColors.dangerRed),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _records.where((r) => r.score > 0).length;
    final totalCount = _records.length;
    final percentage = totalCount > 0 ? ((presentCount / totalCount) * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.courseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.mintAccent),
            tooltip: 'مشاركة سريعة عبر WhatsApp / تطبيق آخر',
            onPressed: _isExporting ? null : _shareDirectly,
          ),
        ],
      ),
      body: Column(
        children: [
          // Session Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceDark,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المكان: ${widget.session.location ?? "الكل"} • ${widget.session.sessionTypeArabic}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'التاريخ: ${widget.session.createdAt.split("T").first}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.royalDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.emerald.withOpacity(0.5)),
                      ),
                      child: Text(
                        'الحضور: $presentCount / $totalCount (%$percentage)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mintAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Export Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF107C41), // Excel green
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isExporting ? null : _exportExcel,
                        icon: const Icon(Icons.table_view_rounded, size: 20),
                        label: const Text('تصدير Excel (معادلة SUM)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626), // PDF red
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isExporting ? null : _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                        label: const Text('تقرير PDF رسمي'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceCard,
            child: const Row(
              children: [
                SizedBox(width: 32, child: Text('م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('الكود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 40, child: Text('الدرجة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),

          // Attendance Records List
          Expanded(
            child: ListView.separated(
              itemCount: _records.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceCardBorder, height: 1),
              itemBuilder: (context, index) {
                final rec = _records[index];
                final isPresent = rec.score > 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          rec.studentName ?? 'طالب',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          rec.academicId,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPresent ? AppColors.emerald.withOpacity(0.15) : AppColors.dangerRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rec.statusArabic,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPresent ? AppColors.mintAccent : AppColors.dangerRed,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${rec.score}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isPresent ? AppColors.mintAccent : AppColors.dangerRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // SUM Row Footer (إجمالي درجات الحضور للجلسة - معادلة SUM التلقائية)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.royalDark,
              border: Border(top: BorderSide(color: AppColors.emerald, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.functions_rounded, color: AppColors.mintAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'إجمالي درجات الحضور (SUM التلقائية):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  '=SUM() -> [$presentCount من $totalCount]',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppColors.mintAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
