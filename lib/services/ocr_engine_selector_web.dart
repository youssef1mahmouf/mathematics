import 'ocr_engine.dart';
import 'ocr_engine_web.dart';

/// Builds the OCR engine for the browser.
///
/// Google ML Kit has no web implementation, so the browser always gets the
/// web engine, which reports itself as unavailable and lets the UI fall back
/// to manual review.
OcrEngine createOcrEngine() => WebOcrEngine();