import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/excel_pdf_exporter.dart';
import '../../domain/models/student.dart';
import '../controllers/app_state.dart';

class Screen3Importer extends StatefulWidget {
  const Screen3Importer({super.key});

  @override
  State<Screen3Importer> createState() => _Screen3ImporterState();
}

class _Screen3ImporterState extends State<Screen3Importer> {
  final AppState _appState = AppState();
  final DatabaseHelper _db = DatabaseHelper();

  List<Student> _students = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedLocationFilter;
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await _db.getStudents(
      location: _selectedLocationFilter,
      query: _searchQuery,
    );
    final locs = await _db.getAllUniqueLocations();
    setState(() {
      _students = list;
      _locations = locs;
      _isLoading = false;
    });
  }

  Future<void> _pickAndImportExcel() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (pickedFiles.isEmpty) return;

      setState(() => _isLoading = true);

      final firstFile = pickedFiles.first;
      final fileBytes = await firstFile.xFile.readAsBytes();

      final parsedStudents = await ExcelPdfExporter.parseStudentExcel(fileBytes);

      if (parsedStudents.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على بيانات طلاب صالحة في الملف المرفوع. تأكد من تطابق أسماء الأعمدة.'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final count = await _appState.importStudents(parsedStudents);
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم استيراد وحفظ $count طالباً بنجاح في قاعدة البيانات المحلية!'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء استيراد الملف: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadTemplate() async {
    final file = await ExcelPdfExporter.generateImportTemplate();
    await ExcelPdfExporter.shareFile(file, 'قالب استيراد طلاب الدفعة - ASAD');
  }

  Future<void> _clearAllStudentsDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('استبدال / مسح كشف الطلاب'),
        content: const Text(
          'هل تريد مسح كشف الطلاب الحالي لاستبداله بكشف محدث من شؤون الطلاب؟\nلن تتأثر سجلات الجلسات السابقة المؤرشفة.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('تأكيد المسح'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await _db.clearAllStudents();
      await _appState.refreshAll();
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد كشف الدفعة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'تنزيل قالب الإكسيل المعتمد',
            onPressed: _downloadTemplate,
          ),
          if (_students.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.dangerRed),
              tooltip: 'مسح / استبدال الكشف',
              onPressed: _clearAllStudentsDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _pickAndImportExcel,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('استيراد شيت إكسيل الطلاب (XLSX)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download_rounded, color: AppColors.mintAccent),
                      label: const Text('قالب فارغ'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search and Location Filter Bar
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم، الكود، أو المكان...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emerald),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _loadData();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          _searchQuery = val.trim();
                          _loadData();
                        },
                      ),
                    ),
                    if (_locations.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String?>(
                          value: _selectedLocationFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            isDense: true,
                          ),
                          hint: const Text('كل الأماكن', style: TextStyle(fontSize: 12)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل الأماكن', style: TextStyle(fontSize: 12))),
                            ..._locations.map(
                              (loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedLocationFilter = val);
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Total count banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي الطلاب المقيدين: ${_students.length}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.mintAccent),
                ),
                Text(
                  _selectedLocationFilter != null ? 'المكان: $_selectedLocationFilter' : 'جميع الأماكن المخصصة',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Students Table / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.emerald))
                : _students.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textDim),
                              const SizedBox(height: 16),
                              const Text(
                                'لا توجد بيانات طلاب حالياً',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'قم باستيراد ملف كشف الطلاب من شؤون الطلاب (Excel) لتسجيل وتحديث الفرق والأقسام والأماكن المعتمدة تلقائياً.',
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _pickAndImportExcel,
                                icon: const Icon(Icons.upload_file_rounded),
                                label: const Text('استيراد شيت الطلاب الآن (XLSX)'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final st = _students[index];
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.surfaceCardBorder, width: 0.5),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.royalDark,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mintAccent),
                                ),
                              ),
                              title: Text(
                                st.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textLight),
                              ),
                              subtitle: Text(
                                'كود: ${st.academicId} • ${st.gradeYear} (${st.department})',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
                                ),
                                child: Text(
                                  st.location,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.mintAccent),
                                ),
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
}
