import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ocr_engine.dart';
import 'ocr_engine_mobile.dart';
import 'ocr_engine_web.dart';
import 'ocr_engine_windows.dart';

/// Builds the OCR engine that matches the current native platform.
///
/// This file is only ever compiled on platforms with `dart:io`
/// (see `ocr_engine_factory.dart`), so the Google ML Kit / Windows engines
/// never reach the web bundle.
OcrEngine createOcrEngine() {
  if (kIsWeb) return WebOcrEngine();
  if (Platform.isWindows) return WindowsOcrEngine();
  if (Platform.isAndroid || Platform.isIOS) return MobileOcrEngine();
  // Fallback
  return WebOcrEngine();
}