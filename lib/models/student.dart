enum StudentStatus { active, inactive }

class Student {
  final String? id; // Database internal id
  final String studentId; // University student ID (e.g., 192600001)
  final String name;
  final String? group; // e.g., GA-1, GB-3
  final String sourceFile; // Source file name
  final String sourceList; // e.g., "GA groups", "PEM001 Math"
  final DateTime createdAt;
  final StudentStatus status;

  Student({
    this.id,
    required this.studentId,
    required this.name,
    this.group,
    required this.sourceFile,
    required this.sourceList,
    DateTime? createdAt,
    this.status = StudentStatus.active,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'name': name,
      'group_name': group,
      'source_file': sourceFile,
      'source_list': sourceList,
      'created_at': createdAt.toIso8601String(),
      'status': status.index,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String?,
      studentId: map['student_id'] as String,
      name: map['name'] as String,
      group: (map['group_name'] ?? map['group']) as String?,
      sourceFile: map['source_file'] as String,
      sourceList: map['source_list'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      status: StudentStatus.values[(map['status'] as int? ?? 0)],
    );
  }

  Student copyWith({
    String? id,
    String? studentId,
    String? name,
    String? group,
    String? sourceFile,
    String? sourceList,
    DateTime? createdAt,
    StudentStatus? status,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      group: group ?? this.group,
      sourceFile: sourceFile ?? this.sourceFile,
      sourceList: sourceList ?? this.sourceList,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Normalized name for matching (lowercase, trimmed, remove extra spaces)
  String get normalizedName =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Normalized student ID for matching
  String get normalizedStudentId => studentId.trim();

  @override
  String toString() {
    return 'Student(studentId: $studentId, name: $name, group: $group, source: $sourceList)';
  }
}
