import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/excel_pdf_exporter.dart';
import '../../domain/models/course.dart';
import '../../domain/models/cumulative_student_report.dart';
import '../../domain/models/session.dart';
import '../controllers/app_state.dart';

class Screen7CumulativeReports extends StatefulWidget {
  final Course? initialCourse;

  const Screen7CumulativeReports({
    super.key,
    this.initialCourse,
  });

  @override
  State<Screen7CumulativeReports> createState() => _Screen7CumulativeReportsState();
}

class _Screen7CumulativeReportsState extends State<Screen7CumulativeReports> {
  final AppState _appState = AppState();

  Course? _selectedCourse;
  List<Session> _courseSessions = [];
  List<CumulativeStudentReport> _reports = [];
  bool _isLoading = false;
  bool _isExporting = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'regular', 'at_risk', 'deprived'

  @override
  void initState() {
    super.initState();
    _initCourse();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initCourse() {
    if (_appState.courses.isNotEmpty) {
      _selectedCourse = widget.initialCourse ?? _appState.courses.first;
      _loadCumulativeData();
    }
  }

  Future<void> _loadCumulativeData() async {
    if (_selectedCourse == null) return;
    setState(() => _isLoading = true);

    try {
      final sessions = await _appState.getCourseSessions(_selectedCourse!.courseId!);
      final data = await _appState.getCumulativeCourseReport(_selectedCourse!.courseId!);
      if (mounted) {
        setState(() {
          _courseSessions = sessions;
          _reports = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تحميل التقرير التراكمي: $e')),
        );
      }
    }
  }

  List<CumulativeStudentReport> get _filteredReports {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _reports.where((r) {
      final matchesQuery = query.isEmpty ||
          r.fullName.toLowerCase().contains(query) ||
          r.academicId.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      switch (_selectedFilter) {
        case 'regular':
          return r.attendancePercentage >= 75.0;
        case 'at_risk':
          return r.isAtRisk && !r.isDeprived;
        case 'deprived':
          return r.isDeprived;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _exportExcel() async {
    if (_selectedCourse == null || _reports.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final doctorName = _appState.doctorProfile?.doctorName ?? 'القائم بالتدريس';
      final file = await ExcelPdfExporter.exportCumulativeExcel(
        course: _selectedCourse!,
        doctorName: doctorName,
        sessions: _courseSessions,
        reports: _reports,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استخراج شيت الرصد التراكمي: ${file.path.split("/").last}'),
          backgroundColor: AppColors.emerald,
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => ExcelPdfExporter.shareFile(
              file,
              'الرصد التراكمي لمقرر ${_selectedCourse!.courseName}',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء تصدير الإكسيل: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedCourse == null || _reports.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final doctorName = _appState.doctorProfile?.doctorName ?? 'القائم بالتدريس';
      final file = await ExcelPdfExporter.exportCumulativePdf(
        course: _selectedCourse!,
        doctorName: doctorName,
        sessions: _courseSessions,
        reports: _reports,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استخراج تقرير PDF المعتمد بنجاح: ${file.path.split("/").last}'),
          backgroundColor: AppColors.emerald,
          action: SnackBarAction(
            label: 'مشاركة',
            textColor: Colors.white,
            onPressed: () => ExcelPdfExporter.shareFile(
              file,
              'تقرير تراكمي - ${_selectedCourse!.courseName}',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء تصدير الـ PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareDirectly() async {
    if (_selectedCourse == null || _reports.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final doctorName = _appState.doctorProfile?.doctorName ?? 'القائم بالتدريس';
      final file = await ExcelPdfExporter.exportCumulativeExcel(
        course: _selectedCourse!,
        doctorName: doctorName,
        sessions: _courseSessions,
        reports: _reports,
      );
      await ExcelPdfExporter.shareFile(
        file,
        'سجل الرصد التراكمي - ${_selectedCourse!.courseName}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء المشاركة: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showManageSessionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إدارة جلسات المقرر المنعقدة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك حذف أي محاضرة لحذفها من السجل وإعادة احتساب الدرجات التراكمية تلقائياً.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _courseSessions.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد جلسات مسجلة لهذا المقرر حالياً',
                              style: TextStyle(color: AppColors.textDim),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _courseSessions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final s = _courseSessions[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.surfaceCardBorder),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.royalDark,
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.mintAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${s.sessionTypeArabic} • ${s.location ?? "الكل"}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'حضور: ${s.presentCount ?? 0} / ${s.totalStudentsCount ?? 0} طالب',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.mintAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed),
                                      tooltip: 'حذف الجلسة',
                                      onPressed: () {
                                        _confirmDeleteSession(s, () {
                                          setSheetState(() {});
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSession(Session session, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('حذف الجلسة نهائياً؟'),
        content: Text(
          'سيتم حذف جلسة (${session.sessionTypeArabic} - ${session.location}) وسجلات الحضور التابعة لها بالكامل، وإعادة احتساب الرصد التراكمي للمقرر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () async {
              Navigator.pop(c);
              await _appState.deleteSession(session.sessionId!);
              await _loadCumulativeData();
              onDeleted();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الجلسة وتحديث التقرير التراكمي بنجاح')),
                );
              }
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailModal(CumulativeStudentReport rep) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rep.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'كود: ${rep.academicId} • ${rep.location ?? "عام"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.mintAccent),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rep.isDeprived
                              ? AppColors.dangerRed.withOpacity(0.2)
                              : (rep.isAtRisk ? AppColors.warningYellow.withOpacity(0.2) : AppColors.emerald.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: rep.isDeprived ? AppColors.dangerRed : (rep.isAtRisk ? AppColors.warningYellow : AppColors.emerald),
                          ),
                        ),
                        child: Text(
                          rep.statusTag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: rep.isDeprived ? AppColors.dangerRed : (rep.isAtRisk ? AppColors.warningYellow : AppColors.emerald),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Metrics summary
                  Row(
                    children: [
                      _metricBadge('الحضور', '${rep.attendedSessions}', AppColors.emerald),
                      const SizedBox(width: 8),
                      _metricBadge('الغياب', '${rep.absentSessions}', AppColors.dangerRed),
                      const SizedBox(width: 8),
                      _metricBadge('الأعذار', '${rep.excusedSessions}', AppColors.warningYellow),
                      const SizedBox(width: 8),
                      _metricBadge('الدرجات', '${rep.totalScore}', AppColors.mintAccent),
                      const SizedBox(width: 8),
                      _metricBadge('النسبة', '%${rep.attendancePercentage.toStringAsFixed(1)}', Colors.white),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'سجل حضور الطالب جلسة بجلسة:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _courseSessions.isEmpty
                        ? const Center(child: Text('لا توجد جلسات مسجلة'))
                        : ListView.separated(
                            itemCount: _courseSessions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final sess = _courseSessions[idx];
                              final status = rep.sessionStatuses[sess.sessionId!] ?? 'absent';
                              final score = rep.sessionScores[sess.sessionId!] ?? 0;

                              Color statusColor = AppColors.dangerRed;
                              String statusText = 'غائب (0)';
                              if (status == 'present') {
                                statusColor = AppColors.emerald;
                                statusText = 'حاضر ($score)';
                              } else if (status == 'excused') {
                                statusColor = AppColors.warningYellow;
                                statusText = 'عذر مقبول ($score)';
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.surfaceCardBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'المحاضرة ${idx + 1} (${sess.sessionTypeArabic})',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = _appState.courses;
    final totalSessions = _courseSessions.length;
    final totalStudents = _reports.length;
    final atRiskCount = _reports.where((r) => r.isAtRisk).length;
    final deprivedCount = _reports.where((r) => r.isDeprived).length;
    final double avgPct = _reports.isNotEmpty
        ? _reports.map((r) => r.attendancePercentage).reduce((a, b) => a + b) / _reports.length
        : 0.0;

    final filtered = _filteredReports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل رصد المادة التراكمي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.mintAccent),
            tooltip: 'مشاركة سريعة',
            onPressed: _isExporting ? null : _shareDirectly,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: _loadCumulativeData,
          ),
        ],
      ),
      body: courses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'يرجى إضافة مقررات دراسية أولاً لعرض التقرير التراكمي',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                // Top Course Selector & Overview
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.surfaceDark,
                  child: Column(
                    children: [
                      // Course Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceCardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Course>(
                            value: _selectedCourse,
                            isExpanded: true,
                            dropdownColor: AppColors.surfaceDark,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.mintAccent),
                            items: courses.map((c) {
                              return DropdownMenuItem<Course>(
                                value: c,
                                child: Text(
                                  '${c.courseName} - ${c.gradeYear} (${c.department})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCourse = val);
                                _loadCumulativeData();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Metrics Row
                      Row(
                        children: [
                          _buildStatCard('الجلسات المنعقدة', '$totalSessions', AppColors.mintAccent),
                          const SizedBox(width: 8),
                          _buildStatCard('إجمالي الطلاب', '$totalStudents', const Color(0xFF60A5FA)),
                          const SizedBox(width: 8),
                          _buildStatCard('متوسط الحضور', '%${avgPct.toStringAsFixed(1)}', AppColors.emerald),
                          const SizedBox(width: 8),
                          _buildStatCard('المنذرين', '$atRiskCount', AppColors.warningYellow),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons Row: Excel, PDF, Manage Sessions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF107C41), // Excel green
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isExporting ? null : _exportExcel,
                              icon: const Icon(Icons.table_view_rounded, size: 18),
                              label: const Text('إكسيل (.xlsx)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626), // PDF red
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isExporting ? null : _exportPdf,
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                              label: const Text('تقرير PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceCard,
                              side: const BorderSide(color: AppColors.surfaceCardBorder),
                            ),
                            icon: const Icon(Icons.rule_folder_rounded, color: AppColors.mintAccent, size: 20),
                            tooltip: 'إدارة وحذف الجلسات',
                            onPressed: _showManageSessionsModal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search & Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم أو الكود الجامعي...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emerald, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('all', 'الكل ($totalStudents)'),
                            const SizedBox(width: 6),
                            _filterChip('regular', 'منتظم (≥75%)'),
                            const SizedBox(width: 6),
                            _filterChip('at_risk', 'منذر بالحرمان ($atRiskCount)'),
                            const SizedBox(width: 6),
                            _filterChip('deprived', 'محروم ($deprivedCount)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // List of Students
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                      : totalSessions == 0
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.analytics_outlined, size: 54, color: AppColors.textDim),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'لا توجد جلسات منعقدة لهذا المقرر بعد',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'عند إنهاء وحفظ أول جلسة حضور، سيظهر سجل الرصد التراكمي الشامل هنا.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : filtered.isEmpty
                              ? const Center(
                                  child: Text('لا توجد نتائج تطابق معايير البحث'),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final rep = filtered[index];
                                    return InkWell(
                                      onTap: () => _showStudentDetailModal(rep),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceCard,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: rep.isDeprived
                                                ? AppColors.dangerRed.withOpacity(0.5)
                                                : (rep.isAtRisk
                                                    ? AppColors.warningYellow.withOpacity(0.5)
                                                    : AppColors.surfaceCardBorder),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Status avatar
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: rep.isDeprived
                                                  ? AppColors.dangerRed.withOpacity(0.2)
                                                  : (rep.isAtRisk
                                                      ? AppColors.warningYellow.withOpacity(0.2)
                                                      : AppColors.emerald.withOpacity(0.2)),
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: rep.isDeprived
                                                      ? AppColors.dangerRed
                                                      : (rep.isAtRisk ? AppColors.warningYellow : AppColors.emerald),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Student Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    rep.fullName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: AppColors.textLight,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'كود: ${rep.academicId} • ${rep.location ?? "عام"}',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Stats badge
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.royalDark,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: rep.isDeprived
                                                          ? AppColors.dangerRed
                                                          : (rep.isAtRisk ? AppColors.warningYellow : AppColors.emerald),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '%${rep.attendancePercentage.toStringAsFixed(1)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: rep.isDeprived
                                                          ? AppColors.dangerRed
                                                          : (rep.isAtRisk ? AppColors.warningYellow : AppColors.mintAccent),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'حضور: ${rep.attendedSessions} من $totalSessions (${rep.totalScore} درجة)',
                                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedFilter == id;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textMuted,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.emerald,
      backgroundColor: AppColors.surfaceCard,
      onSelected: (_) => setState(() => _selectedFilter = id),
    );
  }
}
