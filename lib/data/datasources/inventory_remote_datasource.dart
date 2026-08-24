import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRemoteDatasource {
  static SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    final data = await _client
        .from('branches')
        .select('id, name, location')
        .order('name', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createBranch({
    required String name,
    String? location,
  }) {
    return _client
        .from('branches')
        .insert({'name': name, 'location': location})
        .select('id, name, location')
        .single();
  }

  Future<void> deleteBranch(int branchId) async {
    await _client.from('branches').delete().eq('id', branchId);
  }

  Future<Map<String, dynamic>> insertItem({
    required int branchId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
  }) {
    return _client
        .from('items')
        .insert({
          'branch_id': branchId,
          'name': name,
          'price': price,
          'description': description,
          'barcode': barcode,
          'image_url': imageUrl,
        })
        .select('*, branches(name)')
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchItems({int? branchId}) async {
    var query = _client.from('items').select('*, branches(name)');
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }
    final data = await query.order('created_at', ascending: false).limit(1000);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> deleteItem(int itemId) async {
    await _client.from('items').delete().eq('id', itemId);
  }
}
