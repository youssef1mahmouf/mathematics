import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Metadata of a stored document.
class StoredFile {
  final String path;
  final String fileName;
  final DateTime modifiedAt;

  const StoredFile({
    required this.path,
    required this.fileName,
    required this.modifiedAt,
  });
}

/// Resolves `<app data>/<folderName>` and makes sure it exists.
///
/// * Windows: `%APPDATA%/ECU Attendance/<folderName>`
/// * Everything else: `<documents>/<folderName>`
Future<String> appFolderPath(String folderName) async {
  final Directory base;
  final appData = Platform.environment['APPDATA'];
  if (appData != null) {
    base = Directory(p.join(appData, 'Mathsmatics'));
  } else if (Platform.isWindows) {
    base = Directory(p.join(Platform.environment['LOCALAPPDATA'] ?? '.',
        'ECU Attendance'));
  } else {
    base = await getApplicationDocumentsDirectory();
  }
  final dir = Directory(p.join(base.path, folderName));
  await dir.create(recursive: true);
  return dir.path;
}

Future<bool> fileExists(String path) => File(path).exists();

Future<void> writeTextFile(String path, String text) async {
  await File(path).writeAsString(text, encoding: utf8, flush: true);
}

Future<String> readTextFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('ملف غير موجود: $path');
  }
  return file.readAsString(encoding: utf8);
}

Future<void> deleteStoredFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<List<StoredFile>> listStoredFiles(String folderPath) async {
  final dir = Directory(folderPath);
  if (!await dir.exists()) return const [];

  final files = <StoredFile>[];
  await for (final entity in dir.list(followLinks: false)) {
    if (entity is! File) continue;
    final stat = await entity.stat();
    files.add(StoredFile(
      path: entity.path,
      fileName: p.basename(entity.path),
      modifiedAt: stat.modified,
    ));
  }
  return files;
}

/// Persists a user facing text document to disk.
Future<void> saveTextDocument(
  String path,
  String text, {
  String mimeType = 'text/plain',
}) =>
    writeTextFile(path, text);

/// Persists generated report bytes to disk.
Future<void> writeBinaryFile(
  String path,
  List<int> bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

/// Opens [path] with the operating system.
Future<void> openStoredFile(
  String path, {
  String mimeType = 'application/octet-stream',
}) async {
  await OpenFilex.open(path);
}

/// Shares [path] through the platform share sheet.
Future<void> shareStoredFile(
  String path, {
  String mimeType = 'application/octet-stream',
  String? text,
}) async {
  await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: text));
}