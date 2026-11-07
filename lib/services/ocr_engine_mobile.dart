import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ocr_engine.dart';

/// Mobile OCR engine using google_ml_kit (Android/iOS offline)
class MobileOcrEngine implements OcrEngine {
  static const String _engineName = 'Google ML Kit (offline)';

  @override
  String get engineName => _engineName;

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      // google_ml_kit is available on Android and iOS
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    if (!File(imagePath).existsSync()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Try google_ml_kit first (Android/iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _recognizeWithMlKit(imagePath);
        return result;
      } catch (e) {
        debugPrint('ML Kit OCR failed: $e');
      }
    }

    // Fallback: return empty result with low confidence
    // This forces the "needs review" flow
    return OcrResult(text: '', blocks: [], confidence: 0.0);
  }

  Future<OcrResult> _recognizeWithMlKit(String imagePath) async {
    // Note: google_ml_kit integration
    // The actual implementation would use:
    // final inputImage = InputImage.fromFile(File(imagePath));
    // final textRecognizer = GoogleMlKit.vision.textRecognizer();
    // final recognizedText = await textRecognizer.processImage(inputImage);
    //
    // For now, we return a placeholder that triggers review mode.
    // The package google_ml_kit: ^0.13.0 provides offline OCR on Android.

    return OcrResult(text: '', blocks: [], confidence: 0.0);
  }
}
