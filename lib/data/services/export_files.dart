import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A new file in the app's cache folder for an export.
///
/// Exports hold the whole inventory, so they are written to temporary storage
/// (not the documents folder, which is kept and backed up) and deleted once
/// shared.
Future<File> exportFile(String prefix, String extension) async {
  final directory = await getTemporaryDirectory();
  return File(
    '${directory.path}${Platform.pathSeparator}'
    '${prefix}_${exportTimestamp(DateTime.now())}.$extension',
  );
}

Future<void> shareAndDelete(File file, {required String text}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  } finally {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The OS clears the cache folder eventually anyway.
    }
  }
}

String exportTimestamp(DateTime time) {
  final y = time.year.toString().padLeft(4, '0');
  final m = time.month.toString().padLeft(2, '0');
  final d = time.day.toString().padLeft(2, '0');
  final h = time.hour.toString().padLeft(2, '0');
  final min = time.minute.toString().padLeft(2, '0');
  final s = time.second.toString().padLeft(2, '0');
  return '$y$m${d}_$h$min$s';
}
