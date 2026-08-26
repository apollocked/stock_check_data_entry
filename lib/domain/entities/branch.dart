import 'dart:convert';

class BranchField {
  final String id;
  final String label;
  final String type; // text, number, image
  final bool enabled;
  final bool required;

  const BranchField({
    required this.id,
    required this.label,
    required this.type,
    this.enabled = true,
    this.required = false,
  });

  factory BranchField.fromMap(Map<String, dynamic> map) {
    return BranchField(
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

  BranchField copyWith({bool? enabled}) {
    return BranchField(
      id: id,
      label: label,
      type: type,
      enabled: enabled ?? this.enabled,
      required: required,
    );
  }
}

class Branch {
  final int id;
  final String name;
  final String? location;
  final List<BranchField> fields;

  const Branch({
    required this.id,
    required this.name,
    this.location,
    this.fields = const [],
  });

  factory Branch.fromMap(Map<String, dynamic> map) {
    final rawFields = map['fields'];
    List<BranchField> parsedFields = const [];
    if (rawFields is String) {
      try {
        parsedFields = (jsonDecode(rawFields) as List)
            .map((e) => BranchField.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    } else if (rawFields is List) {
      parsedFields = rawFields
          .map((e) => BranchField.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return Branch(
      id: map['id'] as int,
      name: map['name'] as String,
      location: map['location'] as String?,
      fields: parsedFields,
    );
  }

  List<BranchField> get enabledFields =>
      fields.where((f) => f.enabled).toList();

  bool hasField(String fieldId) =>
      fields.any((f) => f.id == fieldId && f.enabled);

  @override
  String toString() => name;
}
