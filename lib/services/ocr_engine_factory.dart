import 'ocr_engine.dart';
import 'ocr_engine_selector_io.dart'
    if (dart.library.js_interop) 'ocr_engine_selector_web.dart';

/// Factory to create the appropriate OCR engine for the current platform.
///
/// The platform switch lives behind a conditional import so the `dart:io`
/// based engines (Google ML Kit on Android/iOS, Windows OCR) are excluded
/// from the web bundle entirely.
class OcrEngineFactory {
  static OcrEngine create() => createOcrEngine();
}
