import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryRemoteDatasource {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _storeColumns = 'id, name, location, fields';
  static const _itemColumns = '*, branches(name)';

  // ---- Store (single store) ----

  Future<Map<String, dynamic>> fetchStore() async {
    final data = await _client
        .from('branches')
        .select(_storeColumns)
        .order('id', ascending: true)
        .limit(1)
        .single();
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> updateStore({
    required int storeId,
    required Map<String, dynamic> updates,
  }) {
    return _client
        .from('branches')
        .update(updates)
        .eq('id', storeId)
        .select(_storeColumns)
        .single();
  }

  // ---- Items ----

  Future<Map<String, dynamic>> insertItem({
    required int storeId,
    required String name,
    required double price,
    String? description,
    String? barcode,
    String? imageUrl,
    Map<String, dynamic>? customFields,
  }) {
    final row = {
      'branch_id': storeId,
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

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final data = await _client
        .from('items')
        .select(_itemColumns)
        .order('created_at', ascending: false)
        .limit(1000);
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

  Future<Map<String, dynamic>?> searchByBarcode(String barcode) async {
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
    final result = await _client.rpc(
      'record_stock_movement',
      params: {
        'p_item_id': itemId,
        'p_movement_type': movementType,
        'p_quantity': quantity,
        if (note != null && note.trim().isNotEmpty) 'p_note': note.trim(),
      },
    );
    return (result as num).toInt();
  }

  Future<List<Map<String, dynamic>>> fetchMovements({
    String? type,
    DateTime? day,
  }) async {
    var query = _client.from('stock_movements').select('*, items(name)');
    if (type != null) {
      query = query.eq('movement_type', type);
    }
    if (day != null) {
      final dayStart = DateTime(day.year, day.month, day.day).toUtc();
      final dayEnd = dayStart.add(const Duration(days: 1));
      query = query
          .gte('created_at', dayStart.toIso8601String())
          .lt('created_at', dayEnd.toIso8601String());
    }
    final data = await query.order('created_at', ascending: false).limit(500);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> fetchStockReport(int storeId) async {
    final result = await _client.rpc(
      'branch_stock_report',
      params: {'p_branch_id': storeId},
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
