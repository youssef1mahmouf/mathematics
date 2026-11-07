import 'ocr_engine.dart';

/// Web OCR engine.
///
/// Google ML Kit (the OCR used on Android/iOS) has **no web implementation**,
/// so the browser cannot run on-device OCR today. Rather than pretending to
/// work, this engine reports itself as unavailable: the attendance screen
/// then shows its explicit "unsupported on this platform" message and the
/// operator falls back to manual review.
class WebOcrEngine implements OcrEngine {
  static const String _engineName = 'OCR عبر المتصفح (غير متاح)';

  @override
  String get engineName => _engineName;

  @override
  Future<bool> isAvailable() async {
    // No browser OCR engine is bundled; see the class documentation.
    return false;
  }

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    // Kept as a safe empty result so any caller still following the
    // "needs review" flow behaves as before instead of crashing.
    return OcrResult(text: '', blocks: [], confidence: 0.0);
  }
}
