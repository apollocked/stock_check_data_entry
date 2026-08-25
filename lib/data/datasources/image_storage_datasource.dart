import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageStorageDatasource {
  static const _bucket = 'grocery_images';
  static const _allowedTypes = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  SupabaseClient get _client => Supabase.instance.client;

  Future<String> upload(XFile imageFile) async {
    final extension = imageFile.name.contains('.')
        ? imageFile.name.split('.').last.toLowerCase()
        : '';
    final contentType = _allowedTypes[extension];
    if (contentType == null) {
      throw Exception('Unsupported image type. Use jpg, png, webp or gif.');
    }
    final bytes = await imageFile.readAsBytes();
    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}.$extension';
    await _client.storage
        .from(_bucket)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return _client.storage.from(_bucket).getPublicUrl(fileName);
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
