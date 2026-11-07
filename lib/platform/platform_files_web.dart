import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:web/web.dart' as web;

/// Metadata of a stored document (mirrors the io implementation).
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

const String _keyPrefix = 'math_fs:';

/// Reports saved during this session, so "open/share" can re-send them.
final Map<String, ({Uint8List bytes, String mimeType})> _savedBinaries = {};

String _key(String path) => '$_keyPrefix$path';

web.Storage get _storage => web.window.localStorage;

/// Browsers cannot address arbitrary folders, so each folder is a virtual
/// bucket (a `localStorage` key prefix) named [folderName].
Future<String> appFolderPath(String folderName) async => folderName;

Future<bool> fileExists(String path) async => _storage.getItem(_key(path)) != null;

/// Stores an entry as `{"m": <iso timestamp>, "c": <content>}` so the list
/// view can still report a modification date.
Future<void> writeTextFile(String path, String text) async {
  try {
    _storage.setItem(
      _key(path),
      jsonEncode({
        'm': DateTime.now().toUtc().toIso8601String(),
        'c': text,
      }),
    );
  } catch (e) {
    throw Exception(
      'تعذر حفظ الملف في متصفحك (مساحة التخزين ممتلئة): $e',
    );
  }
}

Future<String> readTextFile(String path) async {
  final raw = _storage.getItem(_key(path));
  if (raw == null) {
    throw Exception('ملف غير موجود: $path');
  }
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded['c'] as String;
}

Future<void> deleteStoredFile(String path) async {
  _storage.removeItem(_key(path));
}

Future<List<StoredFile>> listStoredFiles(String folderPath) async {
  final storage = _storage;
  final prefix = '$_keyPrefix$folderPath/';
  final files = <StoredFile>[];
  for (var i = 0; i < storage.length; i++) {
    final key = storage.key(i);
    if (key == null || !key.startsWith(prefix)) continue;
    final raw = storage.getItem(key);
    if (raw == null) continue;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final path = key.substring(_keyPrefix.length);
    files.add(StoredFile(
      path: path,
      fileName: p.basename(path),
      modifiedAt: DateTime.tryParse(decoded['m'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    ));
  }
  return files;
}

/// Keeps a copy in the browser vault **and** hands the document to the user
/// as a download — the closest equivalent of "write a backup file to disk".
Future<void> saveTextDocument(
  String path,
  String text, {
  String mimeType = 'text/plain',
}) async {
  await writeTextFile(path, text);
  _downloadBytes(
    Uint8List.fromList(utf8.encode(text)),
    p.basename(path),
    mimeType,
  );
}

/// Generates a download; the bytes are also cached so "open"/"share" can
/// re-send them later in the session.
Future<void> writeBinaryFile(
  String path,
  List<int> bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  _savedBinaries[path] = (bytes: data, mimeType: mimeType);
  _downloadBytes(data, p.basename(path), mimeType);
}

Future<void> openStoredFile(
  String path, {
  String mimeType = 'application/octet-stream',
}) async {
  final cached = _savedBinaries[path];
  if (cached != null) {
    _downloadBytes(cached.bytes, p.basename(path), cached.mimeType);
    return;
  }
  final text = await readTextFile(path);
  _downloadBytes(Uint8List.fromList(utf8.encode(text)), p.basename(path),
      mimeType);
}

Future<void> shareStoredFile(
  String path, {
  String mimeType = 'application/octet-stream',
  String? text,
}) =>
    openStoredFile(path, mimeType: mimeType);

/// Triggers a browser download for [bytes] using an object URL.
void _downloadBytes(Uint8List bytes, String fileName, String mimeType) {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}