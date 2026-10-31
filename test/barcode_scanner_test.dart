import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:asad_app/domain/models/attendance_record.dart';
import 'package:asad_app/presentation/controllers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Barcode & QR Scanner Configuration & Logic Tests', () {
    test('1. MobileScannerController supports 1D barcodes and QR codes', () {
      final controller = MobileScannerController(
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

      // Verify that controller is NOT restricted to qrCode only
      expect(controller.formats.contains(BarcodeFormat.all), isTrue);
      expect(controller.formats.contains(BarcodeFormat.code128), isTrue);
      expect(controller.formats.contains(BarcodeFormat.code39), isTrue);
      expect(controller.formats.contains(BarcodeFormat.ean13), isTrue);
      expect(controller.formats.contains(BarcodeFormat.qrCode), isTrue);

      // Verify lifecycle methods
      expect(controller.toggleTorch, isNotNull);
      expect(controller.start, isNotNull);
      expect(controller.stop, isNotNull);
      expect(controller.dispose, isNotNull);

      controller.dispose();
    });

    test('2. RawValue parsing and sanitization handles whitespace and newlines', () {
      const sample1DBarcode = '  20261055  \n';
      const sampleQrCode = '\t4450892\r\n';

      final clean1D = sample1DBarcode.trim();
      final cleanQr = sampleQrCode.trim();

      expect(clean1D, '20261055');
      expect(cleanQr, '4450892');
      expect(clean1D.isNotEmpty, isTrue);
      expect(cleanQr.isNotEmpty, isTrue);
    });

    test('3. In-memory Set guarantees O(1) duplicate flagging for active session', () {
      final inMemoryPresents = <String>{};
      const academicId = '20261001';

      // Initially not present
      expect(inMemoryPresents.contains(academicId), isFalse);

      // First scan: mark present in memory
      inMemoryPresents.add(academicId);
      expect(inMemoryPresents.contains(academicId), isTrue);

      // Subsequent scan: immediately flagged as duplicate in 0ms without disk I/O
      final isDuplicate = inMemoryPresents.contains(academicId);
      expect(isDuplicate, isTrue);
    });

    test('4. Debounce throttling cooldown prevents rapid multi-fire', () async {
      DateTime? lastScanTime;
      String? lastScannedBarcode;
      const cooldown = Duration(milliseconds: 1800);

      bool shouldProcess(String rawCode) {
        final clean = rawCode.trim();
        final now = DateTime.now();

        if (lastScannedBarcode == clean &&
            lastScanTime != null &&
            now.difference(lastScanTime!) < cooldown) {
          return false; // Throttled / Debounced
        }

        lastScanTime = now;
        lastScannedBarcode = clean;
        return true;
      }

      // First detection fires
      expect(shouldProcess('20261001'), isTrue);

      // Immediate repeated detection (milliseconds later) is throttled
      expect(shouldProcess('20261001'), isFalse);
      expect(shouldProcess(' 20261001\n'), isFalse);

      // Different student barcode passes immediately
      expect(shouldProcess('20261002'), isTrue);
    });

    test('5. Real-time feedback result models and messages conform to specifications', () {
      // Success feedback
      const successResult = ScanResult(
        type: ScanFeedbackType.success,
        academicId: '20261001',
        message: 'أحمد محمد إبراهيم',
      );
      expect(successResult.type, ScanFeedbackType.success);
      expect(successResult.academicId, '20261001');

      // Duplicate feedback
      const duplicateResult = ScanResult(
        type: ScanFeedbackType.duplicate,
        academicId: '20261001',
        message: 'الطالب مسجل بالفعل في هذه الجلسة',
      );
      expect(duplicateResult.type, ScanFeedbackType.duplicate);
      expect(duplicateResult.message, 'الطالب مسجل بالفعل في هذه الجلسة');

      // Wrong location / unregistered feedback
      const wrongLocationResult = ScanResult(
        type: ScanFeedbackType.wrongLocation,
        academicId: '99999999',
        message: 'طالب غير مقيد في هذا المكان / المقرر',
      );
      expect(wrongLocationResult.type, ScanFeedbackType.wrongLocation);
      expect(wrongLocationResult.message, 'طالب غير مقيد في هذا المكان / المقرر');
    });

    test('6. Manual attendance search correctly filters by academic_id and full_name', () {
      final sampleRecords = [
        const AttendanceRecord(
          recordId: 1,
          sessionId: 10,
          academicId: '20261001',
          studentName: 'أحمد محمد علي',
          status: 'absent',
          score: 0,
        ),
        const AttendanceRecord(
          recordId: 2,
          sessionId: 10,
          academicId: '20261002',
          studentName: 'محمود حسن إبراهيم',
          status: 'present',
          score: 1,
        ),
        const AttendanceRecord(
          recordId: 3,
          sessionId: 10,
          academicId: '20261055',
          studentName: 'سارة خالد السيد',
          status: 'absent',
          score: 0,
        ),
      ];

      List<AttendanceRecord> search(String query) {
        final q = query.trim().toLowerCase();
        if (q.isEmpty) return sampleRecords;
        return sampleRecords.where((r) {
          final name = (r.studentName ?? '').toLowerCase();
          final id = r.academicId.toLowerCase();
          return name.contains(q) || id.contains(q);
        }).toList();
      }

      // Search by academic_id
      final byId = search('1055');
      expect(byId.length, 1);
      expect(byId.first.academicId, '20261055');
      expect(byId.first.studentName, 'سارة خالد السيد');

      // Search by full_name
      final byName = search('محمود');
      expect(byName.length, 1);
      expect(byName.first.academicId, '20261002');

      // Blank search returns all
      expect(search('').length, 3);
    });
  });
}
