import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/student.dart';
import '../models/session.dart';
import '../models/attendance_record.dart';

import 'database_setup.dart';

const _uuid = Uuid();

class AppDatabase {
  static Database? _db;
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // Installs the right sqflite factory first (`sqflite_common_ffi_web` in
    // the browser, no-op on Android/iOS where the plugin registers itself),
    // then resolves the database location: a real file path on native
    // platforms, a plain database name on the web (persisted in IndexedDB).
    await initDatabaseFactory();
    final dbPath = await databaseFilePath('attendance.db');
    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        name TEXT NOT NULL,
        group_name TEXT,
        source_file TEXT NOT NULL,
        source_list TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        UNIQUE(student_id, source_list)
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        subject TEXT NOT NULL,
        group_name TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        student_group TEXT,
        status INTEGER NOT NULL DEFAULT 2,
        check_in_time TEXT,
        time_manually_edited INTEGER NOT NULL DEFAULT 0,
        time_edited_at TEXT,
        matched_by TEXT,
        match_confidence REAL NOT NULL DEFAULT 0,
        needs_review INTEGER NOT NULL DEFAULT 0,
        review_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_attendance_session ON attendance_records(session_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_attendance_student ON attendance_records(student_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_students_student_id ON students(student_id)
    ''');
  }

  // ---- Students ----
  Future<int> insertStudent(Student student) async {
    final database = await db;
    final record = student.id == null
        ? student.copyWith(id: _uuid.v4())
        : student;
    return await database.insert(
      'students',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Student>> getStudents({
    String? groupFilter,
    String? searchQuery,
  }) async {
    final database = await db;
    var where = 'status = 0';
    var args = <dynamic>[];

    if (groupFilter != null && groupFilter.isNotEmpty) {
      where += ' AND group_name = ?';
      args.add(groupFilter);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where += ' AND (name LIKE ? OR student_id LIKE ?)';
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }

    final maps = await database.query(
      'students',
      where: where,
      whereArgs: args,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<Student?> getStudentById(String studentId) async {
    final database = await db;
    final maps = await database.query(
      'students',
      where: 'student_id = ? AND status = 0',
      whereArgs: [studentId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  Future<List<Student>> getStudentsByGroup(String group) async {
    return getStudents(groupFilter: group);
  }

  Future<int> getStudentCount() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as cnt FROM students WHERE status = 0',
    );
    return (result.first['cnt'] as int);
  }

  Future<bool> studentExists(String studentId, String sourceList) async {
    final database = await db;
    final maps = await database.query(
      'students',
      where: 'student_id = ? AND source_list = ? AND status = 0',
      whereArgs: [studentId, sourceList],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<List<Student>> findPotentialDuplicates(Student student) async {
    final database = await db;
    final maps = await database.query(
      'students',
      where: '(student_id = ? OR name = ?) AND status = 0 AND source_list != ?',
      whereArgs: [student.studentId, student.name, student.sourceList],
    );
    return maps.map((m) => Student.fromMap(m)).toList();
  }

  Future<int> deleteStudent(String id) async {
    final database = await db;
    return await database.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Sessions ----
  /// Inserts a session and returns its generated string id.
  Future<String> insertSession(Session session) async {
    final database = await db;
    final record = session.id == null
        ? session.copyWith(id: _uuid.v4())
        : session;
    await database.insert(
      'sessions',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return record.id!;
  }

  Future<List<Session>> getSessions({
    String? subjectFilter,
    String? groupFilter,
    DateTime? fromDate,
    DateTime? toDate,
    int? statusFilter,
  }) async {
    final database = await db;
    var where = '1 = 1';
    var args = <dynamic>[];

    if (subjectFilter != null && subjectFilter.isNotEmpty) {
      where += ' AND subject = ?';
      args.add(subjectFilter);
    }
    if (groupFilter != null && groupFilter.isNotEmpty) {
      where += ' AND group_name = ?';
      args.add(groupFilter);
    }
    if (fromDate != null) {
      where += ' AND date >= ?';
      args.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      where += ' AND date <= ?';
      args.add(toDate.toIso8601String());
    }
    if (statusFilter != null) {
      where += ' AND status = ?';
      args.add(statusFilter);
    }

    final maps = await database.query(
      'sessions',
      where: where,
      whereArgs: args,
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => Session.fromMap(m)).toList();
  }

  Future<Session?> getSessionById(String id) async {
    final database = await db;
    final maps = await database.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  Future<int> updateSession(Session session) async {
    final database = await db;
    return await database.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(String id) async {
    final database = await db;
    await database.delete(
      'attendance_records',
      where: 'session_id = ?',
      whereArgs: [id],
    );
    return await database.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> sessionHasAttendance(String sessionId) async {
    final database = await db;
    final maps = await database.query(
      'attendance_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // ---- Attendance Records ----
  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    final database = await db;
    final row = record.id == null ? record.copyWith(id: _uuid.v4()) : record;
    return await database.insert(
      'attendance_records',
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceBySession(
    String sessionId,
  ) async {
    final database = await db;
    final maps = await database.query(
      'attendance_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'student_name ASC',
    );
    return maps.map((m) => AttendanceRecord.fromMap(m)).toList();
  }

  Future<AttendanceRecord?> getAttendanceRecord(String id) async {
    final database = await db;
    final maps = await database.query(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AttendanceRecord.fromMap(maps.first);
  }

  Future<int> updateAttendanceRecord(AttendanceRecord record) async {
    final database = await db;
    return await database.update(
      'attendance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<Map<String, int>> getAttendanceSummary(String sessionId) async {
    final records = await getAttendanceBySession(sessionId);
    var present = 0, absent = 0, needsReview = 0;
    for (final r in records) {
      switch (r.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.absent:
          absent++;
        case AttendanceStatus.needsReview:
          needsReview++;
        case AttendanceStatus.excused:
          break;
      }
    }
    return {'present': present, 'absent': absent, 'needsReview': needsReview};
  }

  Future<int> deleteAttendanceRecord(String id) async {
    final database = await db;
    return await database.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllAttendanceForSession(String sessionId) async {
    final database = await db;
    return await database.delete(
      'attendance_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> close() async {
    final database = await db;
    await database.close();
    _db = null;
  }
}
