import 'dart:io';

import 'ocr_engine.dart';

/// Windows OCR engine - placeholder for Windows OCR API integration
/// Falls back to manual review when native OCR is not available
class WindowsOcrEngine implements OcrEngine {
  static const String _engineName = 'Windows OCR (native)';

  @override
  String get engineName => _engineName;

  @override
  Future<bool> isAvailable() async {
    return Platform.isWindows;
  }

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    if (!File(imagePath).existsSync()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Windows OCR API integration would go here using Win32 FFI
    // or the Windows.Media.Ocr namespace via interop.
    //
    // For now, return empty result to trigger safe "needs review" flow.
    return OcrResult(text: '', blocks: [], confidence: 0.0);
  }
}
