class Pokemon {
  int? id;
  String name;
  String type;      // primary (required)
  String? type2;    // secondary (optional)

  Pokemon({
    this.id,
    required this.name,
    required this.type,
    this.type2,
  });

  factory Pokemon.fromMap(Map<String, dynamic> m) => Pokemon(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        type2: m['type2'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'type2': type2,
      };
}
