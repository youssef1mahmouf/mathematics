import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Installs the native `databaseFactory`.
///
/// On Android/iOS/macOS `package:sqflite` installs its own method-channel
/// factory when the plugin registers itself, so there is nothing to do here.
/// This keeps the historical native behaviour untouched.
Future<void> initDatabaseFactory() async {
  return;
}

/// Resolves the on-disk location used for [fileName].
///
/// * Windows: `%APPDATA%/ECU Attendance/<fileName>` (unchanged behaviour).
/// * Everything else: the application documents directory (unchanged).
Future<String> databaseFilePath(String fileName) async {
  final Directory documentsDir;
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'] ?? '.';
    documentsDir = Directory(p.join(appData, 'Mathsmatics'));
  } else {
    documentsDir = await getApplicationDocumentsDirectory();
  }
  await documentsDir.create(recursive: true);
  return p.join(documentsDir.path, fileName);
}