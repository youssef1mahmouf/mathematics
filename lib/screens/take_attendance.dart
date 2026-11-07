import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/ocr_engine_factory.dart';
import '../services/matching_service.dart';
import '../database/app_database.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../models/attendance_record.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  String _selectedSubject = 'رياضيات';
  String _selectedGroup = 'GA-1';
  String _sessionName = 'المحاضرة 1';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  // XFile works on every platform: it wraps a path natively and the picked
  // bytes/blob-url in the browser (a dart:io File does not exist on web).
  XFile? _imageFile;
  bool _isProcessing = false;
  bool _hasResult = false;
  List<AttendanceRecord> _matchedRecords = [];
  List<Student> _allStudents = [];
  String _statusMessage = '';
  Color _statusColor = Colors.blue;

  final List<String> _subjects = ['رياضيات', 'فيزياء', 'كيمياء', 'أحياء'];
  final List<String> _groups = [
    'GA-1',
    'GA-2',
    'GA-3',
    'GA-4',
    'GA-5',
    'GA-6',
    'GA-7',
    'GA-8',
    'GA-9',
    'GA-10',
    'GA-11',
    'GA-12',
    'GB-1',
    'GB-2',
    'GB-3',
    'GB-4',
    'GB-5',
    'GB-6',
    'GB-7',
    'GB-8',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = AppDatabase();
    final students = await db.getStudents(groupFilter: _selectedGroup);
    setState(() {
      _allStudents = students;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
        _hasResult = false;
        _matchedRecords = [];
        _statusMessage = 'تم اختيار الصورة. اضغط على معالجة لبدء المطابقة.';
        _statusColor = Colors.blue;
      });
    }
  }

  Future<void> _captureImage() async {
    if (kIsWeb) {
      // image_picker_for_web has no camera support.
      setState(() {
        _statusMessage =
            'الكاميرا غير متاحة في نسخة المتصفح، استخدم "اختيار من المعرض".';
        _statusColor = Colors.orange;
      });
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        _imageFile = picked;
        _hasResult = false;
        _matchedRecords = [];
        _statusMessage = 'تم التقاط الصورة. اضغط على معالجة لبدء المطابقة.';
        _statusColor = Colors.blue;
      });
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'جاري قراءة الصورة ومطابقة الأسماء...';
      _statusColor = Colors.blue;
    });

    try {
      final ocrEngine = OcrEngineFactory.create();
      final available = await ocrEngine.isAvailable();

      if (!available) {
        setState(() {
          _statusMessage =
              'محرك القراءة (${ocrEngine.engineName}) غير متاح على هذه المنصة. يمكنك المراجعة اليدوية.';
          _statusColor = Colors.orange;
          _isProcessing = false;
        });
        return;
      }

      final ocrResult = await ocrEngine.recognizeText(_imageFile!.path);
      final detectedNames = _extractNamesFromOCR(ocrResult.text);

      final records = <AttendanceRecord>[];
      final now = DateTime.now();

      for (final name in detectedNames) {
        final match = MatchingService.matchStudent(
          detectedName: name,
          detectedId: null,
          detectedGroup: _selectedGroup,
          availableStudents: _allStudents,
        );

        final record = MatchingService.createRecordFromMatch(
          sessionId: '',
          match: match,
          detectedName: name,
          detectedId: null,
          checkInTime: now,
        );
        records.add(record);
      }

      final detectedStudentIds = records
          .where((r) => r.studentId.isNotEmpty)
          .map((r) => r.studentId)
          .toSet();
      for (final student in _allStudents) {
        if (!detectedStudentIds.contains(student.studentId)) {
          records.add(
            AttendanceRecord(
              sessionId: '',
              studentId: student.studentId,
              studentName: student.name,
              studentGroup: student.group,
              status: AttendanceStatus.absent,
              matchedBy: 'none',
              matchConfidence: 0.0,
              needsReview: false,
            ),
          );
        }
      }

      setState(() {
        _matchedRecords = records;
        _hasResult = true;
        _isProcessing = false;
        _statusMessage =
            'اكتمل المعالجة. تم العثور على ${records.where((r) => r.status == AttendanceStatus.present).length} حاضر و ${records.where((r) => r.status == AttendanceStatus.absent).length} غائب.';
        _statusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في المعالجة: $e';
        _statusColor = Colors.red;
        _isProcessing = false;
      });
    }
  }

  List<String> _extractNamesFromOCR(String text) {
    final lines = text.split(RegExp(r'[\n\r]+'));
    final names = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length > 2 && !RegExp(r'^[\d\s\.\-]+$').hasMatch(trimmed)) {
        names.add(trimmed);
      }
    }
    return names;
  }

  Future<void> _saveAttendance() async {
    final session = Session(
      name: _sessionName,
      subject: _selectedSubject,
      group: _selectedGroup,
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      status: SessionStatus.completed,
      imagePath: _imageFile?.path,
    );

    final db = AppDatabase();
    final sessionId = await db.insertSession(session);

    for (final record in _matchedRecords) {
      final updated = record.copyWith(sessionId: sessionId);
      await db.insertAttendanceRecord(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ سجل الحضور بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar', 'EG'),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تسجيل حضور'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'المادة',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedSubject,
                              items: _subjects
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() => _selectedSubject = v!);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'المجموعة',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedGroup,
                              items: _groups
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedGroup = v!;
                                  _loadStudents();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'اسم الجلسة (مثل: المحاضرة 1)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _sessionName = v,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('التاريخ والوقت'),
                              subtitle: Text(
                                DateFormat('yyyy/MM/dd HH:mm', 'ar').format(
                                  DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                    _selectedDate.day,
                                    _selectedTime.hour,
                                    _selectedTime.minute,
                                  ),
                                ),
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _showDateTimePicker,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'صورة الحضور',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('اختيار من المعرض'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _captureImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('تصوير'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _imageFile == null || _isProcessing
                                  ? null
                                  : _processImage,
                              icon: const Icon(Icons.auto_awesome),
                              label: Text(
                                _isProcessing
                                    ? 'جاري المعالجة...'
                                    : 'معالجة ومطابقة',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: _statusColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(
                        _statusColor == Colors.green
                            ? Icons.check_circle
                            : _statusColor == Colors.red
                            ? Icons.error
                            : Icons.info,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusMessage)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (_hasResult && _matchedRecords.isNotEmpty) ...[
                const Text(
                  'النتيجة النهائية - مراجعة الحضور',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('اسم الطالب')),
                      DataColumn(label: Text('رقم الطالب')),
                      DataColumn(label: Text('الحالة')),
                      DataColumn(label: Text('وقت الحضور')),
                    ],
                    rows: _matchedRecords.take(50).map((record) {
                      return DataRow(
                        cells: [
                          DataCell(Text(record.studentName)),
                          DataCell(Text(record.studentId)),
                          DataCell(
                            Chip(
                              label: Text(
                                record.status == AttendanceStatus.present
                                    ? 'حاضر'
                                    : record.status == AttendanceStatus.absent
                                    ? 'غائب'
                                    : 'يحتاج مراجعة',
                              ),
                              backgroundColor:
                                  record.status == AttendanceStatus.present
                                  ? Colors.green.shade100
                                  : record.status == AttendanceStatus.absent
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                            ),
                          ),
                          DataCell(
                            Text(
                              record.checkInTime != null
                                  ? DateFormat(
                                      'HH:mm',
                                      'ar',
                                    ).format(record.checkInTime!)
                                  : '-',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                if (_matchedRecords.length > 50)
                  Text('يظهر أول 50 طالب من ${_matchedRecords.length}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('تعديل يدوي'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveAttendance,
                        child: const Text('اعتماد الحضور'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
