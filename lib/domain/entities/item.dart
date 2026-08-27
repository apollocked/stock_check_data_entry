import 'dart:convert';

class Item {
  final int id;
  final int branchId;
  final String? branchName;
  final String name;
  final String? description;
  final double? price;
  final String? barcode;
  final String? imageUrl;
  final Map<String, dynamic> customFields;
  final int quantity;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.branchId,
    this.branchName,
    required this.name,
    this.description,
    this.price,
    this.barcode,
    this.imageUrl,
    this.customFields = const {},
    this.quantity = 0,
    required this.createdAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];

    Map<String, dynamic> parsedCustom = {};
    final rawCustom = map['custom_fields'];
    if (rawCustom is String) {
      try {
        parsedCustom = jsonDecode(rawCustom) as Map<String, dynamic>;
      } catch (_) {}
    } else if (rawCustom is Map) {
      parsedCustom = Map<String, dynamic>.from(rawCustom);
    }

    return Item(
      id: map['id'] as int,
      branchId: map['branch_id'] as int,
      branchName:
          (map['branches'] as Map<String, dynamic>?)?['name'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: rawPrice == null ? null : double.parse(rawPrice.toString()),
      barcode: map['barcode'] as String?,
      imageUrl: map['image_url'] as String?,
      customFields: parsedCustom,
      quantity: map['quantity'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  dynamic customValue(String fieldId) => customFields[fieldId];
}
