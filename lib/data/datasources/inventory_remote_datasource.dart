import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRemoteDatasource {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _branchColumns = 'id, name, location, fields';
  static const _itemColumns = '*, branches(name)';

  Future<List<Map<String, dynamic>>> fetchBranches() async {
    final data = await _client
        .from('branches')
        .select(_branchColumns)
        .order('name', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createBranch({
    required String name,
    String? location,
    required List<Map<String, dynamic>> fields,
  }) {
    return _client
        .from('branches')
        .insert({
          'name': name,
          'location': location,
          'fields': jsonEncode(fields),
        })
        .select(_branchColumns)
        .single();
  }

  Future<Map<String, dynamic>> updateBranch({
    required int branchId,
    required Map<String, dynamic> updates,
  }) {
    return _client
        .from('branches')
        .update(updates)
        .eq('id', branchId)
        .select(_branchColumns)
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
    Map<String, dynamic>? customFields,
  }) {
    final row = {
      'branch_id': branchId,
      'name': name,
      'price': price,
      'description': description,
      'barcode': barcode,
      'image_url': imageUrl,
    };
    if (customFields != null && customFields.isNotEmpty) {
      row['custom_fields'] = jsonEncode(customFields);
    }
    return _client.from('items').insert(row).select(_itemColumns).single();
  }

  Future<List<Map<String, dynamic>>> fetchItems({int? branchId}) async {
    var query = _client.from('items').select(_itemColumns);
    if (branchId != null) {
      query = query.eq('branch_id', branchId);
    }
    final data = await query.order('created_at', ascending: false).limit(1000);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> deleteItem(int itemId) async {
    await _client.from('items').delete().eq('id', itemId);
  }

  Future<Map<String, dynamic>> updateItem({
    required int itemId,
    required Map<String, dynamic> updates,
  }) {
    if (updates.containsKey('custom_fields') &&
        updates['custom_fields'] is Map) {
      updates['custom_fields'] = jsonEncode(updates['custom_fields']);
    }
    return _client
        .from('items')
        .update(updates)
        .eq('id', itemId)
        .select(_itemColumns)
        .single();
  }

  Future<Map<String, dynamic>?> searchByBarcode({
    required int branchId,
    required String barcode,
  }) async {
    final data = await _client
        .from('items')
        .select(_itemColumns)
        .eq('branch_id', branchId)
        .eq('barcode', barcode)
        .maybeSingle();
    return data;
  }

  Future<Map<String, dynamic>?> searchByBarcodeGlobal(String barcode) async {
    final data = await _client
        .from('items')
        .select(_itemColumns)
        .eq('barcode', barcode)
        .limit(1)
        .maybeSingle();
    return data;
  }

  // ---- Stock movements ----

  Future<int> recordMovement({
    required int itemId,
    required String movementType,
    required int quantity,
    String? note,
  }) async {
    final result = await _client.rpc('record_stock_movement', params: {
      'p_item_id': itemId,
      'p_movement_type': movementType,
      'p_quantity': quantity,
      if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
    });
    return (result as num).toInt();
  }

  Future<List<Map<String, dynamic>>> fetchMovements({
    required int branchId,
    String? type,
  }) async {
    var query = _client
        .from('stock_movements')
        .select('*, items(name)')
        .eq('branch_id', branchId);
    if (type != null) {
      query = query.eq('movement_type', type);
    }
    final data = await query
        .order('created_at', ascending: false)
        .limit(500);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchStockReport(int branchId) async {
    final result = await _client.rpc('branch_stock_report', params: {
      'p_branch_id': branchId,
    });
    return Map<String, dynamic>.from(result as Map);
  }
}
