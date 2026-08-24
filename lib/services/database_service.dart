import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/branch.dart';
import '../models/item.dart';

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => message;
}

class DatabaseService {
  static const _imageBucket = 'grocery_images';
  static const _allowedImageTypes = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Branch>> fetchBranches() async {
    try {
      final data = await _client
          .from('branches')
          .select('id, name, location')
          .order('name', ascending: true);
      return [for (final row in (data as List)) Branch.fromMap(row)];
    } catch (e) {
      throw DatabaseException('Could not load branches: $e');
    }
  }

  Future<Branch> createBranch({
    required String name,
    String? location,
  }) async {
    try {
      final row = await _client
          .from('branches')
          .insert({'name': name.trim(), 'location': location?.trim()})
          .select('id, name, location')
          .single();
      return Branch.fromMap(row);
    } catch (e) {
      throw DatabaseException('Could not create branch: $e');
    }
  }

  Future<void> deleteBranch(int branchId) async {
    try {
      await _client.from('branches').delete().eq('id', branchId);
    } catch (e) {
      throw DatabaseException('Could not delete branch: $e');
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final extension =
          imageFile.path.contains('.') ? imageFile.path.split('.').last.toLowerCase() : '';
      final contentType = _allowedImageTypes[extension];
      if (contentType == null) {
        throw const DatabaseException(
          'Unsupported image type. Use jpg, png, webp or gif.',
        );
      }
      final bytes = await imageFile.readAsBytes();
      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(100000)}.$extension';
      await _client.storage.from(_imageBucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      return _client.storage.from(_imageBucket).getPublicUrl(fileName);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('Image upload failed: $e');
    }
  }

  Future<Item> insertItem({
    required int branchId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
  }) async {
    try {
      final row = await _client
          .from('items')
          .insert({
            'branch_id': branchId,
            'name': name.trim(),
            'price': price,
            'description': description?.trim(),
            'barcode': barcode?.trim(),
            'image_url': imageUrl,
          })
          .select('*, branches(name)')
          .single();
      return Item.fromMap(row);
    } catch (e) {
      throw DatabaseException('Could not save item: $e');
    }
  }

  Future<List<Item>> fetchItems({int? branchId}) async {
    try {
      var query = _client.from('items').select('*, branches(name)');
      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      final data = await query
          .order('created_at', ascending: false)
          .limit(1000);
      return [for (final row in (data as List)) Item.fromMap(row)];
    } catch (e) {
      throw DatabaseException('Could not load items: $e');
    }
  }

  Future<void> deleteItem(Item item) async {
    try {
      await _client.from('items').delete().eq('id', item.id);
      await _deleteStorageObject(item.imageUrl);
    } catch (e) {
      throw DatabaseException('Could not delete item: $e');
    }
  }

  Future<void> _deleteStorageObject(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final segments = Uri.tryParse(imageUrl)?.pathSegments;
    if (segments == null) return;
    final bucketIndex = segments.indexOf(_imageBucket);
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return;
    try {
      await _client.storage
          .from(_imageBucket)
          .remove([segments.sublist(bucketIndex + 1).join('/')]);
    } catch (_) {
      // Row is already deleted; orphaned image is harmless.
    }
  }
}
