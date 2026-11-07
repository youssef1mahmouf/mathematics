import '../models/student.dart';

class ImportDuplicate {
  final Student existing;
  final Student incoming;
  final String reason;

  ImportDuplicate({
    required this.existing,
    required this.incoming,
    required this.reason,
  });
}
