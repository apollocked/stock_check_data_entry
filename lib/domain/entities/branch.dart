class Branch {
  final int id;
  final String name;
  final String? location;

  const Branch({required this.id, required this.name, this.location});

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'] as int,
      name: map['name'] as String,
      location: map['location'] as String?,
    );
  }

  @override
  String toString() => name;
}
