import 'dart:convert';

class ItemField {
  final String id;
  final String label;
  final String type; // text, number, image
  final bool enabled;
  final bool required;

  const ItemField({
    required this.id,
    required this.label,
    required this.type,
    this.enabled = true,
    this.required = false,
  });

  factory ItemField.fromMap(Map<String, dynamic> map) {
    return ItemField(
      id: map['id'] as String,
      label: map['label'] as String,
      type: map['type'] as String,
      enabled: map['enabled'] as bool? ?? true,
      required: map['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'type': type,
    'enabled': enabled,
    'required': required,
  };

  ItemField copyWith({bool? enabled}) {
    return ItemField(
      id: id,
      label: label,
      type: type,
      enabled: enabled ?? this.enabled,
      required: required,
    );
  }
}

class Store {
  final int id;
  final String name;
  final String? location;
  final List<ItemField> fields;

  const Store({
    required this.id,
    required this.name,
    this.location,
    this.fields = const [],
  });

  factory Store.fromMap(Map<String, dynamic> map) {
    final rawFields = map['fields'];
    List<ItemField> parsedFields = const [];
    if (rawFields is String) {
      try {
        parsedFields = (jsonDecode(rawFields) as List)
            .map((e) => ItemField.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else if (rawFields is List) {
      parsedFields = rawFields
          .map((e) => ItemField.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return Store(
      id: map['id'] as int,
      name: map['name'] as String,
      location: map['location'] as String?,
      fields: parsedFields,
    );
  }

  List<ItemField> get enabledFields => fields.where((f) => f.enabled).toList();

  bool hasField(String fieldId) =>
      fields.any((f) => f.id == fieldId && f.enabled);

  @override
  String toString() => name;
}

const kStandardFieldIds = {
  'name',
  'price',
  'description',
  'barcode',
  'image_url',
};

/// All available optional fields a store can add to its items.
const List<Map<String, dynamic>> kStoreFieldOptions = [
  {'id': 'name', 'label': 'Name', 'type': 'text', 'required': true},
  {'id': 'price', 'label': 'Price', 'type': 'number', 'required': true},
  {
    'id': 'description',
    'label': 'Description',
    'type': 'text',
    'required': false,
  },
  {'id': 'barcode', 'label': 'Barcode', 'type': 'text', 'required': false},
  {'id': 'image_url', 'label': 'Image', 'type': 'image', 'required': false},
  {'id': 'category', 'label': 'Category', 'type': 'text', 'required': false},
  {'id': 'supplier', 'label': 'Supplier', 'type': 'text', 'required': false},
  {
    'id': 'stock',
    'label': 'Stock Quantity',
    'type': 'number',
    'required': false,
  },
  {
    'id': 'expiry_date',
    'label': 'Expiry Date',
    'type': 'text',
    'required': false,
  },
];

/// Default fields used when a store defines none.
List<ItemField> defaultValueFields() {
  return [
    for (final f in kStoreFieldOptions)
      ItemField(
        id: f['id'] as String,
        label: f['label'] as String,
        type: f['type'] as String,
        enabled: f['required'] as bool,
        required: f['required'] as bool,
      ),
  ];
}
