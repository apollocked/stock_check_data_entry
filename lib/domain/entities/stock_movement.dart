class StockMovement {
  final int id;
  final int itemId;
  final int branchId;
  final MovementType type;
  final int quantity;
  final String? note;
  final String? userEmail;
  final String? itemName;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.itemId,
    required this.branchId,
    required this.type,
    required this.quantity,
    this.note,
    this.userEmail,
    this.itemName,
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int,
      itemId: map['item_id'] as int,
      branchId: map['branch_id'] as int,
      type: MovementType.fromString(map['movement_type'] as String),
      quantity: map['quantity'] as int,
      note: map['note'] as String?,
      userEmail: map['user_email'] as String?,
      itemName: (map['items'] as Map<String, dynamic>?)?['name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }

  int get signedQuantity => switch (type) {
    MovementType.inbound => quantity,
    MovementType.outbound || MovementType.damage => -quantity,
  };
}

enum MovementType {
  inbound,
  outbound,
  damage;

  static MovementType fromString(String value) => switch (value.toUpperCase()) {
    'IN' => MovementType.inbound,
    'OUT' => MovementType.outbound,
    'DAMAGE' => MovementType.damage,
    _ => throw ArgumentError('Unknown movement type: $value'),
  };

  String get code => switch (this) {
    MovementType.inbound => 'IN',
    MovementType.outbound => 'OUT',
    MovementType.damage => 'DAMAGE',
  };

  String get label => switch (this) {
    MovementType.inbound => 'Stock in',
    MovementType.outbound => 'Stock out',
    MovementType.damage => 'Damage',
  };
}
