import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/report_service.dart';
import '../services/session_service.dart';
import '../models/session.dart';
import '../models/attendance_record.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SessionService _sessionService = SessionService();
  final ReportService _reportService = ReportService();

  List<Session> _sessions = [];
  Session? _selectedSession;
  SessionReport? _report;
  String? _subjectFilter;
  String? _groupFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    final sessions = await _sessionService.getSessions(
      subjectFilter: _subjectFilter,
      groupFilter: _groupFilter,
      fromDate: _fromDate,
      toDate: _toDate,
    );
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _generateReport(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      final report = await _reportService.generateSessionReport(sessionId);
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportExcel() async {
    if (_report == null) return;
    try {
      final path = await _reportService.exportToExcel(_report!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير التقرير إلى: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_report == null) return;
    try {
      final path = await _reportService.exportToPdf(_report!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير التقرير إلى: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التقارير'), centerTitle: true),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
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
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('كل المواد'),
                                  ),
                                  ...[
                                    'رياضيات',
                                    'فيزياء',
                                    'كيمياء',
                                    'أحياء',
                                  ].map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  ),
                                ],
                                initialValue: _subjectFilter,
                                onChanged: (v) {
                                  setState(() => _subjectFilter = v);
                                  _loadSessions();
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
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('كل المجموعات'),
                                  ),
                                  ...[
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
                                  ].map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  ),
                                ],
                                initialValue: _groupFilter,
                                onChanged: (v) {
                                  setState(() => _groupFilter = v);
                                  _loadSessions();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('من تاريخ'),
                                subtitle: Text(
                                  _fromDate != null
                                      ? DateFormat(
                                          'yyyy/MM/dd',
                                          'ar',
                                        ).format(_fromDate!)
                                      : 'اختيار',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _fromDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    locale: const Locale('ar', 'EG'),
                                  );
                                  if (date != null) {
                                    setState(() => _fromDate = date);
                                    _loadSessions();
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('إلى تاريخ'),
                                subtitle: Text(
                                  _toDate != null
                                      ? DateFormat(
                                          'yyyy/MM/dd',
                                          'ar',
                                        ).format(_toDate!)
                                      : 'اختيار',
                                ),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _toDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    locale: const Locale('ar', 'EG'),
                                  );
                                  if (date != null) {
                                    setState(() => _toDate = date);
                                    _loadSessions();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _sessions.isEmpty
                        ? const Center(child: Text('لا توجد جلسات'))
                        : ListView.builder(
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              return ListTile(
                                title: Text(
                                  '${session.name} - ${session.subject}',
                                ),
                                subtitle: Text(
                                  '${session.group} - ${DateFormat('yyyy/MM/dd', 'ar').format(session.date)}',
                                ),
                                trailing: _selectedSession?.id == session.id
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() => _selectedSession = session);
                                  _generateReport(session.id!);
                                },
                              );
                            },
                          ),
                  ),
                  if (_report != null) ...[
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير: ${_report!.session.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'المادة: ${_report!.session.subject} | المجموعة: ${_report!.session.group}',
                            ),
                            Text(
                              'التاريخ: ${DateFormat('yyyy/MM/dd', 'ar').format(_report!.session.date)}',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _statItem(
                                    'حاضر',
                                    '${_report!.presentCount}',
                                    Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _statItem(
                                    'غائب',
                                    '${_report!.absentCount}',
                                    Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: _statItem(
                                    'يحتاج مراجعة',
                                    '${_report!.needsReviewCount}',
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _exportExcel,
                                    icon: const Icon(Icons.table_view),
                                    label: const Text('تصدير Excel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _exportPdf,
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('تصدير PDF'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _report!.records.length,
                        itemBuilder: (context, index) {
                          final record = _report!.records[index];
                          return ListTile(
                            title: Text(record.studentName),
                            subtitle: Text(
                              '${record.studentId} - ${record.studentGroup ?? '-'}',
                            ),
                            trailing: Chip(
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
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
