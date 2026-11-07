import '../models/session.dart';
import 'session_service.dart';

/// Parsed command from the chat interface
class ChatCommand {
  final String type; // 'take_attendance', 'copy_attendance', 'cancel_session', 'show_absent', 'unknown'
  final String rawText;
  final Map<String, dynamic> parameters;
  final bool needsConfirmation;
  final String confirmationMessage;

  ChatCommand({
    required this.type,
    required this.rawText,
    required this.parameters,
    required this.needsConfirmation,
    required this.confirmationMessage,
  });
}

/// Service for processing Arabic chat commands
class ChatService {
  final SessionService _sessionService = SessionService();

  /// Parse a natural Arabic command
  ChatCommand parseCommand(String text) {
    final normalized = text.trim();

    // "اعمل حضور جلسة النهارده" - Take attendance for today
    if (_containsAny(normalized, ['اعمل حضور', 'سجل حضور', 'حضور جلسة'])) {
      return ChatCommand(
        type: 'take_attendance',
        rawText: text,
        parameters: {'date': 'today'},
        needsConfirmation: true,
        confirmationMessage: 'هل تريد تسجيل حضور جلسة جديدة ليوم اليوم؟',
      );
    }

    // "استخدم حضور الجلسة دي للجلسة الجاية" - Copy attendance to next session
    if (_containsAny(normalized, ['استخدم حضور', 'انسخ حضور', 'نسخ حضور'])) {
      return ChatCommand(
        type: 'copy_attendance',
        rawText: text,
        parameters: {},
        needsConfirmation: true,
        confirmationMessage:
            'هل تريد نسخ سجل الحضور من الجلسة الحالية إلى الجلسة القادمة؟',
      );
    }

    // "ألغِ الجلسة القادمة" - Cancel upcoming session
    if (_containsAny(normalized, ['ألغِ', 'إلغاء', 'إلغاء جلسة'])) {
      return ChatCommand(
        type: 'cancel_session',
        rawText: text,
        parameters: {},
        needsConfirmation: true,
        confirmationMessage:
            'هل تريد إلغاء الجلسة المحددة؟ هذا الإجراء لا يمكن التراجع عنه.',
      );
    }

    // "ورّيني غياب مجموعة A في آخر جلسة" - Show absent students
    if (_containsAny(normalized, ['ورّيني', 'أظهر', 'اعرض', 'غياب'])) {
      return ChatCommand(
        type: 'show_absent',
        rawText: text,
        parameters: {},
        needsConfirmation: false,
        confirmationMessage: '',
      );
    }

    return ChatCommand(
      type: 'unknown',
      rawText: text,
      parameters: {},
      needsConfirmation: false,
      confirmationMessage: '',
    );
  }

  /// Execute a command after confirmation
  Future<Map<String, dynamic>> executeCommand(ChatCommand command) async {
    switch (command.type) {
      case 'take_attendance':
        return _handleTakeAttendance();
      case 'copy_attendance':
        return _handleCopyAttendance();
      case 'cancel_session':
        return _handleCancelSession();
      case 'show_absent':
        return _handleShowAbsent();
      default:
        return {
          'success': false,
          'message': 'لم أفهم الأمر. جرب مثلاً: "اعمل حضور جلسة النهارده"',
        };
    }
  }

  Future<Map<String, dynamic>> _handleTakeAttendance() async {
    final today = DateTime.now();
    final sessions = await _sessionService.getSessions(
      fromDate: DateTime(today.year, today.month, today.day),
      toDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
      statusFilter: SessionStatus.active.index,
    );

    if (sessions.isEmpty) {
      return {
        'success': false,
        'message': 'لا توجد جلسة نشطة ليوم اليوم. يرجى إنشاء جلسة أولاً.',
      };
    }

    return {
      'success': true,
      'message': 'تم العثور على ${sessions.length} جلسة نشطة اليوم.',
      'sessions': sessions,
    };
  }

  Future<Map<String, dynamic>> _handleCopyAttendance() async {
    return {
      'success': false,
      'message': 'ميزة نسخ الحضور تتطلب اختيار الجلسة المصدر والوجهة يدوياً من الشاشة.',
    };
  }

  Future<Map<String, dynamic>> _handleCancelSession() async {
    return {
      'success': false,
      'message': 'يرجى اختيار الجلسة للإلغاء من شاشة الجلسات.',
    };
  }

  Future<Map<String, dynamic>> _handleShowAbsent() async {
    return {
      'success': false,
      'message': 'يرجى اختيار المجموعة والجلسة من شاشة التقارير لعرض الغائبين.',
    };
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  /// Get suggested commands for the user
  List<String> getSuggestions() {
    return [
      'اعمل حضور جلسة النهارده',
      'استخدم حضور الجلسة دي للجلسة الجاية',
      'ألغِ الجلسة القادمة',
      'ورّيني غياب مجموعة A في آخر جلسة',
    ];
  }
}
