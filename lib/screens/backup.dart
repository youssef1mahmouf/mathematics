import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  List<BackupInfo> _backups = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _hasRecentBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
    _checkRecentBackup();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _backupService.getBackupHistory();
      setState(() {
        _backups = backups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkRecentBackup() async {
    final hasRecent = await _backupService.hasRecentBackup();
    setState(() => _hasRecentBackup = hasRecent);
  }

  Future<void> _createBackup() async {
    setState(() => _isCreating = true);
    try {
      final info = await _backupService.createBackup();
      setState(() {
        _isCreating = false;
        _hasRecentBackup = true;
      });
      _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية: ${info.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreFromBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text(
          'هل تريد استعادة البيانات من النسخة الاحتياطية المحددة؟ سيتم دمج البيانات مع البيانات الحالية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.restoreFromBackup(filePath);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استعادة البيانات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاستعادة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذه النسخة الاحتياطية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _backupService.deleteBackup(filePath);
      _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('النسخ الاحتياطي'), centerTitle: true),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _hasRecentBackup
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _hasRecentBackup
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hasRecentBackup
                                      ? 'يوجد نسخة احتياطية حديثة (خلال 7 أيام)'
                                      : 'لا توجد نسخة احتياطية حديثة - يرجى إنشاء نسخة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _hasRecentBackup
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isCreating ? null : _createBackup,
                                  icon: _isCreating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.backup),
                                  label: Text(
                                    _isCreating
                                        ? 'جاري الإنشاء...'
                                        : 'إنشاء نسخة احتياطية',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'تاريخ النسخ الاحتياطية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _backups.isEmpty
                        ? const Center(child: Text('لا توجد نسخ احتياطية'))
                        : ListView.builder(
                            itemCount: _backups.length,
                            itemBuilder: (context, index) {
                              final backup = _backups[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.backup,
                                  color: Colors.blue,
                                ),
                                title: Text(backup.fileName),
                                subtitle: Text(
                                  'التاريخ: ${DateFormat('yyyy/MM/dd HH:mm', 'ar').format(backup.createdAt)}\n'
                                  'الطلاب: ${backup.studentCount} | الجلسات: ${backup.sessionCount}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.restore,
                                        color: Colors.green,
                                      ),
                                      onPressed: () =>
                                          _restoreFromBackup(backup.filePath),
                                      tooltip: 'استعادة',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteBackup(backup.filePath),
                                      tooltip: 'حذف',
                                    ),
                                  ],
                                ),
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
