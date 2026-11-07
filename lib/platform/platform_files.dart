/// Cross-platform file access seam.
///
/// Exactly one implementation is compiled in:
///  * `platform_files_io.dart` – real file system (`dart:io`,
///    `path_provider`) + `open_filex` + `share_plus` (Android/iOS/Windows),
///  * `platform_files_web.dart` – a virtual document vault backed by
///    `localStorage` plus browser downloads (no `dart:io` anywhere).
///
/// Both implementations expose the very same API so services can be written
/// once.
library;

export 'platform_files_io.dart'
    if (dart.library.js_interop) 'platform_files_web.dart';