class Item {
  final int id;
  final int branchId;
  final String? branchName;
  final String name;
  final String? description;
  final double? price;
  final String? barcode;
  final String? imageUrl;
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
    required this.createdAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    return Item(
      id: map['id'] as int,
      branchId: map['branch_id'] as int,
      branchName: (map['branches'] as Map<String, dynamic>?)?['name'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price:
          rawPrice == null ? null : double.parse(rawPrice.toString()),
      barcode: map['barcode'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'description': description,
      'price': price,
      'barcode': barcode,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
