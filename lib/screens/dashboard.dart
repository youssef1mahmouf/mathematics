import 'package:flutter/material.dart';

import '../database/app_database.dart';
import 'student_list.dart';
import 'import_students.dart';
import 'take_attendance.dart';
import 'chat.dart';
import 'reports.dart';
import 'backup.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int studentCount = 0;
  int presentCount = 0;
  int absentCount = 0;
  int sessionCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = AppDatabase();
    final count = await db.getStudentCount();
    final sessions = await db.getSessions();
    var present = 0;
    var absent = 0;
    if (sessions.isNotEmpty) {
      final summary = await db.getAttendanceSummary(sessions.first.id!);
      present = summary['present'] ?? 0;
      absent = summary['absent'] ?? 0;
    }
    if (!mounted) return;
    setState(() {
      studentCount = count;
      presentCount = present;
      absentCount = absent;
      sessionCount = sessions.length;
      isLoading = false;
    });
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.today), onPressed: () {}),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'إجمالي الطلاب',
                            studentCount.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'الحاضرون',
                            presentCount.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'الغائبون',
                            absentCount.toString(),
                            Icons.cancel,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'الجلسات',
                            sessionCount.toString(),
                            Icons.event,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'الإجراءات السريعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _actionButton(
                          'تسجيل حضور',
                          Icons.check_circle_outline,
                          Colors.green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TakeAttendanceScreen(),
                              ),
                            );
                          },
                        ),
                        _actionButton(
                          'الطلاب والمجموعات',
                          Icons.people_alt,
                          Colors.blue,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentListScreen(),
                              ),
                            );
                          },
                        ),
                        _actionButton(
                          'استيراد',
                          Icons.file_upload,
                          Colors.orange,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ImportStudentsScreen(),
                              ),
                            );
                          },
                        ),
                        _actionButton(
                          'المحادثة',
                          Icons.chat,
                          Colors.indigo,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatScreen(),
                              ),
                            );
                          },
                        ),
                        _actionButton(
                          'التقارير',
                          Icons.assessment,
                          Colors.teal,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _actionButton(
                          'النسخ الاحتياطي',
                          Icons.backup,
                          Colors.grey,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BackupScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'نظام إدارة حضور الطلاب - يعمل دون إنترنت',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
