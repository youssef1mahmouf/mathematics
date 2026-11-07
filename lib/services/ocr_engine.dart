/// Result of OCR text recognition from an image
class OcrResult {
  final String text;
  final List<OcrTextBlock> blocks;
  final double confidence; // 0.0 to 1.0

  OcrResult({required this.text, required this.blocks, this.confidence = 0.0});
}

/// A text block detected by OCR with bounding box
class OcrTextBlock {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;

  OcrTextBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.confidence = 0.0,
  });
}

/// Abstract OCR engine interface - can be swapped for different platforms
abstract class OcrEngine {
  /// Recognize text from an image file
  Future<OcrResult> recognizeText(String imagePath);

  /// Whether this engine is available on the current platform
  Future<bool> isAvailable();

  /// Engine name for display
  String get engineName;
}
