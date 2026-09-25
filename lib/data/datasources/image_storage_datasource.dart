import 'dart:math';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';

class ImageStorageDatasource {
  static const _bucket = 'grocery_images';
  static const _folder = 'items';

  /// Matches the bucket's `file_size_limit` in supabase/schema/.
  static const maxBytes = 5 * 1024 * 1024;

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> upload(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const AppException(
        'That image is larger than 5 MB. Pick a smaller one.',
        AppExceptionType.storage,
      );
    }
    final type = detectImageType(bytes);
    if (type == null) {
      throw const AppException(
        'Unsupported image. Use a JPG, PNG, WebP or GIF photo.',
        AppExceptionType.storage,
      );
    }

    // A random name: never derived from user input (a barcode like "../x"
    // could otherwise pick the path) and never overwrites another item's image.
    final path = '$_folder/${randomObjectName()}.${type.extension}';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: type.mimeType, upsert: false),
        );
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<void> remove(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final segments = Uri.tryParse(imageUrl)?.pathSegments;
    if (segments == null) return;
    final bucketIndex = segments.indexOf(_bucket);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return;
    try {
      await _client.storage.from(_bucket).remove([
        segments.sublist(bucketIndex + 1).join('/'),
      ]);
    } catch (_) {
      // Orphaned image is harmless; never block row deletion on this.
    }
  }
}

/// 128 random bits as hex, from a cryptographically secure source.
String randomObjectName() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

typedef ImageType = ({String extension, String mimeType});

/// Reads the file signature instead of trusting the file name.
ImageType? detectImageType(Uint8List bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) {
    if (bytes.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[offset + i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith([0xFF, 0xD8, 0xFF])) {
    return (extension: 'jpg', mimeType: 'image/jpeg');
  }
  if (startsWith([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return (extension: 'png', mimeType: 'image/png');
  }
  if (startsWith([0x47, 0x49, 0x46, 0x38])) {
    return (extension: 'gif', mimeType: 'image/gif');
  }
  if (startsWith([0x52, 0x49, 0x46, 0x46]) &&
      startsWith([0x57, 0x45, 0x42, 0x50], 8)) {
    return (extension: 'webp', mimeType: 'image/webp');
  }
  return null;
}
