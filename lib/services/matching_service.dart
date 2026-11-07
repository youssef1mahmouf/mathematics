import '../models/student.dart';
import '../models/attendance_record.dart';

import 'package:collection/collection.dart';

/// Result of matching a name from attendance image to a student
class MatchResult {
  final Student? student;
  final double confidence; // 0.0 to 1.0
  final String matchType; // 'exact_id', 'exact_name', 'fuzzy_name', 'none'
  final bool needsReview;

  MatchResult({
    this.student,
    required this.confidence,
    required this.matchType,
    required this.needsReview,
  });
}

/// Service for matching OCR text to students in the database
class MatchingService {
  /// Match a detected name to a student
  static MatchResult matchStudent({
    required String detectedName,
    required String? detectedId,
    required String? detectedGroup,
    required List<Student> availableStudents,
  }) {
    // 1. Try exact student ID match
    if (detectedId != null && detectedId.isNotEmpty) {
      final exactIdMatch = availableStudents.firstWhereOrNull(
        (s) => s.normalizedStudentId == detectedId.trim(),
      );
      if (exactIdMatch != null) {
        return MatchResult(
          student: exactIdMatch,
          confidence: 1.0,
          matchType: 'exact_id',
          needsReview: false,
        );
      }
    }

    // 2. Try exact name match (normalized)
    final normalizedDetected = _normalize(detectedName);
    if (normalizedDetected.isNotEmpty) {
      final exactNameMatch = availableStudents.firstWhereOrNull(
        (s) => s.normalizedName == normalizedDetected,
      );
      if (exactNameMatch != null) {
        // If we also have a group, verify it matches
        if (detectedGroup != null && detectedGroup.isNotEmpty) {
          if (exactNameMatch.group == detectedGroup) {
            return MatchResult(
              student: exactNameMatch,
              confidence: 0.95,
              matchType: 'exact_name',
              needsReview: false,
            );
          }
        } else {
          return MatchResult(
            student: exactNameMatch,
            confidence: 0.9,
            matchType: 'exact_name',
            needsReview: false,
          );
        }
      }
    }

    // 3. Try fuzzy name match (contains)
    if (normalizedDetected.isNotEmpty) {
      final fuzzyMatches = availableStudents.where((s) {
        final sName = s.normalizedName;
        return sName.contains(normalizedDetected) ||
            normalizedDetected.contains(sName);
      }).toList();

      if (fuzzyMatches.length == 1) {
        return MatchResult(
          student: fuzzyMatches.first,
          confidence: 0.7,
          matchType: 'fuzzy_name',
          needsReview: true,
        );
      }

      if (fuzzyMatches.length > 1) {
        return MatchResult(
          student: fuzzyMatches.first,
          confidence: 0.5,
          matchType: 'fuzzy_name',
          needsReview: true,
        );
      }
    }

    // 4. No match found
    return MatchResult(
      student: null,
      confidence: 0.0,
      matchType: 'none',
      needsReview: true,
    );
  }

  /// Create an attendance record from a match result
  static AttendanceRecord createRecordFromMatch({
    required String sessionId,
    required MatchResult match,
    required String detectedName,
    required String? detectedId,
    DateTime? checkInTime,
  }) {
    if (match.student != null && !match.needsReview) {
      return AttendanceRecord(
        sessionId: sessionId,
        studentId: match.student!.studentId,
        studentName: match.student!.name,
        studentGroup: match.student!.group,
        status: AttendanceStatus.present,
        checkInTime: checkInTime,
        matchedBy: match.matchType,
        matchConfidence: match.confidence,
        needsReview: false,
      );
    } else if (match.student != null && match.needsReview) {
      return AttendanceRecord(
        sessionId: sessionId,
        studentId: match.student!.studentId,
        studentName: match.student!.name,
        studentGroup: match.student!.group,
        status: AttendanceStatus.needsReview,
        checkInTime: checkInTime,
        matchedBy: match.matchType,
        matchConfidence: match.confidence,
        needsReview: true,
      );
    } else {
      // No match - create record with empty fields for manual entry
      return AttendanceRecord(
        sessionId: sessionId,
        studentId: detectedId ?? '',
        studentName: detectedName,
        studentGroup: detectedGroupFromName(detectedName),
        status: AttendanceStatus.needsReview,
        checkInTime: checkInTime,
        matchedBy: 'none',
        matchConfidence: 0.0,
        needsReview: true,
      );
    }
  }

  static String? detectedGroupFromName(String name) {
    // Try to extract group from name pattern like "GA-1" or "GB-3"
    final groupRegex = RegExp(r'(GA|GB)\s*[-]?\s*\d+');
    final match = groupRegex.firstMatch(name);
    return match?.group(0);
  }

  static String _normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\u0621-\u064A]'), '');
  }
}
