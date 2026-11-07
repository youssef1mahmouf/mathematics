enum AttendanceStatus { present, absent, needsReview, excused }

class AttendanceRecord {
  final String? id;
  final String sessionId;
  final String studentId; // References Student.studentId
  final String studentName; // Denormalized for display
  final String? studentGroup;
  final AttendanceStatus status;
  final DateTime? checkInTime; // Auto-detected or manually set
  final bool timeManuallyEdited;
  final DateTime? timeEditedAt;
  final String? matchedBy; // 'name', 'id', 'group', 'manual'
  final double matchConfidence; // 0.0 to 1.0
  final bool needsReview; // Flag for uncertain matches
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    this.studentGroup,
    required this.status,
    this.checkInTime,
    this.timeManuallyEdited = false,
    this.timeEditedAt,
    this.matchedBy,
    this.matchConfidence = 0.0,
    this.needsReview = false,
    this.reviewNotes,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'student_name': studentName,
      'student_group': studentGroup,
      'status': status.index,
      'check_in_time': checkInTime?.toIso8601String(),
      'time_manually_edited': timeManuallyEdited ? 1 : 0,
      'time_edited_at': timeEditedAt?.toIso8601String(),
      'matched_by': matchedBy,
      'match_confidence': matchConfidence,
      'needs_review': needsReview ? 1 : 0,
      'review_notes': reviewNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String?,
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String,
      studentGroup: map['student_group'] as String?,
      status: AttendanceStatus.values[(map['status'] as int? ?? 0)],
      checkInTime: map['check_in_time'] != null
          ? DateTime.parse(map['check_in_time'] as String)
          : null,
      timeManuallyEdited: (map['time_manually_edited'] as int? ?? 0) == 1,
      timeEditedAt: map['time_edited_at'] != null
          ? DateTime.parse(map['time_edited_at'] as String)
          : null,
      matchedBy: map['matched_by'] as String?,
      matchConfidence: (map['match_confidence'] as num? ?? 0.0).toDouble(),
      needsReview: (map['needs_review'] as int? ?? 0) == 1,
      reviewNotes: map['review_notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? studentName,
    String? studentGroup,
    AttendanceStatus? status,
    DateTime? checkInTime,
    bool? timeManuallyEdited,
    DateTime? timeEditedAt,
    String? matchedBy,
    double? matchConfidence,
    bool? needsReview,
    String? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentGroup: studentGroup ?? this.studentGroup,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      timeManuallyEdited: timeManuallyEdited ?? this.timeManuallyEdited,
      timeEditedAt: timeEditedAt ?? this.timeEditedAt,
      matchedBy: matchedBy ?? this.matchedBy,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      needsReview: needsReview ?? this.needsReview,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AttendanceRecord(student: $studentName, status: $status, needsReview: $needsReview)';
  }
}
