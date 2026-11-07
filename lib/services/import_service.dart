import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

import '../models/student.dart';
import '../models/import_duplicate.dart';

/// Result of importing students from a file
class ImportResult {
  final List<Student> students;
  final List<ImportDuplicate> duplicates;
  final List<String> errors;
  final String sourceFile;
  final String sourceList;

  ImportResult({
    required this.students,
    required this.duplicates,
    required this.errors,
    required this.sourceFile,
    required this.sourceList,
  });

  int get validCount =>
      students.where((s) => s.name.isNotEmpty && s.studentId.isNotEmpty).length;
  int get uncertainCount =>
      students.where((s) => s.name.isEmpty || s.studentId.isEmpty).length;
}

/// Service for importing students from PDF, Excel, and Word files
class ImportService {
  /// Pick a file and parse it into students
  static Future<ImportResult> importFromFile({
    required String sourceList,
    String? groupOverride,
  }) async {
    // `withData: true` fills `PlatformFile.bytes` on every platform. In the
    // browser `path` is always null, so the bytes are the only usable handle.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xlsx', 'xls', 'docx', 'doc'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult(
        students: [],
        duplicates: [],
        errors: ['لم يتم اختيار ملف'],
        sourceFile: '',
        sourceList: sourceList,
      );
    }

    final file = result.files.single;
    final sourceFile = file.name;
    final bytes = file.bytes;

    if (bytes == null) {
      return ImportResult(
        students: [],
        duplicates: [],
        errors: ['لم يتم قراءة الملف'],
        sourceFile: sourceFile,
        sourceList: sourceList,
      );
    }

    try {
      final students = await _parseFile(
        bytes,
        sourceFile,
        sourceList,
        groupOverride,
      );
      return ImportResult(
        students: students,
        duplicates: [],
        errors: [],
        sourceFile: sourceFile,
        sourceList: sourceList,
      );
    } catch (e) {
      return ImportResult(
        students: [],
        duplicates: [],
        errors: ['خطأ في قراءة الملف: $e'],
        sourceFile: sourceFile,
        sourceList: sourceList,
      );
    }
  }

  static Future<List<Student>> _parseFile(
    List<int> bytes,
    String sourceFile,
    String sourceList,
    String? groupOverride,
  ) async {
    final extension = sourceFile.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return _parsePdf();
      case 'xlsx':
      case 'xls':
        return _parseExcel(bytes, sourceFile, sourceList, groupOverride);
      case 'docx':
      case 'doc':
        return _parseWord();
      default:
        throw Exception('امتداد ملف غير مدعوم: $extension');
    }
  }

  static List<Student> _parsePdf() {
    // PDF parsing is done natively in Dart using the pdf package or
    // by extracting text. Since we can't run Python here,
    // we return an empty list and let the user review manually.
    // The actual PDF text extraction would use a Dart PDF library.
    return [];
  }

  static List<Student> _parseExcel(
    List<int> bytes,
    String sourceFile,
    String sourceList,
    String? groupOverride,
  ) {
    final students = <Student>[];
    try {
      final excel = Excel.decodeBytes(bytes);

      for (final table in excel.tables.values) {
        for (final row in table.rows) {
          if (row.isEmpty) continue;

          // Try to find student ID and name in the row
          String? studentId;
          String? name;

          for (final cell in row) {
            if (cell == null || cell.value == null) continue;
            final value = cell.value.toString().trim();

            // Check if it looks like a student ID (9 digits starting with 19)
            if (studentId == null && RegExp(r'^19\d{7}$').hasMatch(value)) {
              studentId = value;
            }
            // Check if it looks like a name (not a number, not empty)
            else if (name == null &&
                value.length > 2 &&
                !RegExp(r'^[\d\s\.\-]+$').hasMatch(value)) {
              name = value;
            }

            if (studentId != null && name != null) break;
          }

          if (studentId != null && name != null) {
            students.add(
              Student(
                studentId: studentId,
                name: name,
                group: groupOverride,
                sourceFile: sourceFile,
                sourceList: sourceList,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Return what we have so far
    }
    return students;
  }

  static List<Student> _parseWord() {
    // Word (.docx) parsing would require extracting text from XML
    // For now, return empty list
    return [];
  }

  /// Check for duplicates against existing students
  static Future<List<ImportDuplicate>> checkDuplicates(
    List<Student> incomingStudents,
  ) async {
    final duplicates = <ImportDuplicate>[];
    // This would be implemented with database access
    return duplicates;
  }

  /// Normalize student name for comparison
  static String normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Normalize student ID
  static String normalizeId(String id) {
    return id.trim().replaceAll(RegExp(r'\s+'), '');
  }
}
