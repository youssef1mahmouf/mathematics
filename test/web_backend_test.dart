import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

import 'package:mathsmatics/platform/platform_files.dart';

/// Exercises the `dart:js_interop` branch of the file-access seam (the
/// `localStorage` vault plus browser downloads).
///
/// Skipped by the regular VM `flutter test` run; execute with
/// `flutter test --platform chrome test/web_backend_test.dart`.
void main() {
  final skip = kIsWeb ? false : 'requires a web platform';

  test('round trips a text document', () async {
    final dir = await appFolderPath('backups');
    await writeTextFile('$dir/round_trip.json', '{"a":1}');
    expect(await fileExists('$dir/round_trip.json'), isTrue);
    expect(await readTextFile('$dir/round_trip.json'), '{"a":1}');

    final listed = await listStoredFiles(dir);
    expect(listed.map((f) => f.fileName), contains('round_trip.json'));

    await deleteStoredFile('$dir/round_trip.json');
    expect(await fileExists('$dir/round_trip.json'), isFalse);
    expect(
      (await listStoredFiles(dir)).map((f) => f.fileName),
      isNot(contains('round_trip.json')),
    );
  }, skip: skip);

  test('saving binary bytes hands the file to the browser', () async {
    final file = '${await appFolderPath('reports')}/report.xlsx';
    await writeBinaryFile(
      file,
      utf8.encode('not-really-xlsx'),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    // Re-sending it (open/share) must not throw either.
    await openStoredFile(file);
    await shareStoredFile(file);
  }, skip: skip);

  test('reading a missing document fails loudly', () async {
    await expectLater(
      readTextFile('backups/does-not-exist.json'),
      throwsA(isA<Exception>()),
    );
  }, skip: skip);
}