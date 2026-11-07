import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/student.dart';
import '../services/import_service.dart';

class ImportStudentsScreen extends StatefulWidget {
  const ImportStudentsScreen({super.key});

  @override
  State<ImportStudentsScreen> createState() => _ImportStudentsScreenState();
}

class _ImportStudentsScreenState extends State<ImportStudentsScreen> {
  List<Student> importedStudents = [];
  List<String> errors = [];
  bool isImporting = false;
  bool showReview = false;

  Future<void> _importFromFile(String type) async {
    setState(() {
      isImporting = true;
      errors = [];
      importedStudents = [];
    });
    try {
      final result = await ImportService.importFromFile(sourceList: type);
      setState(() {
        importedStudents = result.students;
        errors = result.errors;
        showReview = true;
        isImporting = false;
      });
    } catch (e) {
      setState(() {
        errors = ['خطأ: $e'];
        isImporting = false;
      });
    }
  }

  Future<void> _saveStudents() async {
    final db = AppDatabase();
    int saved = 0;
    int skipped = 0;
    for (final student in importedStudents) {
      final exists = await db.studentExists(
        student.studentId,
        student.sourceList,
      );
      if (exists) {
        skipped++;
        continue;
      }
      await db.insertStudent(student);
      saved++;
    }
    setState(() {
      showReview = false;
      importedStudents = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ $saved طالب، تم تخطي $skipped مكرر'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('استيراد الطلاب'), centerTitle: true),
        body: isImporting
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'اختر نوع القائمة التي تريد استيرادها:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _importFromFile('مجموعات GA'),
                                icon: const Icon(Icons.file_present),
                                label: const Text('مجموعات GA'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _importFromFile('مجموعات GB'),
                                icon: const Icon(Icons.file_present),
                                label: const Text('مجموعات GB'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _importFromFile('مادة الرياضيات PEM001'),
                                icon: const Icon(Icons.functions),
                                label: const Text('رياضيات PEM001'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (errors.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.red.shade50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: errors
                                  .map(
                                    (e) => Text(
                                      '⚠ $e',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (showReview && importedStudents.isNotEmpty) ...[
                          Text(
                            'معاينة البيانات المستخرجة (${importedStudents.length} طالب)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: importedStudents.length,
                              itemBuilder: (context, index) {
                                final s = importedStudents[index];
                                final isUncertain =
                                    s.name.isEmpty || s.studentId.isEmpty;
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isUncertain
                                          ? Colors.orange.shade100
                                          : null,
                                      child: Text(
                                        isUncertain
                                            ? '?'
                                            : s.studentId.substring(
                                                s.studentId.length - 2,
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      s.name.isEmpty
                                          ? 'اسم غير محدد ⚠'
                                          : s.name,
                                      style: TextStyle(
                                        color: isUncertain
                                            ? Colors.orange
                                            : null,
                                        fontWeight: isUncertain
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${s.studentId} | ${s.group ?? '-'} | ${s.sourceList}',
                                    ),
                                    trailing: isUncertain
                                        ? const Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                          )
                                        : const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveStudents,
                                  child: const Text('حفظ جميع الطلاب'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => showReview = false),
                                  child: const Text('إلغاء'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
