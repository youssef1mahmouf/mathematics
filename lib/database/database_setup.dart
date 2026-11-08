/// Cross-platform database bootstrap.
///
/// Exactly one of the two implementations below is compiled in:
///  * `database_setup_io.dart` on Android / iOS / Windows / desktop tests,
///  * `database_setup_web.dart` in the browser (`dart:js_interop` exists).
///
/// Keeping this behind a conditional export is what allows `dart:io`,
/// `path_provider` and `sqflite`'s method-channel factory to stay out of the
/// web bundle while leaving the native behaviour byte-for-byte unchanged.
library;

export 'database_setup_io.dart';