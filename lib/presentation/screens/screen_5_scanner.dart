import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/app_state.dart';
import '../widgets/scan_feedback_overlay.dart';
import 'screen_6_archive.dart';

class Screen5Scanner extends StatefulWidget {
  const Screen5Scanner({super.key});

  @override
  State<Screen5Scanner> createState() => _Screen5ScannerState();
}

class _Screen5ScannerState extends State<Screen5Scanner> {
  final AppState _appState = AppState();
  MobileScannerController? _scannerController;

  bool _isTorchOn = false;
  bool _isProcessing = false;
  Timer? _overlayDismissTimer;

  // Manual Attendance Search & Selection
  final TextEditingController _searchCtrl = TextEditingController();

  // Scan Throttling & Debounce (1.8s cooling-down per barcode to avoid camera stream duplicate flood)
  DateTime? _lastScannedTimestamp;
  String? _lastScannedBarcode;
  static const Duration _cooldownDuration = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChange);
    _initScanner();
  }

  void _initScanner() {
    try {
      _scannerController = MobileScannerController(
        formats: const [
          BarcodeFormat.all,
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.ean13,
        ],
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 1500,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (e) {
      debugPrint('MobileScanner init error (desktop/web): $e');
    }
  }

  @override
  void dispose() {
    _overlayDismissTimer?.cancel();
    _appState.removeListener(_onStateChange);
    _scannerController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    final cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) return;

    final now = DateTime.now();

    // 1. Debounce & Throttling: Ignore rapid duplicate reads of the same barcode within 1.8 seconds
    if (_lastScannedBarcode == cleanCode &&
        _lastScannedTimestamp != null &&
        now.difference(_lastScannedTimestamp!) < _cooldownDuration) {
      return;
    }

    if (_isProcessing) return;
    _isProcessing = true;
    _lastScannedTimestamp = now;
    _lastScannedBarcode = cleanCode;

    try {
      await _appState.processScan(cleanCode);

      // Auto-dismiss the feedback banner/border after 2 seconds
      _overlayDismissTimer?.cancel();
      _overlayDismissTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() {});
      });
    } finally {
      // Small debounce delay before releasing processing lock
      Future.delayed(const Duration(milliseconds: 250), () {
        _isProcessing = false;
      });
    }
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;
    try {
      await _scannerController!.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  void _showManualAttendanceSheet() {
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
            final records = _appState.activeSessionRecords;
            final query = _searchCtrl.text.trim().toLowerCase();
            final filtered = records.where((r) {
              if (query.isEmpty) return true;
              final name = (r.studentName ?? '').toLowerCase();
              final id = r.academicId.toLowerCase();
              return name.contains(query) || id.contains(query);
            }).toList();

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'نافذة التحضير اليدوي ورصد الأعذار',
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
                  const SizedBox(height: 10),
                  // Search Box
                  TextField(
                    controller: _searchCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الكود الجامعي...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.emerald),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // List of students
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد نتائج مطابقة',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceCardBorder, height: 1),
                            itemBuilder: (context, idx) {
                              final rec = filtered[idx];
                              final isPresent = rec.score > 0;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: isPresent ? AppColors.emerald : AppColors.surfaceCard,
                                  child: Icon(
                                    isPresent ? Icons.check : Icons.person_outline,
                                    color: isPresent ? Colors.white : AppColors.textMuted,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  rec.studentName ?? 'طالب',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  'كود: ${rec.academicId} • ${rec.statusArabic}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPresent ? AppColors.mintAccent : AppColors.textDim,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isPresent) ...[
                                      // Normal Present Button
                                      IconButton(
                                        icon: const Icon(Icons.how_to_reg_rounded, color: AppColors.emerald),
                                        tooltip: 'تحضير يدوي (حاضر)',
                                        onPressed: () async {
                                          await _appState.markManualAttendance(
                                            academicId: rec.academicId,
                                            isExcused: false,
                                          );
                                          setSheetState(() {});
                                        },
                                      ),
                                      // Excused Button
                                      IconButton(
                                        icon: const Icon(Icons.medical_services_outlined, color: AppColors.warningYellow),
                                        tooltip: 'حاضر بعذر مقبول',
                                        onPressed: () async {
                                          await _appState.markManualAttendance(
                                            academicId: rec.academicId,
                                            isExcused: true,
                                            note: 'عذر مقبول (مرضي/إداري)',
                                          );
                                          setSheetState(() {});
                                        },
                                      ),
                                    ] else ...[
                                      // Cancel attendance
                                      IconButton(
                                        icon: const Icon(Icons.undo_rounded, color: AppColors.dangerRed),
                                        tooltip: 'إلغاء التحضير',
                                        onPressed: () async {
                                          await _appState.removeAttendance(rec.academicId);
                                          setSheetState(() {});
                                        },
                                      ),
                                    ],
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

  void _finishSessionAndNavigateToArchive() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('إنهاء جلسة الحضور'),
        content: Text(
          'تم رصد ${_appState.activePresentCount} من إجمالي ${_appState.activeTotalTargetCount} طالباً.\nهل تريد حفظ الجلسة والانتقال للأرشيف لتصدير كشف الإكسيل والـ PDF؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('متابعة المسح'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await _appState.refreshAll();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const Screen6Archive()),
              );
            },
            child: const Text('إنهاء وحفظ الجلسة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _appState.activeSession;
    final course = _appState.activeCourse;
    final presentCount = _appState.activePresentCount;
    final totalCount = _appState.activeTotalTargetCount;
    final percentage = totalCount > 0 ? ((presentCount / totalCount) * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withOpacity(0.95),
        title: Column(
          children: [
            Text(
              course?.courseName ?? 'جلسة الحضور',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${session?.sessionTypeArabic ?? ''} • ${session?.location ?? 'الكل'}',
              style: const TextStyle(fontSize: 11, color: AppColors.mintAccent),
            ),
          ],
        ),
        actions: [
          // Torch Button (زر الفلاش للإنارة بالمدرجات المظلمة)
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFBBF24) : AppColors.textLight,
            ),
            tooltip: 'كشاف الإضاءة (Torch)',
            onPressed: _toggleTorch,
          ),
          // Manual attendance sheet
          IconButton(
            icon: const Icon(Icons.manage_search_rounded, color: AppColors.mintAccent),
            tooltip: 'التحضير اليدوي والأعذار',
            onPressed: _showManualAttendanceSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Live Camera Feed (or fallback simulator)
          Positioned.fill(
            child: _buildCameraFeed(),
          ),

          // 2. Optical Scanning Viewfinder Reticle & Guidelines
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.emerald.withOpacity(0.85),
                      width: 2.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 4 Green QR corner markers
                      Positioned(top: 0, left: 0, child: _corner(true, true)),
                      Positioned(top: 0, right: 0, child: _corner(false, true)),
                      Positioned(bottom: 0, left: 0, child: _corner(true, false)),
                      Positioned(bottom: 0, right: 0, child: _corner(false, false)),
                      // Center guideline hint
                      Center(
                        child: Text(
                          'وجّه الكاميرا نحو باركود أو QR الكارنيه',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Audio/Visual/Haptic Instant Response Overlay
          ScanFeedbackOverlay(result: _appState.lastScanResult),

          // 4. Live Counter Bar (شريط العداد اللحظي)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceCardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: AppColors.mintAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'الحضور: $presentCount / $totalCount',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.royalDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.emerald.withOpacity(0.5)),
                        ),
                        child: Text(
                          '%$percentage',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? (presentCount / totalCount).clamp(0.0, 1.0) : 0.0,
                      backgroundColor: AppColors.surfaceCard,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            ),
          ),


          // 6. Bottom Finish & Save Bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _finishSessionAndNavigateToArchive,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'إنهاء وحفظ الجلسة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceCardBorder),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.person_search_rounded, color: AppColors.mintAccent),
                    tooltip: 'التحضير اليدوي',
                    onPressed: _showManualAttendanceSheet,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeed() {
    if (_scannerController != null) {
      return MobileScanner(
        controller: _scannerController!,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final rawValue = barcode.rawValue;
            if (rawValue != null && rawValue.trim().isNotEmpty) {
              _handleBarcodeDetected(rawValue.trim());
              break;
            }
          }
        },
        errorBuilder: (context, error) {
          return _cameraFallbackView('الكاميرا غير مفعلة أو قيد الاستخدام في تطبيق آخر');
        },
      );
    }
    return _cameraFallbackView('جاري تهيئة عدسة المسح الضوئي...');
  }

  Widget _cameraFallbackView(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 54, color: AppColors.textDim),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'يمكنك استخدام نافذة التحضير اليدوي والأعذار بالأعلى للبحث والرصد',
              style: TextStyle(color: AppColors.mintAccent, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(bool left, bool top) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.mintAccent, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.mintAccent, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.mintAccent, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.mintAccent, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
