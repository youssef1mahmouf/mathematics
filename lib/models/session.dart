enum SessionStatus { draft, active, completed, cancelled }

class Session {
  final String? id;
  final String name; // e.g., "المحاضرة 1"
  final String subject; // e.g., "رياضيات"
  final String group; // e.g., "GA-1"
  final DateTime date;
  final DateTime createdAt;
  final SessionStatus status;
  final String? imagePath; // Path to attendance image
  final String? notes;

  Session({
    this.id,
    required this.name,
    required this.subject,
    required this.group,
    required this.date,
    DateTime? createdAt,
    this.status = SessionStatus.draft,
    this.imagePath,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'group_name': group,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.index,
      'image_path': imagePath,
      'notes': notes,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String?,
      name: map['name'] as String,
      subject: map['subject'] as String,
      group: (map['group_name'] ?? map['group']) as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      status: SessionStatus.values[(map['status'] as int? ?? 0)],
      imagePath: map['image_path'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Session copyWith({
    String? id,
    String? name,
    String? subject,
    String? group,
    DateTime? date,
    DateTime? createdAt,
    SessionStatus? status,
    String? imagePath,
    String? notes,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      group: group ?? this.group,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Session(name: $name, subject: $subject, group: $group, date: $date)';
  }
}
