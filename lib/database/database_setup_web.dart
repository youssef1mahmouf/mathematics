import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Installs `sqflite_common_ffi_web` as the global sqflite factory.
///
/// Must run before the first `openDatabase(...)` call. Guarded so calling it
/// twice (from `main()` and from `AppDatabase`) is harmless.
///
/// Requires `web/sqlite3.wasm` and `web/sqflite_sw.js`, produced with
/// `dart run sqflite_common_ffi_web:setup`.
Future<void> initDatabaseFactory() async {
  if (databaseFactoryOrNull == null) {
    databaseFactory = databaseFactoryFfiWeb;
  }
}

/// Browsers have no file system, so on the web the "path" is just the
/// database name; SQLite keeps it in IndexedDB under the origin.
Future<String> databaseFilePath(String fileName) async => fileName;