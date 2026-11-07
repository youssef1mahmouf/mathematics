import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/student.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  List<Student> students = [];
  List<Student> filteredStudents = [];
  String searchQuery = '';
  String? groupFilter;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final db = AppDatabase();
    final all = await db.getStudents();
    setState(() {
      students = all;
      filteredStudents = all;
      isLoading = false;
    });
  }

  void _filterStudents() {
    setState(() {
      filteredStudents = students.where((s) {
        final matchesSearch =
            searchQuery.isEmpty ||
            s.name.contains(searchQuery) ||
            s.studentId.contains(searchQuery);
        final matchesGroup = groupFilter == null || s.group == groupFilter;
        return matchesSearch && matchesGroup;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الطلاب والمجموعات'),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'البحث باسم الطالب أو رقمه',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            searchQuery = val;
                            _filterStudents();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'تصفية حسب المجموعة',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('كل المجموعات'),
                            ),
                            ...{
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
                            }.map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            ),
                          ],
                          onChanged: (val) {
                            groupFilter = val;
                            _filterStudents();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              student.studentId.substring(
                                student.studentId.length - 2,
                              ),
                            ),
                          ),
                          title: Text(student.name),
                          subtitle: Text(
                            '${student.studentId} - ${student.group ?? '-'}',
                          ),
                          trailing: Text(student.sourceList),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
