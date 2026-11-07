import '../models/session.dart';
import '../models/attendance_record.dart';
import '../database/app_database.dart';

/// Service for managing attendance sessions
class SessionService {
  final AppDatabase _db = AppDatabase();

  /// Create a new session
  Future<String> createSession({
    required String name,
    required String subject,
    required String group,
    required DateTime date,
  }) async {
    // Check for duplicate session (same subject, group, date)
    final existing = await _db.getSessions(
      subjectFilter: subject,
      groupFilter: group,
      fromDate: DateTime(date.year, date.month, date.day),
      toDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
    );

    if (existing.isNotEmpty) {
      throw Exception('يوجد جلسة بالفعل لهذه المادة والمجموعة في هذا التاريخ');
    }

    final session = Session(
      name: name,
      subject: subject,
      group: group,
      date: date,
      status: SessionStatus.active,
    );

    final id = await _db.insertSession(session);
    return id;
  }

  /// Get all sessions with optional filters
  Future<List<Session>> getSessions({
    String? subjectFilter,
    String? groupFilter,
    DateTime? fromDate,
    DateTime? toDate,
    int? statusFilter,
  }) async {
    return await _db.getSessions(
      subjectFilter: subjectFilter,
      groupFilter: groupFilter,
      fromDate: fromDate,
      toDate: toDate,
      statusFilter: statusFilter,
    );
  }

  /// Get session by ID
  Future<Session?> getSession(String id) async {
    return await _db.getSessionById(id);
  }

  /// Update a session
  Future<void> updateSession(Session session) async {
    await _db.updateSession(session);
  }

  /// Cancel a session
  Future<void> cancelSession(String id) async {
    final session = await _db.getSessionById(id);
    if (session != null) {
      await _db.updateSession(
        session.copyWith(status: SessionStatus.cancelled),
      );
    }
  }

  /// Delete a session (only if no attendance records exist)
  Future<bool> deleteSession(String id) async {
    final hasAttendance = await _db.sessionHasAttendance(id);
    if (hasAttendance) {
      return false; // Cannot delete session with attendance
    }
    await _db.deleteSession(id);
    return true;
  }

  /// Mark session as completed
  Future<void> completeSession(String id) async {
    final session = await _db.getSessionById(id);
    if (session != null) {
      await _db.updateSession(
        session.copyWith(status: SessionStatus.completed),
      );
    }
  }

  /// Save attendance records for a session
  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    for (final record in records) {
      await _db.insertAttendanceRecord(record);
    }
  }

  /// Get attendance records for a session
  Future<List<AttendanceRecord>> getAttendance(String sessionId) async {
    return await _db.getAttendanceBySession(sessionId);
  }

  /// Update a single attendance record
  Future<void> updateAttendance(AttendanceRecord record) async {
    await _db.updateAttendanceRecord(record);
  }

  /// Get attendance summary for a session
  Future<Map<String, int>> getAttendanceSummary(String sessionId) async {
    return await _db.getAttendanceSummary(sessionId);
  }

  /// Get distinct subjects from sessions
  Future<List<String>> getDistinctSubjects() async {
    final sessions = await _db.getSessions();
    final subjects = sessions.map((s) => s.subject).toSet().toList();
    subjects.sort();
    return subjects;
  }

  /// Get distinct groups from sessions
  Future<List<String>> getDistinctGroups() async {
    final sessions = await _db.getSessions();
    final groups = sessions.map((s) => s.group).toSet().toList();
    groups.sort();
    return groups;
  }
}
