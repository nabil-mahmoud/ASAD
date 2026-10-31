import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  test('Inspect BarcodeFormat and MobileScannerController', () {
    print('BarcodeFormat values: ${BarcodeFormat.values}');
    final controller = MobileScannerController(
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
      ],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    print('Controller created: $controller, formats: ${controller.formats}');
    controller.dispose();
  });
}
