import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../models/session.dart';
import '../models/attendance_record.dart';
import '../platform/platform_files.dart';

class SessionReport {
  final Session session;
  final List<AttendanceRecord> records;
  final Map<String, int> summary;

  SessionReport({
    required this.session,
    required this.records,
    required this.summary,
  });

  int get presentCount => summary['present'] ?? 0;
  int get absentCount => summary['absent'] ?? 0;
  int get needsReviewCount => summary['needsReview'] ?? 0;
  int get totalCount => records.length;
}

class ReportService {
  final AppDatabase _db = AppDatabase();

  Future<SessionReport> generateSessionReport(String sessionId) async {
    final session = await _db.getSessionById(sessionId);
    if (session == null) {
      throw Exception('الجلسة غير موجودة');
    }
    final records = await _db.getAttendanceBySession(sessionId);
    final summary = await _db.getAttendanceSummary(sessionId);
    return SessionReport(session: session, records: records, summary: summary);
  }

  String _attendanceStatusArabic(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.needsReview:
        return 'يحتاج مراجعة';
      case AttendanceStatus.excused:
        return 'معذور';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<String> exportToExcel(
    SessionReport report, {
    String? outputPath,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['التقرير'];

    sheet.appendRow([
      TextCellValue('رقم الطالب'),
      TextCellValue('اسم الطالب'),
      TextCellValue('المجموعة'),
      TextCellValue('الحالة'),
      TextCellValue('وقت الحضور'),
      TextCellValue('تم التعديل يدوياً'),
      TextCellValue('يحتاج مراجعة'),
    ]);

    for (final record in report.records) {
      sheet.appendRow([
        TextCellValue(record.studentId),
        TextCellValue(record.studentName),
        TextCellValue(record.studentGroup ?? ''),
        TextCellValue(_attendanceStatusArabic(record.status)),
        TextCellValue(
          record.checkInTime != null ? record.checkInTime!.toString() : '',
        ),
        TextCellValue(record.timeManuallyEdited ? 'نعم' : 'لا'),
        TextCellValue(record.needsReview ? 'نعم' : 'لا'),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('الملخص'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('إجمالي'),
      TextCellValue('${report.totalCount}'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('حاضر'),
      TextCellValue('${report.presentCount}'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('غائب'),
      TextCellValue('${report.absentCount}'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    sheet.appendRow([
      TextCellValue('يحتاج مراجعة'),
      TextCellValue('${report.needsReviewCount}'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    final fileBytes = excel.save();
    String filePath;
    if (outputPath != null && outputPath.isNotEmpty) {
      filePath = outputPath;
    } else {
      filePath = await _getSavePath('xlsx', report.session);
    }
    await writeBinaryFile(
      filePath,
      fileBytes!,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    return filePath;
  }

  Future<String> exportToPdf(SessionReport report, {String? outputPath}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: [
              pw.Text(
                'تقرير الحضور - ${report.session.subject}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'المجموعة: ${report.session.group}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'الجلسة: ${report.session.name}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'التاريخ: ${_formatDate(report.session.date)}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        'رقم الطالب',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'اسم الطالب',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'الحالة',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'وقت الحضور',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  for (final record in report.records)
                    pw.TableRow(
                      children: [
                        pw.Text(record.studentId),
                        pw.Text(record.studentName),
                        pw.Text(_attendanceStatusArabic(record.status)),
                        pw.Text(
                          record.checkInTime != null
                              ? record.checkInTime!.toString()
                              : '-',
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'الحاضرون: ${report.presentCount} | الغائبون: ${report.absentCount} | يحتاج مراجعة: ${report.needsReviewCount}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    String filePath;
    if (outputPath != null && outputPath.isNotEmpty) {
      filePath = outputPath;
    } else {
      filePath = await _getSavePath('pdf', report.session);
    }
    await writeBinaryFile(filePath, pdfBytes, mimeType: 'application/pdf');
    return filePath;
  }

  Future<String> _getSavePath(String ext, Session session) async {
    final timestamp = _formatDate(session.date);
    final safeSubject = session.subject.replaceAll(
      RegExp(r'[^\w\u0621-\u064A]'),
      '_',
    );
    final safeGroup = session.group.replaceAll(
      RegExp(r'[^\w\u0621-\u064A]'),
      '_',
    );
    final fileName = 'تقرير_${safeSubject}_${safeGroup}_$timestamp.$ext';

    // Native: `<app data>/ECU Attendance/reports/<file>`.
    // Web: a virtual bucket; the file is handed to the user as a download.
    final reportsDir = await appFolderPath('reports');
    return p.join(reportsDir, fileName);
  }

  Future<void> openFile(String filePath) async {
    await openStoredFile(filePath);
  }

  Future<void> shareFile(String filePath) async {
    await shareStoredFile(filePath);
  }
}
