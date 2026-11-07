import 'dart:convert';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../platform/platform_files.dart';
import '../models/student.dart';
import '../models/session.dart';

/// Backup metadata
class BackupInfo {
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int studentCount;
  final int sessionCount;
  final int attendanceCount;

  BackupInfo({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.studentCount,
    required this.sessionCount,
    required this.attendanceCount,
  });
}

/// Service for backup and restore of local data
class BackupService {
  final AppDatabase _db = AppDatabase();

  /// Get the backup directory based on platform.
  ///
  /// Native: `%APPDATA%/ECU Attendance/backups` (or `<documents>/backups`).
  /// Web: a virtual bucket stored in `localStorage`.
  Future<String> _getBackupDirectory() => appFolderPath('backups');

  /// Create a backup file (JSON format)
  Future<BackupInfo> createBackup({String? customPath}) async {
    final students = await _db.getStudents();
    final sessions = await _db.getSessions();

    // Get attendance count
    int attendanceCount = 0;
    for (final session in sessions) {
      final records = await _db.getAttendanceBySession(session.id!);
      attendanceCount += records.length;
    }

    final backupData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'students': students.map((s) => s.toMap()).toList(),
      'sessions': sessions.map((s) => s.toMap()).toList(),
    };

    final jsonString = jsonEncode(backupData);
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final fileName = 'attendance_backup_$timestamp.json';

    String filePath;
    if (customPath != null && customPath.isNotEmpty) {
      filePath = customPath;
    } else {
      filePath = p.join(await _getBackupDirectory(), fileName);
    }

    // Native: writes a real .json file. Web: stores it in the browser vault
    // and offers it to the user as a download.
    await saveTextDocument(filePath, jsonString, mimeType: 'application/json');

    return BackupInfo(
      filePath: filePath,
      fileName: fileName,
      createdAt: DateTime.now(),
      studentCount: students.length,
      sessionCount: sessions.length,
      attendanceCount: attendanceCount,
    );
  }

  /// Restore from a backup file
  Future<void> restoreFromBackup(String filePath) async {
    if (!await fileExists(filePath)) {
      throw Exception('ملف النسخة الاحتياطية غير موجود');
    }

    final jsonString = await readTextFile(filePath);
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    // Clear existing data (for simplicity - in production, ask user)
    // Note: We don't delete existing data to avoid accidental loss.
    // Instead, we import with conflict resolution.

    final studentsList = data['students'] as List? ?? [];
    final sessionsList = data['sessions'] as List? ?? [];

    for (final studentMap in studentsList) {
      final student = Student.fromMap(Map<String, dynamic>.from(studentMap));
      await _db.insertStudent(student);
    }

    for (final sessionMap in sessionsList) {
      final session = Session.fromMap(Map<String, dynamic>.from(sessionMap));
      await _db.insertSession(session);
    }
  }

  /// Get list of available backup files
  Future<List<BackupInfo>> getBackupHistory() async {
    final dir = await _getBackupDirectory();
    final files = await listStoredFiles(dir);
    final backupFiles = files
        .where((f) => f.fileName.endsWith('.json'))
        .toList();

    final history = <BackupInfo>[];
    for (final file in backupFiles) {
      history.add(
        BackupInfo(
          filePath: file.path,
          fileName: file.fileName,
          createdAt: file.modifiedAt,
          studentCount: 0, // Would need to read file to get counts
          sessionCount: 0,
          attendanceCount: 0,
        ),
      );
    }

    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return history;
  }

  /// Delete a backup file
  Future<void> deleteBackup(String filePath) async {
    await deleteStoredFile(filePath);
  }

  /// Share backup file (for manual transfer)
  Future<void> shareBackup(String filePath) async {
    await shareStoredFile(
      filePath,
      mimeType: 'application/json',
      text: 'نسخة احتياطية من بيانات الحضور',
    );
  }

  /// Open backup file
  Future<void> openBackup(String filePath) async {
    await openStoredFile(filePath, mimeType: 'application/json');
  }

  /// Check if a recent backup exists (within last 7 days)
  Future<bool> hasRecentBackup({int days = 7}) async {
    final history = await getBackupHistory();
    if (history.isEmpty) return false;

    final latest = history.first.createdAt;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return latest.isAfter(cutoff);
  }

  /// Get the latest backup info
  Future<BackupInfo?> getLatestBackup() async {
    final history = await getBackupHistory();
    return history.isNotEmpty ? history.first : null;
  }
}
