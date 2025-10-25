class Pokemon {
  int? id;
  String name;
  String type;
  String? type2;
  int? dex;

  Pokemon({
    this.id,
    required this.name,
    required this.type,
    this.type2,
    this.dex,
  });

  factory Pokemon.fromMap(Map<String, dynamic> m) => Pokemon(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String,
        type2: m['type2'] as String?,
        dex: m['dex'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'type2': type2,
        'dex': dex,
      };
}